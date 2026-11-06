#!/usr/bin/env bash
#
# new-work.sh - Script para iniciar trabajo siguiendo el flujo de contribución del proyecto.
#
# Uso:
#   ./scripts/new-work.sh [tipo] [numero-issue] [nombre-descriptivo]
#
# Los argumentos son opcionales y pueden ir en cualquier orden. El script detecta
# automáticamente si cada argumento es un tipo (feature/hotfix/devops/chore/release),
# un número de issue o un nombre descriptivo. Los argumentos que faltan se piden
# de forma interactiva.
#
# Ejemplos:
#   ./scripts/new-work.sh feature 42 implementar-comando-privmsg
#   ./scripts/new-work.sh 42 implementar-comando-privmsg
#   ./scripts/new-work.sh feature 42
#   ./scripts/new-work.sh 42
#   ./scripts/new-work.sh implementar-comando-privmsg
#   ./scripts/new-work.sh hotfix 101 corregir-fuga-memoria
#   ./scripts/new-work.sh devops 5 actualizar-plan-implementacion
#   ./scripts/new-work.sh release 200 v1-0-0
#
# Tipos soportados: feature, hotfix, devops, chore, release
#
# El flujo:
#   1. Verifica que estás en develop y está actualizado con origin/develop
#   2. Crea la rama desde develop con el nombre <tipo>/<issue>-<nombre>
#   3. Sube la rama a origin
#   4. Crea un Pull Request hacia develop (o main para release)
#
# Si se indica un número de issue, el script consulta la API de GitHub (GraphQL)
# para obtener los sub-issues (hijos) del issue e incluye "Closes #N" en el cuerpo
# del PR para que GitHub cierre automáticamente el issue y sus hijos al hacer merge.
#
# Después del merge, recuerda:
#   - Eliminar la rama
#   - Cerrar el issue correspondiente (si no se cerró automáticamente)

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
            log_error "Debes estar en 'develop' para iniciar trabajo."
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
                    log_error "Debes sincronizar 'develop' antes de crear una rama."
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
# Detectar el tipo de un argumento (tipo / numero / nombre)
# -----------------------------------------------------------------------------
detect_arg() {
    local arg="$1"
    case "$arg" in
        feature|hotfix|devops|chore|release) echo "tipo" ;;
        *[!0-9]*) echo "nombre" ;;
        "") echo "vacio" ;;
        *) echo "numero" ;;
    esac
}

# -----------------------------------------------------------------------------
# Pedir tipo de cambio si no se proporciona
# -----------------------------------------------------------------------------
ask_type() {
    local tipo="$1"
    if [ -n "$tipo" ]; then
        echo "$tipo"
        return
    fi

    echo "Tipos de cambio disponibles:"
    echo "  1) feature  - Implementar una feature nueva"
    echo "  2) hotfix   - Arreglo puntual de un bug"
    echo "  3) devops   - Infraestructura, CI, documentación, repo"
    echo "  4) chore    - Tareas de mantenimiento (formatting, dependencias)"
    echo "  5) release  - Sincronizar develop hacia main"
    echo
    read -r -p "Selecciona el tipo (1-5 o nombre): " choice

    case "$choice" in
        1|feature) echo "feature" ;;
        2|hotfix)  echo "hotfix" ;;
        3|devops)  echo "devops" ;;
        4|chore)   echo "chore" ;;
        5|release) echo "release" ;;
        feature|hotfix|devops|chore|release) echo "$choice" ;;
        *) log_error "Tipo inválido: '$choice'"; exit 1 ;;
    esac
}

# -----------------------------------------------------------------------------
# Pedir número de issue si no se proporciona
# -----------------------------------------------------------------------------
ask_issue_number() {
    local num="$1"
    if [ -n "$num" ]; then
        echo "$num"
        return
    fi
    read -r -p "Número de issue (o presiona Enter para omitir): " num
    echo "$num"
}

# -----------------------------------------------------------------------------
# Pedir nombre descriptivo si no se proporciona
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
# Construir nombre de rama
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
# Determinar rama destino del PR
# -----------------------------------------------------------------------------
pr_target_branch() {
    local tipo="$1"
    if [ "$tipo" = "release" ]; then
        echo "main"
    else
        echo "develop"
    fi
}

# -----------------------------------------------------------------------------
# Obtener sub-issues (hijos) de un issue mediante GraphQL
# Devuelve una lista de números de issue, uno por línea.
# -----------------------------------------------------------------------------
get_sub_issues() {
    local issue_num="$1"
    local result=""

    if ! command -v jq &>/dev/null; then
        log_warn "jq no está instalado; no se podrán obtener los sub-issues del issue #$issue_num."
        return
    fi

    result=$(gh api graphql \
        -f query='query($owner: String!, $repo: String!, $number: Int!) { repository(owner: $owner, name: $repo) { issue(number: $number) { subIssues(first: 100) { nodes { number title state } } } } }' \
        -f owner="$OWNER" \
        -f repo="$REPO_NAME" \
        -F number="$issue_num" 2>/dev/null) || result=""

    if [ -z "$result" ]; then
        log_warn "No se pudieron obtener los sub-issues del issue #$issue_num (¿existe el issue? ¿tiene sub-issues?)."
        return
    fi

    echo "$result" | jq -r '.data.repository.issue.subIssues.nodes[].number // empty' 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Construir la sección "Closes #N" para el cuerpo del PR (issue + sub-issues)
# -----------------------------------------------------------------------------
build_closes_section() {
    local issue_num="$1"
    local lines=""
    lines="${lines}Closes #${issue_num}"
    local child
    while IFS= read -r child; do
        [ -n "$child" ] && lines="${lines}
Closes #${child}"
    done < <(get_sub_issues "$issue_num")
    echo "$lines"
}

# -----------------------------------------------------------------------------
# Función principal
# -----------------------------------------------------------------------------
main() {
    check_gh_auth
    check_develop_branch

    # -------------------------------------------------------------------------
    # Procesar argumentos: detectar tipo, número de issue y nombre (cualquier orden)
    # -------------------------------------------------------------------------
    local tipo="" issue_num="" nombre=""
    local arg
    for arg in "$@"; do
        case "$(detect_arg "$arg")" in
            tipo)
                if [ -n "$tipo" ]; then
                    log_error "Se proporcionaron varios tipos de cambio. Especifica solo uno."
                    exit 1
                fi
                tipo="$arg"
                ;;
            numero)
                if [ -n "$issue_num" ]; then
                    log_error "Se proporcionaron varios números de issue. Especifica solo uno."
                    exit 1
                fi
                issue_num="$arg"
                ;;
            nombre)
                if [ -n "$nombre" ]; then
                    log_error "Se proporcionaron varios nombres descriptivos. Especifica solo uno."
                    exit 1
                fi
                nombre="$arg"
                ;;
            vacio) ;;
        esac
    done

    # Obtener valores faltantes de forma interactiva
    tipo=$(ask_type "$tipo")
    issue_num=$(ask_issue_number "$issue_num")
    nombre=$(ask_name "$nombre")

    nombre=$(normalize_name "$nombre")
    local branch_name
    branch_name=$(build_branch_name "$tipo" "$issue_num" "$nombre")

    log_info "Rama a crear: $branch_name"

    # Verificar si la rama ya existe
    if git rev-parse --verify "$branch_name" &>/dev/null; then
        log_error "La rama '$branch_name' ya existe localmente."
        exit 1
    fi

    if git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"; then
        log_error "La rama '$branch_name' ya existe en origin."
        exit 1
    fi

    # Crear rama desde develop
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
                commit_msg="${tipo}: $nombre"
            fi
            git commit -m "$commit_msg"
        else
            log_error "Hay cambios sin commitear. Commítelos o descártelos primero."
            exit 1
        fi
    fi

    # Push de la rama
    log_info "Subiendo rama a origin..."
    git push -u origin "$branch_name"

    # Determinar rama destino del PR
    local target
    target=$(pr_target_branch "$tipo")

    # Título y cuerpo del PR
    local pr_title pr_body closes_section
    local issue_label=""
    if [ -n "$issue_num" ]; then
        issue_label="${tipo^^}-${issue_num}"
        closes_section=$(build_closes_section "$issue_num")
        pr_title="[${tipo}] ${nombre} (${issue_label})"
        pr_body="Tipo de PR: ${tipo}

Rama origen: ${branch_name}
Rama destino: ${target}

Issue relacionado: ${issue_label}

${closes_section}

Cambios realizados:
- [ ] Describir los cambios realizados

Acceptance criteria completadas:
- [ ] Listar los AC cumplidos

Lista de verificación:
- [ ] Rama creada desde develop actualizado
- [ ] Código cumple C++98 (si aplica)
- [ ] make build / make test / make valgrind pasan (si aplica)

Instrucciones para el merge:
- Fusionar hacia ${target}, eliminar la rama y cerrar el issue ${issue_label} (y sus sub-issues) cuando proceda."
    else
        pr_title="[${tipo}] ${nombre}"
        pr_body="Tipo de PR: ${tipo}

Rama origen: ${branch_name}
Rama destino: ${target}

Cambios realizados:
- [ ] Describir los cambios realizados

Acceptance criteria completadas:
- [ ] Listar los AC cumplidos

Lista de verificación:
- [ ] Rama creada desde develop actualizado
- [ ] Código cumple C++98 (si aplica)
- [ ] make build / make test / make valgrind pasan (si aplica)

Instrucciones para el merge:
- Fusionar hacia ${target}, eliminar la rama y cerrar el issue correspondiente cuando proceda."
    fi

    # Crear PR
    log_info "Creando Pull Request hacia ${target}..."
    local pr_url
    pr_url=$(gh pr create \
        --repo "$REPO" \
        --base "$target" \
        --head "$branch_name" \
        --title "$pr_title" \
        --body "$pr_body" 2>&1)

    log_ok "Pull Request creado: $pr_url"

    echo
    echo "========================================================================"
    log_ok "Resumen:"
    echo "  - Rama: $branch_name"
    log_ok "  - PR: $pr_url"
    echo "  - Target: $target"
    echo ""
    echo "Próximos pasos:"
    echo "  1. Implementa los cambios en la rama $branch_name"
    echo "  2. Commitea y push: git push origin $branch_name"
    echo "  3. Revisa que CI pase en el PR"
    echo "  4. Cuando se apruebe, fusiona hacia $target"
    echo "  5. Elimina la rama: git branch -d $branch_name && git push origin --delete $branch_name"
    if [ -n "$issue_num" ]; then
        echo "  6. GitHub cerrará automáticamente el issue #$issue_num y sus sub-issues al hacer merge."
    else
        echo "  6. Cierra el issue correspondiente si aplica."
    fi
    echo "========================================================================"
}

main "$@"
