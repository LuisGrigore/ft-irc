#!/usr/bin/env bash
#
# sync-develop.sh - Script to push changes to develop via a PR.
#
# Follows the repository methodology:
#   1. Verifies gh is authenticated
#   2. Verifies you are on a feature/hotfix/devops branch (not develop/main)
#   3. Updates CHANGELOG.md via generate-changelog.sh
#   4. Commits pending changes if any
#   5. Pushes the branch to origin
#   6. Creates a Pull Request towards develop (type feature/hotfix/devops/chore/release)
#   7. Waits for all CI checks to pass on the PR
#   8. Merges towards develop if there are no conflicts
#
# Usage:
#   ./scripts/sync-develop.sh [pr-type] [descriptive-name]
#
# Examples:
#   ./scripts/sync-develop.sh feature implement-client-getters
#   ./scripts/sync-develop.sh devops add-changelog-generator
#   ./scripts/sync-develop.sh hotfix fix-memory-leak
#
# After merge, remember to delete the branch.

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
# Validate that gh is authenticated
# -----------------------------------------------------------------------------
check_gh_auth() {
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI (gh) is not authenticated. Run: gh auth login"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Validate that we are NOT on develop or main
# -----------------------------------------------------------------------------
check_not_on_protected_branch() {
    local current
    current=$(git branch --show-current)

    if [ "$current" = "develop" ] || [ "$current" = "main" ]; then
        log_error "You are on '$current'. You must be on a feature/hotfix/devops/chore/release branch to sync to develop."
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Validate that develop is up to date
# -----------------------------------------------------------------------------
check_develop_updated() {
    log_info "Checking that develop is up to date..."
    if git fetch origin develop 2>/dev/null; then
        local local_sha remote_sha
        local_sha=$(git rev-parse develop 2>/dev/null || echo "")
        remote_sha=$(git rev-parse origin/develop 2>/dev/null || echo "")
        if [ "$local_sha" != "$remote_sha" ]; then
            log_warn "Your local 'develop' is not up to date with origin/develop."
            if confirm "Pull origin/develop into local develop?"; then
                git checkout develop
                git pull origin develop
                git checkout - 2>/dev/null || git checkout "${current_branch}" 2>/dev/null || true
            else
                log_error "You must synchronize 'develop' before creating a PR."
                exit 1
            fi
        else
            log_ok "'develop' is up to date."
        fi
    else
        log_warn "Could not verify with origin/develop. Make sure you have connection."
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

    echo "Available PR types:"
    echo "  1) feature  - Implement a new feature"
    echo "  2) hotfix   - One-off bug fix"
    echo "  3) devops   - Infrastructure, CI, scripts, documentation, repo"
    echo "  4) chore    - Maintenance tasks (formatting, dependencies)"
    echo "  5) release  - Synchronize develop into main"
    echo
    read -r -p "Select the PR type (1-5 or name): " choice

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
    local name="$2"

    if [ -n "$name" ]; then
        echo "${tipo}/${name}"
    else
        echo "${tipo}/sin-nombre"
    fi
}

# -----------------------------------------------------------------------------
# Determine PR target branch (always develop for sync-develop.sh)
# -----------------------------------------------------------------------------
pr_target_branch() {
    echo "develop"
}

# -----------------------------------------------------------------------------
# Update CHANGELOG.md via generate-changelog.sh (all mode)
# -----------------------------------------------------------------------------
update_changelog() {
    log_info "Updating CHANGELOG.md via generate-changelog.sh (all mode)..."
    if [ -f scripts/generate-changelog.sh ]; then
        if ./scripts/generate-changelog.sh all CHANGELOG.md 2>&1; then
            log_ok "CHANGELOG.md updated."
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
    local tipo="$1"
    local branch_name="$2"
    local target="$3"
    local changed_files="$4"
    local issue_num="$5"
    local closes_section=""

    if [ -n "$issue_num" ]; then
        closes_section="Closes #${issue_num}"
    fi

    local cb_feature="[ ]" cb_hotfix="[ ]" cb_devops="[ ]" cb_chore="[ ]" cb_release="[ ]"
    case "$tipo" in
        feature)  cb_feature="[x]" ;;
        hotfix)   cb_hotfix="[x]" ;;
        devops)   cb_devops="[x]" ;;
        chore)    cb_chore="[x]" ;;
        release)  cb_release="[x]" ;;
    esac

    cat <<EOF
## PR type

Mark with an \`x\` the corresponding type:

- ${cb_feature} \`feature\` — implements a new feature (branch \`feature/\`)
- ${cb_hotfix} \`hotfix\` — one-off bug fix (branch \`hotfix/\`)
- ${cb_devops} \`devops\` — infrastructure, CI, scripts, documentation or repository configuration (branch \`devops/\`)
- ${cb_chore} \`chore\` — maintenance tasks (formatting, dependencies)
- ${cb_release} \`release\` — synchronizes \`develop\` into \`main\` (branch \`release/\`)

## Source and target branches

- **Source branch:** \`${branch_name}\`
- **Target branch:** \`${target}\`

## Related issue(s)

Indicate the traceability ID of the issue closed by this PR:

- Feature: \`FEAT-001\`
- Task: \`T-001\`
- Hotfix: \`HOTFIX-001\`

> Example: \`Closes #123 — FEAT-001\`

$(if [ -n "$issue_num" ]; then echo "Issue related: ${tipo^^}-${issue_num}"; echo ""; echo "${closes_section}"; else echo "No associated issue."; fi)

## Acceptance criteria completed

List the acceptance criteria IDs fulfilled by this PR:

- [ ] \`AC-...\` — …

## Changes made

$(if [ -n "$changed_files" ]; then echo "${changed_files}" | while IFS= read -r f; do [ -n "$f" ] && echo "- \`${f}\`"; done; else echo "Briefly describe what was modified, added or removed."; fi)

## Checklist before requesting review

- [x] Branch created from \`develop\` (\`git checkout develop && git pull && git checkout -b ${tipo}/…\`)
- [ ] Code complies with C++98 (\`-std=c++98\`, no \`unique_ptr\`, lambdas, \`auto\`, etc.)
- [ ] Compiled with \`-Wall -Wextra -Werror -Wpedantic -std=c++98\`
- [ ] \`make build\` completes without errors
- [ ] \`make test\` passes (unit + integration)
- [ ] \`make valgrind\` passes with no leaks or errors
- [ ] \`make sanitize\` passes (if applicable)
- [ ] Documentation updated if necessary
- [x] Traceability IDs used in commit messages and PR description

## Merge instructions

- **For PRs of type \`feature\`, \`hotfix\` or \`devops\`:** merge into \`develop\`, **delete the branch** after merge, and **close the corresponding issue** (feature/task/hotfix) when all its acceptance criteria are completed.
- **For PRs of type \`release\`:** merge \`develop\` into \`main\` (direct synchronization, no release pipeline). After merge on \`main\`, create a version tag (e.g. v1.0.0).
EOF
}

# -----------------------------------------------------------------------------
# Wait for CI checks to pass on a PR
# -----------------------------------------------------------------------------
wait_for_ci() {
    local pr_number="$1"
    local max_wait="${2:-600}"  # max 10 minutes by default
    local elapsed=0
    local interval=30

    log_info "Waiting for CI checks to pass on PR #${pr_number} (max ${max_wait}s)..."

    while [ $elapsed -lt $max_wait ]; do
        local status=""
        status=$(gh pr checks "$pr_number" --repo "$REPO" --json state 2>/dev/null | jq -r '.state // "PENDING"' 2>/dev/null) || status="PENDING"

        case "$status" in
            SUCCESS)
                log_ok "All CI checks passed on PR #${pr_number}."
                return 0
                ;;
            FAILURE|CANCELLED|ERROR)
                log_error "CI checks failed on PR #${pr_number} (state: $status)."
                return 1
                ;;
            *)
                log_info "CI checks still running on PR #${pr_number} (state: $status). Waiting ${interval}s..."
                sleep $interval
                elapsed=$((elapsed + interval))
                ;;
        esac
    done

    log_error "Timed out waiting for CI checks on PR #${pr_number}."
    return 1
}

# -----------------------------------------------------------------------------
# Merge PR towards develop
# -----------------------------------------------------------------------------
merge_pr() {
    local pr_number="$1"

    log_info "Merging PR #${pr_number} towards develop..."

    # Check if PR can be merged (no conflicts)
    local mergeable=""
    mergeable=$(gh pr view "$pr_number" --repo "$REPO" --json mergeable 2>/dev/null | jq -r '.mergeable // "UNKNOWN"' 2>/dev/null) || mergeable="UNKNOWN"

    if [ "$mergeable" = "CONFLICTING" ]; then
        log_error "PR #${pr_number} has conflicts. Please resolve them manually before merging."
        return 1
    fi

    # Perform the merge (squash merge to keep history clean)
    gh pr merge "$pr_number" --repo "$REPO" --squash --delete-branch 2>&1 || {
        log_error "Failed to merge PR #${pr_number}."
        return 1
    }

    log_ok "PR #${pr_number} merged successfully towards develop."
    return 0
}

# -----------------------------------------------------------------------------
# Extract issue number from a commit message
# -----------------------------------------------------------------------------
extract_issue_number_from_commit() {
    local msg="$1"
    local num=""
    num=$(echo "$msg" | sed -n 's/.*Closes #\([0-9]*\).*/\1/p')
    if [ -z "$num" ]; then
        num=$(echo "$msg" | sed -n 's/.*DEVOPS-\([0-9]*\).*/\1/p')
    fi
    if [ -z "$num" ]; then
        num=$(echo "$msg" | sed -n 's/.*FEATURE-\([0-9]*\).*/\1/p')
    fi
    if [ -z "$num" ]; then
        num=$(echo "$msg" | sed -n 's/.*FEAT-\([0-9]*\).*/\1/p')
    fi
    if [ -z "$num" ]; then
        num=$(echo "$msg" | sed -n 's/.*HOTFIX-\([0-9]*\).*/\1/p')
    fi
    echo "$num"
}

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
main() {
    check_gh_auth
    check_not_on_protected_branch

    # -------------------------------------------------------------------------
    # Get arguments
    # -------------------------------------------------------------------------
    local tipo nombre
    tipo=$(ask_type "${1:-}")
    nombre=$(ask_name "${2:-}")
    nombre=$(normalize_name "$nombre")

    local current_branch
    current_branch=$(git branch --show-current)

    # Validate branch name matches type prefix
    local expected_prefix="${tipo}/"
    if [[ "$current_branch" != "${expected_prefix}"* ]]; then
        log_warn "Current branch '$current_branch' does not start with '${expected_prefix}'."
        if ! confirm "Continue anyway?"; then
            exit 1
        fi
    fi

    local branch_name="$current_branch"

    log_info "Syncing branch '$branch_name' to develop..."

    # Check develop is updated
    check_develop_updated

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
                commit_msg="${tipo}: $nombre"
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

    # Determine PR target branch
    local target
    target=$(pr_target_branch)

    # Get list of changed files vs develop
    local changed_files=""
    changed_files=$(git diff --name-only origin/develop.."$branch_name" 2>/dev/null) || changed_files=""

    # Build PR title and body
    local pr_title pr_body
    pr_title="${tipo}: $nombre"

    # Detect issue number from last commit
    local issue_num=""
    local last_commit_msg=""
    last_commit_msg=$(git log -1 --format="%s" 2>/dev/null) || last_commit_msg=""
    issue_num=$(extract_issue_number_from_commit "$last_commit_msg")

    pr_body=$(build_pr_body "$tipo" "$branch_name" "$target" "$changed_files" "$issue_num")

    # Check if a PR already exists towards develop from this branch
    local existing_pr=""
    existing_pr=$(gh pr list \
        --repo "$REPO" \
        --head "$branch_name" \
        --base "develop" \
        --state open \
        --json url,title,number \
        --jq '.[0].url // empty' 2>/dev/null) || existing_pr=""

    local pr_number=""
    local pr_url=""
    if [ -n "$existing_pr" ]; then
        pr_url="$existing_pr"
        pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$' | head -n1)
        log_warn "A Pull Request already exists towards develop from this branch:"
        log_ok "Pull Request: $pr_url"
    else
        # Create PR
        log_info "Creating Pull Request towards develop..."
        local create_output=""
        create_output=$(gh pr create \
            --repo "$REPO" \
            --base "develop" \
            --head "$branch_name" \
            --title "$pr_title" \
            --body "$pr_body" 2>&1) || {
            log_error "Failed to create Pull Request. gh output:"
            echo "$create_output"
            exit 1
        }
        # Extract the PR URL and number
        pr_url=$(echo "$create_output" | grep -oE 'https://github.com/[^/]+/[^/]+/pull/[0-9]+' | head -n1)
        pr_number=$(echo "$pr_url" | grep -oE '[0-9]+$' | head -n1)
        if [ -z "$pr_url" ]; then
            log_error "Could not determine the Pull Request URL from gh output."
            exit 1
        fi
        log_ok "Pull Request created: $pr_url"
    fi

    # Wait for CI checks to pass
    if [ -n "$pr_number" ]; then
        if wait_for_ci "$pr_number"; then
            # Merge the PR
            if merge_pr "$pr_number"; then
                log_ok "Sync complete. Branch '$branch_name' has been merged into develop."
            else
                log_error "Merge failed. PR #${pr_number} remains open."
                exit 1
            fi
        else
            log_error "CI checks did not pass. PR #${pr_number} remains open for manual review."
            exit 1
        fi
    fi

    echo
    echo "========================================================================"
    log_ok "Summary:"
    echo "  - Branch: $branch_name"
    log_ok "  - PR: $pr_url"
    echo "  - Target: $target"
    echo "  - Status: Merged into develop"
    echo "========================================================================"
}

main "$@"
