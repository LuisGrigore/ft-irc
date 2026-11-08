#!/usr/bin/env bash
#
# sync-main.sh - Script to synchronize develop into main via a release PR.
#
# Follows the repository methodology:
#   1. Verifies gh is authenticated
#   2. Verifies you are on develop and up to date with origin/develop
#   3. Creates a release/ branch from develop
#   4. Updates CHANGELOG.md via generate-changelog.sh
#   5. Commits pending changes if any
#   6. Pushes the branch to origin
#   7. Creates a Pull Request towards main (type release)
#
# Usage:
#   ./scripts/sync-main.sh [descriptive-name]
#
# Example:
#   ./scripts/sync-main.sh sync-release-v1-0-0
#
# After merge, remember to create a version tag on main (e.g. v1.0.0).

set -euo pipefail

REPO="LuisGrigore/ft-irc"
OWNER="LuisGrigore"
REPO_NAME="ft-irc"

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
# Protected branches that must never be deleted
# -----------------------------------------------------------------------------
is_protected_branch() {
    local branch="$1"
    if [ "$branch" = "develop" ] || [ "$branch" = "main" ]; then
        return 0
    fi
    return 1
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
            log_error "You must be on 'develop' to synchronize with main."
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
                    log_error "You must synchronize 'develop' before creating the release branch."
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
# Build release branch name
# -----------------------------------------------------------------------------
build_branch_name() {
    local name="$1"

    if [ -n "$name" ]; then
        echo "release/${name}"
    else
        echo "release/sync-develop-to-main"
    fi
}

# -----------------------------------------------------------------------------
# Determine PR target branch (always main for sync-main.sh)
# -----------------------------------------------------------------------------
pr_target_branch() {
    echo "main"
}

# -----------------------------------------------------------------------------
# Update CHANGELOG.md via generate-changelog.sh (sync mode)
# -----------------------------------------------------------------------------
update_changelog() {
    log_info "Updating CHANGELOG.md via generate-changelog.sh (sync mode)..."
    if [ -f scripts/generate-changelog.sh ]; then
        if ./scripts/generate-changelog.sh sync CHANGELOG.md 2>&1; then
            log_ok "CHANGELOG.md updated."
            # Commit the changelog automatically if there are changes
            if ! git diff --quiet CHANGELOG.md || ! git diff --cached --quiet CHANGELOG.md 2>/dev/null; then
                git add CHANGELOG.md
                git commit -m "chore: update changelog" >/dev/null 2>&1 && log_ok "CHANGELOG.md committed automatically."
            fi
        else
            log_warn "generate-changelog.sh failed. Continuing without changelog update."
        fi
    else
        log_warn "scripts/generate-changelog.sh not found. Skipping changelog update."
    fi
}

# -----------------------------------------------------------------------------
# Build PR body following the GitHub PR template
# -----------------------------------------------------------------------------
build_pr_body() {
    local branch_name="$1"
    local changed_files="$2"
    local issue_num="$3"
    local closes_section=""

    if [ -n "$issue_num" ]; then
        closes_section="Closes #${issue_num}"
    fi

    cat <<EOF
## PR type

Mark with an \`x\` the corresponding type:

- [ ] \`feature\` — implements a new feature (branch \`feature/\`)
- [ ] \`hotfix\` — one-off bug fix (branch \`hotfix/\`)
- [ ] \`devops\` — infrastructure, CI, scripts, documentation or repository configuration (branch \`devops/\`)
- [x] \`release\` — synchronizes \`develop\` into \`main\` (branch \`release/\`)

## Source and target branches

- **Source branch:** \`${branch_name}\`
- **Target branch:** \`main\`

## Related issue(s)

Indicate the traceability ID of the issue closed by this PR:

- Feature: \`FEAT-001\`
- Task: \`T-001\`
- Hotfix: \`HOTFIX-001\`

> Example: \`Closes #123 — FEAT-001\`

$(if [ -n "$issue_num" ]; then echo "Issue related: DEVOPS-${issue_num}"; echo ""; echo "${closes_section}"; else echo "No associated issue."; fi)

## Acceptance criteria completed

List the acceptance criteria IDs fulfilled by this PR:

- [ ] \`AC-...\` — …

## Changes made

$(if [ -n "$changed_files" ]; then echo "${changed_files}" | while IFS= read -r f; do [ -n "$f" ] && echo "- \`${f}\`"; done; else echo "Briefly describe what was modified, added or removed."; fi)

## Checklist before requesting review

- [x] Branch created from \`develop\` (\`git checkout develop && git pull && git checkout -b release/…\`)
- [ ] Code complies with C++98 (\`-std=c++98\`, no \`unique_ptr\`, lambdas, \`auto\`, etc.)
- [ ] Compiled with \`-Wall -Wextra -Werror -Wpedantic -std=c++98\`
- [ ] \`make build\` completes without errors
- [ ] \`make test\` passes (unit + integration)
- [ ] \`make valgrind\` passes with no leaks or errors
- [ ] \`make sanitize\` passes (if applicable)
- [ ] Documentation updated if necessary
- [x] Traceability IDs used in commit messages and PR description

## Merge instructions

- **For PRs of type \`release\`:** merge \`develop\` into \`main\` (direct synchronization, no release pipeline). After merge on \`main\`, create a version tag (e.g. v1.0.0).
EOF
}

# -----------------------------------------------------------------------------
# Extract issue number from a commit message (Closes #N or DEVOPS-NNN)
# -----------------------------------------------------------------------------
extract_issue_number_from_commit() {
    local msg="$1"
    local num=""
    num=$(echo "$msg" | sed -n 's/.*Closes #\([0-9]*\).*/\1/p')
    if [ -z "$num" ]; then
        num=$(echo "$msg" | sed -n 's/.*DEVOPS-\([0-9]*\).*/\1/p')
    fi
    echo "$num"
}

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
main() {
    check_gh_auth
    check_develop_branch

    # -------------------------------------------------------------------------
    # Get descriptive name
    # -------------------------------------------------------------------------
    local nombre
    nombre=$(ask_name "${1:-}")
    nombre=$(normalize_name "$nombre")
    local branch_name
    branch_name=$(build_branch_name "$nombre")

    log_info "Release branch to create: $branch_name"

    # Verify branch does not already exist
    if git rev-parse --verify "$branch_name" &>/dev/null; then
        log_error "Branch '$branch_name' already exists locally."
        exit 1
    fi

    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        log_error "Branch '$branch_name' already exists on origin."
        exit 1
    fi

    # Check for pending changes between develop and main
    local diff_count=""
    diff_count=$(git log origin/main..develop --oneline 2>/dev/null | wc -l) || diff_count="0"
    log_info "Pending commits between main and develop: $diff_count"

    # Create release branch from develop
    log_info "Creating branch '$branch_name' from develop..."
    git checkout -b "$branch_name"

    # Update CHANGELOG before committing
    update_changelog

    # If there are uncommitted changes, ask what to do
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "There are uncommitted changes in the working tree."
        if confirm "Commit the changes before continuing?"; then
            git add -A
            local commit_msg
            read -r -p "Commit message: " commit_msg
            if [ -z "$commit_msg" ]; then
                commit_msg="release: synchronize develop into main ($nombre)"
            fi
            git commit -m "$commit_msg"
        else
            log_error "There are uncommitted changes. Commit or discard them first."
            exit 1
        fi
    fi

    # Verify there is at least one commit difference between main and the release branch
    local diff_commits=""
    diff_commits=$(git log origin/main.."$branch_name" --oneline 2>/dev/null) || diff_commits=""
    if [ -z "$diff_commits" ]; then
        log_warn "No commit difference between main and '$branch_name'. Creating an empty commit to allow PR creation..."
        git commit --allow-empty -m "release: synchronize develop into main ($nombre)"
        log_ok "Empty commit created."
    fi

    # Push the branch
    log_info "Pushing branch to origin..."
    git push -u origin "$branch_name"

    # Determine PR target branch
    local target
    target=$(pr_target_branch)

    # Get list of changed files
    local changed_files=""
    changed_files=$(git diff --name-only origin/main.."$branch_name" 2>/dev/null) || changed_files=""

    # Build PR title and body
    local pr_title pr_body
    pr_title="release: synchronize develop into main ($nombre)"

    # Detect issue number from last commit
    local issue_num=""
    local last_commit_msg=""
    last_commit_msg=$(git log -1 --format="%s" 2>/dev/null) || last_commit_msg=""
    issue_num=$(extract_issue_number_from_commit "$last_commit_msg")

    pr_body=$(build_pr_body "$branch_name" "$changed_files" "$issue_num")

    # Check if a PR already exists towards main from this branch
    local existing_pr=""
    existing_pr=$(gh pr list \
        --repo "$REPO" \
        --head "$branch_name" \
        --base "main" \
        --state open \
        --json url,title,number \
        --jq '.[0].url // empty' 2>/dev/null) || existing_pr=""

    local pr_url=""
    if [ -n "$existing_pr" ]; then
        pr_url="$existing_pr"
        log_warn "A Pull Request already exists towards main from this branch:"
        log_ok "Pull Request: $pr_url"
    else
        # Create PR
        log_info "Creating Pull Request towards main..."
        local create_output=""
        create_output=$(gh pr create \
            --repo "$REPO" \
            --base "main" \
            --head "$branch_name" \
            --title "$pr_title" \
            --body "$pr_body" 2>&1) || {
            log_error "Failed to create Pull Request. gh output:"
            echo "$create_output"
            exit 1
        }
        # Extract the PR URL
        pr_url=$(echo "$create_output" | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' | head -n1)
        if [ -z "$pr_url" ]; then
            pr_url=$(echo "$create_output" | grep -oE 'https?://[^ ]+' | head -n1)
        fi
        if [ -z "$pr_url" ]; then
            log_error "Could not determine the Pull Request URL from gh output."
            exit 1
        fi
        log_ok "Pull Request created: $pr_url"
    fi

    echo
    echo "========================================================================"
    log_ok "Summary:"
    echo "  - Branch: $branch_name"
    log_ok "  - PR: $pr_url"
    echo "  - Target: main"
    echo ""
    echo "Next steps:"
    echo "  1. Review the Pull Request on GitHub"
    echo "  2. Wait for CI checks to pass"
    echo "  3. When approved, merge manually on GitHub"
    echo "  4. After merge, create a version tag on main (e.g. v1.0.0)"
    echo "========================================================================"
}

main "$@"
