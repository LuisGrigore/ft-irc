#!/usr/bin/env bash
#
# Interactive commit helper for ft_irc.
#
# Builds a commit message following the project template:
#   <type>: <short description> [(<TRACEABILITY_ID>)] [Closes #<ISSUE_NUMBER>]
#
# Usage:
#   ./commit.sh              Ask for each field and create the commit
#   ./commit.sh -n|--dry-run Ask for each field and print the message instead of committing
#   ./commit.sh -h|--help    Show this help

set -euo pipefail

TYPES=(feature hotfix devops chore release)
ID_PREFIXES=(FEAT T HOTFIX DEVOPS AC)
MAX_SUBJECT_LENGTH=72

DRY_RUN=false

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
}

die() {
  echo "Error: $*" >&2
  exit 1
}

# Asks the user to pick one item from a numbered list.
# Usage: choose "<prompt>" <default_index (1-based)> <option>...
# Result is stored in CHOICE_INDEX (0-based).
choose() {
  local prompt=$1 default=$2
  shift 2
  local options=("$@") i answer

  while true; do
    printf '\n%s\n' "$prompt" >&2
    for i in "${!options[@]}"; do
      printf '  %d) %s\n' "$((i + 1))" "${options[$i]}" >&2
    done
    read -r -p "Choose [1-${#options[@]}] (default: $default): " answer
    answer=${answer:-$default}

    if [[ $answer =~ ^[0-9]+$ ]] && ((answer >= 1 && answer <= ${#options[@]})); then
      CHOICE_INDEX=$((answer - 1))
      return
    fi
    echo "Invalid choice, try again." >&2
  done
}

# Asks a yes/no question. Usage: confirm "<prompt>" <default: y|n>
confirm() {
  local prompt=$1 default=$2 answer hint
  if [[ $default == y ]]; then hint="[Y/n]"; else hint="[y/N]"; fi

  while true; do
    read -r -p "$prompt $hint: " answer
    answer=${answer:-$default}
    case ${answer,,} in
      y | yes) return 0 ;;
      n | no) return 1 ;;
      *) echo "Please answer y or n." >&2 ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# Field prompts (each one stores its result in a global variable)
# ---------------------------------------------------------------------------

ask_type() {
  choose "Commit type:" 1 "${TYPES[@]}"
  TYPE=${TYPES[$CHOICE_INDEX]}
}

ask_description() {
  local input first

  while true; do
    echo >&2
    read -r -p "Short description (imperative, e.g. 'implement client getters'): " input

    # Trim leading/trailing whitespace
    input="${input#"${input%%[![:space:]]*}"}"
    input="${input%"${input##*[![:space:]]}"}"

    # No period at the end
    while [[ $input == *. ]]; do input=${input%.}; done

    if [[ -z $input ]]; then
      echo "The description cannot be empty." >&2
      continue
    fi

    # Lowercase the first character only (keeps identifiers like "Client" intact)
    first=$(printf '%s' "${input:0:1}" | tr '[:upper:]' '[:lower:]')
    DESCRIPTION="${first}${input:1}"
    return
  done
}

ask_traceability() {
  local default_index number
  local options=("${ID_PREFIXES[@]}" "none (no traceability ID)")
  local none_index=${#ID_PREFIXES[@]}

  # Suggest the most likely prefix for the chosen type
  case $TYPE in
    feature) default_index=1 ;; # FEAT
    hotfix) default_index=3 ;;  # HOTFIX
    devops) default_index=4 ;;  # DEVOPS
    *) default_index=$((none_index + 1)) ;;
  esac

  choose "Traceability ID prefix:" "$default_index" "${options[@]}"

  TRACE_ID=""
  if ((CHOICE_INDEX == none_index)); then
    return
  fi

  local prefix=${ID_PREFIXES[$CHOICE_INDEX]}
  while true; do
    read -r -p "Number for ${prefix}-NNN (digits only): " number
    if [[ $number =~ ^[0-9]{1,6}$ ]]; then
      printf -v number '%03d' "$((10#$number))"
      TRACE_ID="${prefix}-${number}"
      return
    fi
    echo "Invalid number, digits only." >&2
  done
}

ask_issue() {
  local input

  ISSUE=""
  while true; do
    echo >&2
    read -r -p "GitHub issue closed by this commit (number, empty to skip): " input
    input=${input#\#}
    input="${input//[[:space:]]/}"

    if [[ -z $input ]]; then
      return
    fi
    if [[ $input =~ ^[0-9]+$ ]]; then
      ISSUE=$((10#$input))
      return
    fi
    echo "Invalid issue number, digits only." >&2
  done
}

build_message() {
  MESSAGE="${TYPE}: ${DESCRIPTION}"
  if [[ -n $TRACE_ID ]]; then
    MESSAGE+=" (${TRACE_ID})"
  fi
  if [[ -n $ISSUE ]]; then
    MESSAGE+=" Closes #${ISSUE}"
  fi
}

# ---------------------------------------------------------------------------
# Git checks
# ---------------------------------------------------------------------------

ensure_staged_changes() {
  if ! git diff --cached --quiet; then
    return
  fi

  echo "There are no staged changes." >&2
  if $DRY_RUN; then
    echo "(dry run: continuing anyway)" >&2
    return
  fi

  echo >&2
  git status --short >&2
  echo >&2

  if confirm "Stage all changes (git add -A)?" n; then
    git add -A
    if git diff --cached --quiet; then
      die "Nothing to commit."
    fi
  else
    die "Stage your changes first (git add ...) and run this script again."
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

while (($# > 0)); do
  case $1 in
    -n | --dry-run) DRY_RUN=true ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      die "Unknown option: $1"
      ;;
  esac
  shift
done

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Not inside a git repository."

ensure_staged_changes

if ! git diff --cached --quiet; then
  echo >&2
  echo "Staged changes:" >&2
  git diff --cached --stat >&2
fi

ask_type
ask_description
ask_traceability
ask_issue
build_message

echo >&2
echo "----------------------------------------" >&2
echo "Commit message:" >&2
if ((${#MESSAGE} > MAX_SUBJECT_LENGTH)); then
  echo "(warning: ${#MESSAGE} characters, recommended maximum is ${MAX_SUBJECT_LENGTH})" >&2
fi

if $DRY_RUN; then
  echo "[dry run - no commit will be created]" >&2
  echo "----------------------------------------" >&2
  echo "$MESSAGE"
  exit 0
fi

echo "  $MESSAGE" >&2
echo "----------------------------------------" >&2

if confirm "Create the commit?" y; then
  git commit -m "$MESSAGE"
else
  echo "Commit cancelled." >&2
  exit 1
fi