#!/usr/bin/env bash
#
# new-work.sh - Script to start work following the project's contributing flow.
#
# Usage:
#   ./scripts/new-work.sh [type] [issue-number] [descriptive-name]
#
# All arguments are optional and can be given in any order. The script detects
# whether each argument is a type (feature/hotfix/devops/chore/release), an
# issue number, or a descriptive name. Missing values are requested interactively.
#
# First, the script asks whether the work corresponds to a GitHub issue:
#   - If yes: it asks for the issue number, fetches its title from GitHub, and
#     uses it to build the branch name.
#   - If no: it asks for the type, a descriptive name.
#
# Examples:
#   ./scripts/new-work.sh                          # fully interactive
#   ./scripts/new-work.sh feature 42               # type + issue (name from issue title)
#   ./scripts/new-work.sh devops 5 update-docs     # type + issue + custom name
#   ./scripts/new-work.sh 42                       # only issue number
#
# Supported types: feature, hotfix, devops, chore, release
#
# Flow:
#   1. Verifies you are on develop and up to date with origin/develop
#   2. Asks whether it corresponds to an issue and collects the needed data
#   3. Creates the branch from develop named <type>/<issue>-<name>
#   4. Commits any uncommitted changes
#   5. Pushes the branch to origin
#
# NOTE: This script does NOT create a Pull Request. Use scripts/sync-develop.sh
# to open the PR, wait for CI, and merge towards develop.

set -euo pipefail

# Derive OWNER/REPO from the origin remote (supports SSH and HTTPS URLs)
REPO=$(git remote get-url origin | sed -E 's#^(git@github\.com:|https://github\.com/)##; s#\.git$##')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Utility functions
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

confirm() {
    local prompt="$1"
    read -r -p "${prompt} [y/N]: " response
    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Validate that gh is authenticated
# -----------------------------------------------------------------------------
check_gh_auth() {
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI (gh) is not authenticated. Run: gh auth login"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Validate that we are on develop and up to date
# -----------------------------------------------------------------------------
check_develop_branch() {
    local current
    current=$(git branch --show-current)

    if [ "$current" != "develop" ]; then
        log_warn "You are not on the 'develop' branch. You are on '$current'."
        if confirm "Switch to 'develop' and pull?"; then
            git checkout develop
            git pull origin develop
        else
            log_error "You must be on 'develop' to start work."
            exit 1
        fi
    else
        log_info "You are on the 'develop' branch. Checking for updates..."
        if git fetch origin develop 2>/dev/null; then
            local local_sha remote_sha
            local_sha=$(git rev-parse develop)
            remote_sha=$(git rev-parse origin/develop 2>/dev/null || echo "$local_sha")
            if [ "$local_sha" != "$remote_sha" ]; then
                log_warn "Your 'develop' branch is not up to date with origin/develop."
                if confirm "Pull from origin/develop?"; then
                    git pull origin develop
                else
                    log_error "You must synchronize 'develop' before creating a branch."
                    exit 1
                fi
            else
                log_ok "'develop' is up to date."
            fi
        else
            log_warn "Could not verify with origin/develop. Make sure you have connection."
        fi
    fi
}

# -----------------------------------------------------------------------------
# Ask for PR type (if not provided)
# -----------------------------------------------------------------------------
ask_type() {
    local tipo="$1"
    if [ -n "$tipo" ]; then
        echo "$tipo"
        return
    fi

    echo "" >&2
    echo "Available change types:" >&2
    echo "  1) feature  - Implement a new feature" >&2
    echo "  2) hotfix   - One-off bug fix" >&2
    echo "  3) devops   - Infrastructure, CI, documentation, repo" >&2
    echo "  4) chore    - Maintenance tasks (formatting, dependencies)" >&2
    echo "  5) release  - Synchronize develop into main" >&2
    echo "" >&2
    read -r -p "Select the type (1-5 or name): " choice

    case "$choice" in
        1|feature)  echo "feature" ;;
        2|hotfix)   echo "hotfix" ;;
        3|devops)   echo "devops" ;;
        4|chore)    echo "chore" ;;
        5|release)  echo "release" ;;
        feature|hotfix|devops|chore|release) echo "$choice" ;;
        *) log_error "Invalid type: '$choice'"; exit 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Ask for issue number (if not provided)
# -----------------------------------------------------------------------------
ask_issue_number() {
    local num="$1"
    if [ -n "$num" ]; then
        echo "$num"
        return
    fi
    read -r -p "Issue number: " num
    echo "$num"
}

# -----------------------------------------------------------------------------
# Ask for descriptive name (if not provided)
# -----------------------------------------------------------------------------
ask_name() {
    local name="$1"
    if [ -n "$name" ]; then
        echo "$name"
        return
    fi
    read -r -p "Descriptive name (no spaces, use hyphens): " name
    echo "$name"
}

# -----------------------------------------------------------------------------
# Normalize name for branch (lowercase, hyphens instead of spaces)
# -----------------------------------------------------------------------------
normalize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# -----------------------------------------------------------------------------
# Build branch name
# -----------------------------------------------------------------------------
build_branch_name() {
    local tipo="$1"
    local issue_num="$2"
    local name="$3"

    if [ -n "$issue_num" ] && [ -n "$name" ]; then
        echo "${tipo}/${issue_num}-${name}"
    elif [ -n "$issue_num" ]; then
        echo "${tipo}/${issue_num}"
    elif [ -n "$name" ]; then
        echo "${tipo}/${name}"
    else
        echo "${tipo}/sin-nombre"
    fi
}

# -----------------------------------------------------------------------------
# Get issue title via gh
# -----------------------------------------------------------------------------
get_issue_title() {
    local issue_num="$1"
    local title=""
    title=$(gh issue view "$issue_num" --json title --jq '.title' 2>/dev/null) || title=""
    echo "$title"
}

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
main() {
    check_gh_auth
    check_develop_branch

    # -------------------------------------------------------------------------
    # Process positional arguments (optional, any order)
    # -------------------------------------------------------------------------
    local tipo="" issue_num="" nombre=""
    local arg
    for arg in "$@"; do
        case "$arg" in
            feature|hotfix|devops|chore|release)
                [ -z "$tipo" ] && tipo="$arg" || { log_error "Several types provided."; exit 1; }
                ;;
            [0-9]*)
                [ -z "$issue_num" ] && issue_num="$arg" || { log_error "Several issue numbers provided."; exit 1; }
                ;;
            *)
                [ -z "$nombre" ] && nombre="$arg" || { log_error "Several names provided."; exit 1; }
                ;;
        esac
    done

    # -------------------------------------------------------------------------
    # Ask whether it corresponds to a GitHub issue
    # -------------------------------------------------------------------------
    local es_issue=""
    read -r -p "Does this work correspond to a GitHub issue? [y/N]: " es_issue

    local issue_title=""
    if [ "$es_issue" = "y" ] || [ "$es_issue" = "Y" ]; then
        # ---- Flow with issue ----
        issue_num=$(ask_issue_number "$issue_num")

        issue_title=$(get_issue_title "$issue_num")
        if [ -z "$issue_title" ]; then
            log_error "Could not fetch issue #$issue_num. Check that it exists and you have access."
            exit 1
        fi
        log_ok "Issue #$issue_num: $issue_title"

        # Use the issue title as the name if none was given
        if [ -z "$nombre" ]; then
            nombre=$(normalize_name "$issue_title")
            log_info "Name derived from issue: $nombre"
        fi

        tipo=$(ask_type "$tipo")
    else
        # ---- Flow without issue (fully interactive) ----
        tipo=$(ask_type "$tipo")
        nombre=$(ask_name "$nombre")
        issue_num=""
    fi

    nombre=$(normalize_name "$nombre")
    local branch_name
    branch_name=$(build_branch_name "$tipo" "$issue_num" "$nombre")

    log_info "Branch to create: $branch_name"

    # Verify branch does not already exist
    if git rev-parse --verify "$branch_name" &>/dev/null; then
        log_error "Branch '$branch_name' already exists locally."
        exit 1
    fi

    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        log_error "Branch '$branch_name' already exists on origin."
        exit 1
    fi

    # Create branch from develop
    log_info "Creating branch '$branch_name' from develop..."
    git checkout -b "$branch_name"

    # If there are uncommitted changes, ask what to do
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "There are uncommitted changes in the working tree."
        if confirm "Commit the changes before continuing?"; then
            git add -A
            local commit_msg
            read -r -p "Commit message: " commit_msg
            if [ -z "$commit_msg" ]; then
                if [ -n "$issue_num" ]; then
                    commit_msg="${tipo}: $nombre (issue #$issue_num)"
                else
                    commit_msg="${tipo}: $nombre"
                fi
            fi
            git commit -m "$commit_msg"
        else
            log_error "There are uncommitted changes. Commit or discard them first."
            exit 1
        fi
    fi

    # Push the branch
    log_info "Pushing branch to origin..."
    git push -u origin "$branch_name"

    echo
    echo "========================================================================"
    log_ok "Summary:"
    echo "  - Branch: $branch_name"
    echo "  - Type: $tipo"
    if [ -n "$issue_num" ]; then
        echo "  - Issue: #$issue_num"
    fi
    echo ""
    echo "Next steps:"
    echo "  1. Implement your changes in branch $branch_name"
    echo "  2. Commit and push: git push origin $branch_name"
    echo "  3. Run: ./scripts/sync-develop.sh $tipo $nombre"
    echo "     - This will create the PR, wait for CI, and merge towards develop"
    echo "========================================================================"
}

main "$@"
