#!/usr/bin/env bash
#
# generate-changelog.sh - Script to automatically generate and update CHANGELOG.md.
#
# Parses commits using the conventional commit format:
#   <type>: <short description> [(<TRACEABILITY_ID>)] [Closes #<ISSUE_NUMBER>]
#
# Extracts traceability IDs (FEAT/T/HOTFIX/DEVOPS/AC) and issue numbers,
# groups changes by category, and generates CHANGELOG.md with links to
# the hosting platform (issues and commits).
#
# The script is repository-agnostic: the base URL used for links is derived from
# the git remote, so it works unchanged in any repository. If no usable remote is
# found, entries are generated without links.
#
# Usage:
#   ./scripts/generate-changelog.sh [mode] [output-file]
#
# Modes:
#   release  - Generate from the last tag to HEAD (for releases)
#   sync     - Generate from the main branch to the develop branch (for sync PRs)
#   all      - Generate the full history
#
# Environment variables (all optional):
#   REMOTE          Remote used to build links and resolve branches (default: origin)
#   MAIN_BRANCH     Name of the main branch (default: main)
#   DEVELOP_BRANCH  Name of the develop branch (default: develop)
#   REPO_URL        Base URL override, e.g. https://github.com/owner/repo
#
# Examples:
#   ./scripts/generate-changelog.sh release CHANGELOG.md
#   ./scripts/generate-changelog.sh sync CHANGELOG.md
#   MAIN_BRANCH=master ./scripts/generate-changelog.sh sync CHANGELOG.md
#
# After generating, review the file, commit it, and open a PR.

set -euo pipefail

REMOTE="${REMOTE:-origin}"
MAIN_BRANCH="${MAIN_BRANCH:-main}"
DEVELOP_BRANCH="${DEVELOP_BRANCH:-develop}"

# Base URL of the repository (e.g. https://github.com/owner/repo). Set in main().
BASE_URL=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Utility functions
# Logs go to stderr so they never end up inside captured output (CHANGELOG.md).
# -----------------------------------------------------------------------------
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*" >&2; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# -----------------------------------------------------------------------------
# Derive the repository base URL from the git remote (or REPO_URL override).
# Handles:  git@host:owner/repo(.git)   ssh://git@host[:port]/owner/repo(.git)
#           https://[user[:token]@]host/owner/repo(.git)
# Prints nothing if no usable http(s) URL can be derived.
# -----------------------------------------------------------------------------
get_repo_url() {
    if [ -n "${REPO_URL:-}" ]; then
        echo "${REPO_URL%/}"
        return
    fi

    local remote_url=""
    remote_url=$(git remote get-url "$REMOTE" 2>/dev/null) || remote_url=""
    if [ -z "$remote_url" ]; then
        return
    fi

    local url=""
    url=$(echo "$remote_url" | sed -E \
        -e 's#^git@([^:]+):#https://\1/#' \
        -e 's#^ssh://[^@/]+@([^/:]+)(:[0-9]+)?/#https://\1/#' \
        -e 's#^(https?://)[^@/]+@#\1#' \
        -e 's#\.git$##' \
        -e 's#/+$##')

    case "$url" in
        http://*|https://*) echo "$url" ;;
        *) ;;
    esac
}

# -----------------------------------------------------------------------------
# Extract the type from a commit subject line
# -----------------------------------------------------------------------------
extract_type() {
    local subject="$1"
    echo "$subject" | sed -n 's/^\([a-z]*\):.*/\1/p'
}

# -----------------------------------------------------------------------------
# Extract the traceability ID from a commit subject line
# -----------------------------------------------------------------------------
extract_traceability_id() {
    local subject="$1"
    echo "$subject" | sed -n 's/.*(\([A-Z]*-[0-9]*\)).*/\1/p'
}

# -----------------------------------------------------------------------------
# Extract the issue number from a commit subject line (Closes #N)
# -----------------------------------------------------------------------------
extract_issue_number() {
    local subject="$1"
    echo "$subject" | sed -n 's/.*Closes #\([0-9]*\).*/\1/p'
}

# -----------------------------------------------------------------------------
# Extract the short description from a commit subject line
# -----------------------------------------------------------------------------
extract_description() {
    local subject="$1"
    # Remove "type: " prefix
    local desc=""
    desc=$(echo "$subject" | sed 's/^[a-z]*: //')
    # Remove traceability ID part: " (ID...)"
    desc=$(echo "$desc" | sed 's/ ([A-Z]*-[0-9]*)//')
    # Remove "Closes #N" part
    desc=$(echo "$desc" | sed 's/ \[Closes #.*//')
    echo "$desc"
}

# -----------------------------------------------------------------------------
# Resolve a branch name to an existing ref.
#   $1 = branch name
#   $2 = preference: "remote" (use <remote>/<branch> if present) or "local"
# Prints the ref, or nothing if the branch does not exist anywhere.
# -----------------------------------------------------------------------------
resolve_ref() {
    local branch="$1"
    local prefer="$2"
    local remote_ref="refs/remotes/${REMOTE}/${branch}"
    local local_ref="refs/heads/${branch}"

    if [ "$prefer" = "remote" ]; then
        if git rev-parse --verify --quiet "$remote_ref" >/dev/null; then
            echo "${REMOTE}/${branch}"; return
        fi
        if git rev-parse --verify --quiet "$local_ref" >/dev/null; then
            echo "$branch"; return
        fi
    else
        if git rev-parse --verify --quiet "$local_ref" >/dev/null; then
            echo "$branch"; return
        fi
        if git rev-parse --verify --quiet "$remote_ref" >/dev/null; then
            echo "${REMOTE}/${branch}"; return
        fi
    fi
}

# -----------------------------------------------------------------------------
# Get the commit range based on mode
# -----------------------------------------------------------------------------
get_commit_range() {
    local mode="$1"
    case "$mode" in
        release)
            local last_tag=""
            last_tag=$(git describe --tags --abbrev=0 2>/dev/null) || last_tag=""
            if [ -z "$last_tag" ]; then
                echo "HEAD"
            else
                echo "${last_tag}..HEAD"
            fi
            ;;
        sync)
            # main: prefer the remote ref (a local main is often stale)
            # develop: prefer the local ref (may contain not-yet-pushed commits)
            local main_ref="" develop_ref=""
            main_ref=$(resolve_ref "$MAIN_BRANCH" remote)
            develop_ref=$(resolve_ref "$DEVELOP_BRANCH" local)
            if [ -z "$main_ref" ]; then
                log_error "Branch '$MAIN_BRANCH' not found (locally or on '$REMOTE'). Set MAIN_BRANCH."
                exit 1
            fi
            if [ -z "$develop_ref" ]; then
                log_error "Branch '$DEVELOP_BRANCH' not found (locally or on '$REMOTE'). Set DEVELOP_BRANCH."
                exit 1
            fi
            echo "${main_ref}..${develop_ref}"
            ;;
        all)
            echo "HEAD"
            ;;
        *)
            log_error "Invalid mode: $mode. Use: release, sync, or all."
            exit 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# Format a commit entry for the changelog
# -----------------------------------------------------------------------------
format_commit_entry() {
    local commit_hash="$1"
    local subject="$2"
    local type="$3"
    local trace_id="$4"
    local issue_num="$5"
    local desc="$6"

    local short_sha=""
    short_sha=$(echo "$commit_hash" | cut -c1-7)

    local commit_link="$short_sha"
    if [ -n "$BASE_URL" ]; then
        commit_link="[${short_sha}](${BASE_URL}/commit/${commit_hash})"
    fi

    local issue_link=""
    if [ -n "$issue_num" ]; then
        if [ -n "$BASE_URL" ]; then
            issue_link=" [Closes #${issue_num}](${BASE_URL}/issues/${issue_num})"
        else
            issue_link=" Closes #${issue_num}"
        fi
    fi

    local trace_text=""
    if [ -n "$trace_id" ]; then
        trace_text=" (**${trace_id}**)"
    fi

    if [ -z "$desc" ]; then
        desc="$subject"
    fi

    echo "- ${commit_link} ${desc}${trace_text}${issue_link}"
}

# -----------------------------------------------------------------------------
# Generate the changelog content
# -----------------------------------------------------------------------------
generate_changelog() {
    local mode="$1"
    local range=""
    range=$(get_commit_range "$mode")

    log_info "Generating changelog for commit range: $range"

    # Get commits: hash and subject, newest first, exclude merge commits
    # Format: HASH<TAB>SUBJECT
    local commits=""
    commits=$(git log --format="%H%x09%s" --no-merges "$range" 2>/dev/null) || commits=""

    if [ -z "$commits" ]; then
        log_warn "No commits found in range: $range"
        return
    fi

    # Group commits by type
    local section_feature="" section_devops="" section_hotfix="" section_chore="" section_release=""

    while IFS=$'\t' read -r commit_hash subject; do
        [ -z "$commit_hash" ] && continue

        local type desc trace_id issue_num
        type=$(extract_type "$subject")
        desc=$(extract_description "$subject")
        trace_id=$(extract_traceability_id "$subject")
        issue_num=$(extract_issue_number "$subject")

        local entry=""
        entry=$(format_commit_entry "$commit_hash" "$subject" "$type" "$trace_id" "$issue_num" "$desc")

        case "$type" in
            feature)
                section_feature="${section_feature}${entry}
"
                ;;
            devops)
                section_devops="${section_devops}${entry}
"
                ;;
            hotfix)
                section_hotfix="${section_hotfix}${entry}
"
                ;;
            chore)
                section_chore="${section_chore}${entry}
"
                ;;
            release)
                section_release="${section_release}${entry}
"
                ;;
            *)
                section_feature="${section_feature}${entry}
"
                ;;
        esac
    done <<< "$commits"

    # Build the changelog
    local date_str=""
    date_str=$(date +"%Y-%m-%d")

    local version_tag=""
    version_tag=$(git describe --tags --abbrev=0 2>/dev/null) || version_tag="Unreleased"

    cat <<EOF
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [${version_tag}] - ${date_str}

### Generated from commit range: \`${range}\`

$(if [ -n "$section_feature" ]; then echo "### Features

${section_feature}"; fi)

$(if [ -n "$section_devops" ]; then echo "### Devops

${section_devops}"; fi)

$(if [ -n "$section_hotfix" ]; then echo "### Hotfixes

${section_hotfix}"; fi)

$(if [ -n "$section_chore" ]; then echo "### Chore

${section_chore}"; fi)

$(if [ -n "$section_release" ]; then echo "### Release

${section_release}"; fi)

---

*Generated by \`scripts/generate-changelog.sh\` on ${date_str}.*
EOF
}

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
main() {
    local mode="${1:-release}"
    local output_file="${2:-CHANGELOG.md}"

    if ! git rev-parse --is-inside-work-tree &>/dev/null; then
        log_error "Not inside a git repository."
        exit 1
    fi

    BASE_URL=$(get_repo_url)
    if [ -n "$BASE_URL" ]; then
        log_info "Repository URL: $BASE_URL"
    else
        log_warn "Could not derive a repository URL from remote '$REMOTE'. Entries will have no links."
    fi

    log_info "Generating changelog in mode: $mode"
    log_info "Output file: $output_file"

    local changelog_content=""
    changelog_content=$(generate_changelog "$mode")

    if [ -z "$changelog_content" ]; then
        log_error "Failed to generate changelog content."
        exit 1
    fi

    echo "$changelog_content" > "$output_file"

    log_ok "Changelog generated: $output_file"

    # Show a preview
    echo ""
    echo "========================================================================"
    log_info "Preview:"
    echo "========================================================================"
    head -40 "$output_file"
    echo "..."
    echo "========================================================================"
    echo ""
    echo "Next steps:"
    echo "  1. Review the generated $output_file"
    echo "  2. Commit the changes: git add $output_file && git commit -m \"chore: update changelog\""
    echo "  3. Push and open a PR towards develop or main"
}

main "$@"