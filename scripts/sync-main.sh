#!/usr/bin/env bash
#
# sync-main.sh - Script para sincronizar develop hacia main mediante PR de tipo release.
#
# Sigue la metodología del repositorio:
#   1. Verifica que gh está autenticado
#   2. Verifica que estás en develop y está actualizado con origin/develop
#   3. Crea una rama release/ desde develop
#   4. Commitea cambios pendientes si los hay
#   5. Sube la rama a origin
#   6. Crea un Pull Request hacia main (tipo release)
#
# Uso:
#   ./scripts/sync-main.sh [nombre-descriptivo]
#
# Ejemplo:
#   ./scripts/sync-main.sh sincronizar-release-v1-0-0
#
# Después del merge, recuerda crear una etiqueta de versión en main (ej. v1.0.0).

set -euo pipefail

REPO="LuisGrigore/ft-irc"
OWNER="LuisGrigore"
REPO_NAME="ft-irc"

# Colores para salida
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Funciones de utilidad
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
# Validar que gh está autenticado
# -----------------------------------------------------------------------------
check_gh_auth() {
    if ! gh auth status &>/dev/null; then
        log_error "GitHub CLI (gh) no está autenticado. Ejecuta: gh auth login"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Validar que estamos en develop y está actualizado
# -----------------------------------------------------------------------------
check_develop_branch() {
    local current
    current=$(git branch --show-current)

    if [ "$current" != "develop" ]; then
        log_warn "No estás en la rama 'develop'. Estás en '$current'."
        if confirm "¿Cambiar a 'develop' y hacer pull?"; then
            git checkout develop
            git pull origin develop
        else
            log_error "Debes estar en 'develop' para sincronizar con main."
            exit 1
        fi
    else
        log_info "Estás en la rama 'develop'. Verificando actualizaciones..."
        if git fetch origin develop 2>/dev/null; then
            local local_sha remote_sha
            local_sha=$(git rev-parse develop)
            remote_sha=$(git rev-parse origin/develop 2>/dev/null || echo "$local_sha")
            if [ "$local_sha" != "$remote_sha" ]; then
                log_warn "Tu rama 'develop' no está actualizada con origin/develop."
                if confirm "¿Hacer pull de origin/develop?"; then
                    git pull origin develop
                else
                    log_error "Debes sincronizar 'develop' antes de crear la rama release."
                    exit 1
                fi
            else
                log_ok "'develop' está actualizado."
            fi
        else
            log_warn "No se pudo verificar con origin/develop. Asegúrate de tener conexión."
        fi
    fi
}

# -----------------------------------------------------------------------------
# Pedir nombre descriptivo (si no se proporciona)
# -----------------------------------------------------------------------------
ask_name() {
    local name="$1"
    if [ -n "$name" ]; then
        echo "$name"
        return
    fi
    read -r -p "Nombre descriptivo (sin espacios, usa guiones): " name
    echo "$name"
}

# -----------------------------------------------------------------------------
# Normalizar nombre para rama (minúsculas, guiones en lugar de espacios)
# -----------------------------------------------------------------------------
normalize_name() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//'
}

# -----------------------------------------------------------------------------
# Construir nombre de rama release
# -----------------------------------------------------------------------------
build_branch_name() {
    local name="$1"

    if [ -n "$name" ]; then
        echo "release/${name}"
    else
        echo "release/sincronizar-develop-a-main"
    fi
}

# -----------------------------------------------------------------------------
# Determinar rama destino del PR
# -----------------------------------------------------------------------------
pr_target_branch() {
    echo "main"
}

# -----------------------------------------------------------------------------
# Construir cuerpo del PR siguiendo la plantilla de GitHub
# -----------------------------------------------------------------------------
build_pr_body() {
    local branch_name="$1"
    local changed_files="$2"

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

No associated issue.

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

- **For PRs of type \`release\`:** merge \`develop\` into \`main\` (direct synchronization, no release pipeline). After merge on \`main\`, create a version tag (e.g. \`v1.0.0\`).
EOF
}

# -----------------------------------------------------------------------------
# Función principal
# -----------------------------------------------------------------------------
main() {
    check_gh_auth
    check_develop_branch

    # -------------------------------------------------------------------------
    # Obtener nombre descriptivo
    # -------------------------------------------------------------------------
    local nombre
    nombre=$(ask_name "${1:-}")
    nombre=$(normalize_name "$nombre")
    local branch_name
    branch_name=$(build_branch_name "$nombre")

    log_info "Rama release a crear: $branch_name"

    # Verificar si la rama ya existe
    if git rev-parse --verify "$branch_name" &>/dev/null; then
        log_error "La rama '$branch_name' ya existe localmente."
        exit 1
    fi

    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        log_error "La rama '$branch_name' ya existe en origin."
        exit 1
    fi

    # Verificar si hay cambios pendientes entre develop y main
    local diff_count=""
    diff_count=$(git log origin/main..develop --oneline 2>/dev/null | wc -l) || diff_count="0"
    log_info "Commits pendientes entre main y develop: $diff_count"

    # Crear rama release desde develop
    log_info "Creando rama '$branch_name' desde develop..."
    git checkout -b "$branch_name"

    # Si hay cambios sin commitear, preguntar qué hacer
    if ! git diff --quiet || ! git diff --cached --quiet; then
        log_warn "Hay cambios sin commitear en el working tree."
        if confirm "¿Hacer commit de los cambios antes de continuar?"; then
            git add -A
            local commit_msg
            read -r -p "Mensaje de commit: " commit_msg
            if [ -z "$commit_msg" ]; then
                commit_msg="release: sincronizar develop hacia main ($nombre)"
            fi
            git commit -m "$commit_msg"
        else
            log_error "Hay cambios sin commitear. Commítelos o descártelos primero."
            exit 1
        fi
    fi

    # Verificar que haya al menos un commit de diferencia entre main y la rama release
    local diff_commits=""
    diff_commits=$(git log origin/main.."$branch_name" --oneline 2>/dev/null) || diff_commits=""
    if [ -z "$diff_commits" ]; then
        log_warn "No hay commits de diferencia entre main y '$branch_name'. Creando un commit vacío para permitir el PR..."
        git commit --allow-empty -m "release: sincronizar develop hacia main ($nombre)"
        log_ok "Commit vacío creado."
    fi

    # Push de la rama
    log_info "Subiendo rama a origin..."
    git push -u origin "$branch_name"

    # Determinar rama destino del PR
    local target="main"

    # Obtener lista de archivos cambiados
    local changed_files=""
    changed_files=$(git diff --name-only origin/main.."$branch_name" 2>/dev/null) || changed_files=""

    # Construir cuerpo del PR
    local pr_title pr_body
    pr_title="release: sincronizar develop hacia main ($nombre)"
    pr_body=$(build_pr_body "$branch_name" "$changed_files")

    # Verificar si ya existe un PR abierto hacia main desde esta rama
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
        log_warn "Ya existe un Pull Request abierto hacia main desde esta rama:"
        log_ok "Pull Request: $pr_url"
    else
        # Crear PR
        log_info "Creando Pull Request hacia main..."
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
        # Extraer la URL del PR
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
    log_ok "Resumen:"
    echo "  - Rama: $branch_name"
    log_ok "  - PR: $pr_url"
    echo "  - Target: main"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Revisa que CI pase en el PR"
    echo "  2. Cuando se apruebe, fusiona hacia main"
    echo "  3. Después del merge, crea una etiqueta de versión en main (ej. v1.0.0)"
    echo "  4. Elimina la rama: git branch -d $branch_name && git push origin --delete $branch_name"
    echo "========================================================================"
}

main "$@"
