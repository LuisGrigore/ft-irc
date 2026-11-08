# Contributing Guide

Practical guide for joining the project. The project is written in **C++98** and uses CMake, CTest, CppUTest, Valgrind and GitHub Actions (according to `AgentGuide.md`).

The implementation work is organized according to the [Implementation Plan](docs/implementation_plan.md), which defines features (FEAT-…), tasks (T-…), and acceptance criteria (AC-…) with traceability IDs.

## Work organization: Features, Tasks and acceptance criteria

All work is organized into **issues** with **traceability IDs** so they can be referenced from commits, branches and pull requests. The full traceability plan is documented in [docs/implementation_plan.md](docs/implementation_plan.md).

### Issue types

| Issue type | Example ID | Associated branch | Description |
|---|---|---|---|
| Feature | `FEAT-001` | `feature/…` | Top-level unit of work. Has acceptance criteria and can be broken down into tasks. |
| Task | `T-001` | `feature/…` (of its parent feature) | Smaller unit of work. It is a **sub-issue** of a parent feature. |
| Hotfix | `HOTFIX-001` | `hotfix/…` | One-off fix for a critical bug. |
| Devops | `DEVOPS-001` | `devops/…` | Infrastructure, CI, scripts, documentation or repository configuration. |

### Traceability IDs

Each issue should have a traceability ID in its title or body:

- Feature: `FEAT-NNN`
- Task: `T-NNN`
- Hotfix: `HOTFIX-NNN`
- Devops: `DEVOPS-NNN`

**Acceptance criteria** also carry their own traceability ID, e.g. `AC-001`, `AC-002`. A feature is considered complete only when all its acceptance criteria (and those of its tasks) are fulfilled and validated.

### Create a feature

1. Open a **Feature** issue using the GitHub template.
2. Assign an ID `FEAT-NNN` (see available feature IDs in [docs/implementation_plan.md](docs/implementation_plan.md)).
3. Define the acceptance criteria (`AC-…`).
4. If needed, break down the feature into tasks: open **Task** issues with ID `T-NNN`, indicating the parent feature (`FEAT-NNN`) and their own acceptance criteria.

### Create a hotfix

1. Open a **Hotfix** issue using the GitHub template.
2. Assign an ID `HOTFIX-NNN`.
3. Describe the bug, its impact and the acceptance criteria to mark it resolved.

### Create a devops issue

For infrastructure, CI, scripts, documentation or repository configuration changes, open a **Devops** issue with ID `DEVOPS-NNN`.

## Branch types

| Prefix | Purpose | Source | PR target |
|---|---|---|---|
| `feature/` | Implement a feature | `develop` | `develop` |
| `hotfix/` | One-off bug fix | `develop` | `develop` |
| `devops/` | Infrastructure, CI, documentation, repository | `develop` | `develop` |
| `release/` | Synchronize `develop` into `main` | `develop` | `main` |

**Note:** There is no release pipeline. A `release` PR only synchronizes `main` with `develop`; after the merge, create a version tag on `main`.

## Create a branch

Always start from an up-to-date `develop`:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/short-description    # or hotfix/…, devops/…, release/…
```

When finished:

```bash
git add -A
git commit -m "type: short description (FEAT-001)"
git push origin feature/short-description
```

Then open the corresponding pull request (see next section).

## Script helper usage (scripts/new-work.sh)

To create a branch in an assisted way, use the [`scripts/new-work.sh`](scripts/new-work.sh) script:

```bash
./scripts/new-work.sh [type] [issue-number] [descriptive-name]
```

All arguments are optional and can be given in any order. When executed, the first thing it asks is:

> Does this work correspond to a GitHub issue? [y/N]

- **If yes:** it asks for the issue number, fetches its title from GitHub, and uses it to build the branch name.
- **If no:** it interactively asks for the type (`feature`, `hotfix`, `devops`, `chore`, `release`), a descriptive name, and, if there are uncommitted changes, the commit message.

**Note:** This script does NOT create a Pull Request. It only creates the branch, commits changes, and pushes to origin. To create the PR, wait for CI, and merge towards `develop`, use [`scripts/sync-develop.sh`](scripts/sync-develop.sh).

Examples:

```bash
# Fully interactive (the script asks for type, name, etc.)
./scripts/new-work.sh

# Type + issue number (name is derived from the issue title)
./scripts/new-work.sh feature 42

# Type + issue + custom name
./scripts/new-work.sh devops 5 update-docs

# Only issue number (type and name are prompted interactively)
./scripts/new-work.sh 42
```

More info: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commit message template

The project uses a commit message template stored in [`.gitmessage`](.gitmessage). It is activated via:

```bash
git config commit.template .gitmessage
```

The template enforces the convention:

```
<type>: <short description> [(<TRACEABILITY_ID>)] [Closes #<ISSUE_NUMBER>]
```

Where:
- `<type>`: `feature`, `hotfix`, `devops`, `chore` or `release`
- `<short description>`: imperative mood, lowercase, no period at the end
- `<TRACEABILITY_ID>`: `FEAT-NNN`, `T-NNN`, `HOTFIX-NNN`, `DEVOPS-NNN` or `AC-NNN`
- `<ISSUE_NUMBER>`: GitHub issue number closed by this commit (optional)

Examples:

```
feature: implement Client getters and setters (FEAT-001) Closes #18
devops: add commit message template (DEVOPS-159) Closes #187
```

All commits created with [`scripts/new-work.sh`](scripts/new-work.sh) use traceability IDs in their messages.

## Sync scripts usage

### scripts/sync-develop.sh

Push changes from a feature/hotfix/devops branch to `develop`. It updates the changelog, waits for CI checks to pass on the PR, and merges towards `develop` if there are no conflicts:

```bash
./scripts/sync-develop.sh [type] [descriptive-name]
```

Examples:

```bash
# Fully interactive
./scripts/sync-develop.sh

# Feature type with name
./scripts/sync-develop.sh feature implement-client-getters

# Devops type with name
./scripts/sync-develop.sh devops add-changelog-generator
```

### scripts/sync-main.sh

Synchronize `develop` into `main` via a release PR. It updates the changelog before creating the PR:

```bash
./scripts/sync-main.sh [descriptive-name]
```

Example:

```bash
# Sync release
./scripts/sync-main.sh sync-release-v1-0-0
```

### scripts/generate-changelog.sh

Automatically generate and update `CHANGELOG.md` from commit history:

```bash
./scripts/generate-changelog.sh [mode] [output-file]
```

Modes: `release` (from last tag to HEAD), `sync` (from develop to main), `all` (full history).

Example:

```bash
# Full changelog
./scripts/generate-changelog.sh all CHANGELOG.md
```

## Uso del script auxiliar (scripts/new-work.sh)

Para crear una rama y un Pull Request de forma asistida, usa el script [`scripts/new-work.sh`](scripts/new-work.sh):

```bash
./scripts/new-work.sh [tipo] [numero-issue] [nombre-descriptivo]
```

Todos los argumentos son opcionales y pueden ir en cualquier orden. Al ejecutarlo, lo primero que pregunta es:

> ¿Corresponde este trabajo a un issue de GitHub? [y/N]

- **Si sí:** pide el número de issue, obtiene su título de GitHub y lo usa para construir el nombre de la rama. El cuerpo del PR incluye `Closes #N` (para el issue y sus sub-issues), de modo que **GitHub los cierre automáticamente al hacer merge**.
- **Si no:** pide de forma interactiva el tipo (`feature`, `hotfix`, `devops`, `chore`, `release`), un nombre descriptivo y, si hay cambios sin commitear, el mensaje de commit.

El cuerpo del Pull Request sigue la [plantilla de PR de GitHub](.github/pull_request_template.md) y se rellena con los archivos modificados, el tipo de PR marcado, el ID de trazabilidad y los ítems del checklist que se pueden confirmar automáticamente.

Ejemplos:

```bash
# Todo interactivo (el script pregunta tipo, nombre, etc.)
./scripts/new-work.sh

# Tipo + número de issue (el nombre se deriva del título del issue)
./scripts/new-work.sh feature 42

# Tipo + issue + nombre personalizado
./scripts/new-work.sh devops 5 actualizar-plan-implementacion

# Solo número de issue (tipo y nombre se piden interactivamente)
./scripts/new-work.sh 42
```

Más información: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Uso de los scripts de sincronización

### scripts/sync-develop.sh

Sube cambios de una rama feature/hotfix/devops a `develop`. Actualiza el changelog, espera a que pasen las comprobaciones de CI en el PR, y fusiona hacia `develop` si no hay conflictos:

```bash
./scripts/sync-develop.sh [tipo] [nombre-descriptivo]
```

Ejemplos:

```bash
# Todo interactivo
./scripts/sync-develop.sh

# Tipo feature con nombre
./scripts/sync-develop.sh feature implement-client-getters

# Tipo devops con nombre
./scripts/sync-develop.sh devops add-changelog-generator
```

### scripts/sync-main.sh

Sincroniza `develop` hacia `main` mediante un PR de tipo release. Actualiza el changelog antes de crear el PR:

```bash
./scripts/sync-main.sh [nombre-descriptivo]
```

Ejemplo:

```bash
# Sincronizar release
./scripts/sync-main.sh sync-release-v1-0-0
```

### scripts/generate-changelog.sh

Genera y actualiza automáticamente `CHANGELOG.md` desde el historial de commits:

```bash
./scripts/generate-changelog.sh [modo] [archivo-salida]
```

Modos: `release` (desde el último tag hasta HEAD), `sync` (desde develop hasta main), `all` (historial completo).

Ejemplo:

```bash
# Changelog completo
./scripts/generate-changelog.sh all CHANGELOG.md
```

## Plantilla de mensajes de commit

El proyecto usa una plantilla de mensajes de commit almacenada en [`.gitmessage`](.gitmessage). Se activa con:

```bash
git config commit.template .gitmessage
```

La plantilla impone la convención:

```
<tipo>: <descripción corta> [(<ID_TRAZABILIDAD>)] [Closes #<NÚMERO_ISSUE>]
```

Donde:
- `<tipo>`: `feature`, `hotfix`, `devops`, `chore` o `release`
- `<descripción corta>`: modo imperativo, minúsculas, sin punto final
- `<ID_TRAZABILIDAD>`: `FEAT-NNN`, `T-NNN`, `HOTFIX-NNN`, `DEVOPS-NNN` o `AC-NNN`
- `<NÚMERO_ISSUE>`: número de issue de GitHub cerrado por este commit (opcional)

Ejemplos:

```
feature: implement Client getters and setters (FEAT-001) Closes #18
devops: add commit message template (DEVOPS-159) Closes #187
```

Todos los PR creados con [`scripts/new-work.sh`](scripts/new-work.sh) usan IDs de trazabilidad en sus títulos y cuerpos.

## Pull requests

Each PR must indicate its type in the pull request template:

- **`feature`**: implements a new feature.
- **`hotfix`**: one-off bug fix.
- **`devops`**: infrastructure, CI, scripts, documentation or configuration.
- **`release`**: synchronizes `develop` into `main`.

### PRs of type feature / hotfix / devops

1. Source branch is `feature/…`, `hotfix/…` or `devops/…`.
2. Target branch is `develop`.
3. Indicate the traceability ID of the issue closed by this PR (e.g. `Closes #123 — FEAT-001`).
4. List fulfilled acceptance criteria (`AC-001`, `AC-002`, …).
5. After review and CI passing, merge into `develop`.
6. **Delete the branch** after merge.
7. **Close the corresponding issue** (feature/task/hotfix) when all its acceptance criteria are completed.

### PRs of type release

1. Source branch is `release/…`.
2. Target branch is `main`.
3. No release pipeline: the PR only synchronizes `main` with `develop`.
4. After merge on `main`, create a version tag (e.g. `v1.0.0`).

## Compile the project

```bash
make build
```

The default build is in `build/` in `Debug` mode.

## Add unit tests

1. Create a file in `tests/unit/` (e.g. `tests/unit/test_foo.cpp`).
2. Use CppUTest (`#include "CppUTest/TestHarness.h"`, macros `TEST_GROUP` and `TEST`).
3. Add the file to the `unit_tests` executable in `tests/CMakeLists.txt`.
4. Run `make test-unit` or `ctest --test-dir build -L unit --output-on-failure`.

Requirements: no external dependencies, deterministic, no filesystem or network operations unless essential, one behavior per test.

## Add integration tests

1. Create a file in `tests/integration/`.
2. Register the executable in `tests/CMakeLists.txt` and add a test with `add_test(...)` and the `integration` label.
3. Run `make test-integration` or `ctest --test-dir build -L integration --output-on-failure`.

Requirements: independent, cleans up temporary resources, does not depend on execution order, does not modify production data.

## Run all checks

```bash
make build
make test
make valgrind
```

For sanitizers (AddressSanitizer + UndefinedBehaviorSanitizer):

```bash
make sanitize
```

## Basic code conventions

- Strict C++98: do not use `unique_ptr`, `shared_ptr`, lambdas, `auto`, `nullptr` or C++11 or later features.
- Clear names, small functions and simple responsibilities.
- RAII and explicit ownership; avoid unnecessary dynamic allocation and raw owning pointers.
- Compiler warnings active: `-Wall -Wextra -Werror -Wpedantic -std=c++98`.
- Consistent formatting (.clang-format).
- Use traceability IDs (`FEAT-…`, `T-…`, `HOTFIX-…`, `DEVOPS-…`, `AC-…`) in commit messages and PR descriptions.

## Pull request

- Describe the change and why it is necessary.
- Indicate the PR type (`feature`, `hotfix`, `devops` or `release`).
- Add or update tests covering the new behavior.
- List fulfilled acceptance criteria.
- Verify `make build`, `make test` and `make valgrind` locally.
- Make sure CI passes before requesting review.

---

# Guía de contribución

Documento práctico para incorporarse al proyecto. El proyecto está escrito en **C++98** y usa CMake, CTest, CppUTest, Valgrind y GitHub Actions (según el `AgentGuide.md`).

El trabajo de implementación se organiza según el [Plan de implementación](docs/implementation_plan.md), que define features (FEAT-…), tasks (T-…) y acceptance criteria (AC-…) con IDs de trazabilidad.

## Organización del trabajo: Features, Tasks y acceptance criteria

Todo el trabajo se organiza en **issues** con **IDs de trazabilidad** para poder referenciarlos desde commits, ramas y pull requests. El plan completo de trazabilidad está documentado en [docs/implementation_plan.md](docs/implementation_plan.md).

### Tipos de issue

| Tipo de issue | ID de ejemplo | Rama asociada | Descripción |
|---|---|---|---|
| Feature | `FEAT-001` | `feature/…` | Unidad de trabajo de alto nivel. Tiene acceptance criteria y puede desglosarse en tasks. |
| Task | `T-001` | `feature/…` (de su feature padre) | Unidad de trabajo menor. Es un subissue de una feature padre. |
| Hotfix | `HOTFIX-001` | `hotfix/…` | Arreglo puntual de un bug crítico. |
| Devops | `DEVOPS-001` | `devops/…` | Infraestructura, CI, scripts, documentación o configuración del repositorio. |

### IDs de trazabilidad

Cada issue debe llevar un ID de trazabilidad en su título o cuerpo:

- Feature: `FEAT-NNN`
- Task: `T-NNN`
- Hotfix: `HOTFIX-NNN`
- Devops: `DEVOPS-NNN`

Los **acceptance criteria** también llevan su propio ID de trazabilidad, por ejemplo `AC-001`, `AC-002`. Una feature se considera completa solo cuando todos sus acceptance criteria (y los de sus tasks) están cumplidos y validados.

### Crear una feature

1. Abrir una issue de tipo **Feature** usando la plantilla de GitHub.
2. Asignar un ID `FEAT-NNN` (ver los IDs de feature disponibles en [docs/implementation_plan.md](docs/implementation_plan.md)).
3. Definir los acceptance criteria (`AC-…`).
4. Si es necesario, desglosar la feature en tasks: abrir issues de tipo **Task** con ID `T-NNN`, indicando la feature padre (`FEAT-NNN`) y sus propios acceptance criteria.

### Crear un hotfix

1. Abrir una issue de tipo **Hotfix** usando la plantilla de GitHub.
2. Asignar un ID `HOTFIX-NNN`.
3. Describir el bug, su impacto y los acceptance criteria para darlo por resuelto.

### Crear un issue de devops

Para cambios de infraestructura, CI, scripts, documentación o configuración del repositorio, abrir una issue de tipo **Devops** con ID `DEVOPS-NNN`.

## Tipos de rama

| Prefijo | Propósito | Origen | Destino del PR |
|---|---|---|---|
| `feature/` | Implementar una feature | `develop` | `develop` |
| `hotfix/` | Arreglo puntual de un bug | `develop` | `develop` |
| `devops/` | Infraestructura, CI, documentación, repo | `develop` | `develop` |
| `release/` | Sincronizar `develop` hacia `main` | `develop` | `main` |

**Nota:** No existe un pipeline de releases. Un PR de tipo `release` solo sincroniza `main` con `develop`; tras el merge, crear una etiqueta de versión en `main`.

## Crear una rama

Siempre partir desde `develop` actualizado:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/descripcion-corta      # o hotfix/…, devops/…, release/…
```

Cuando termine:

```bash
git add -A
git commit -m "tipo: descripción breve (FEAT-001)"
git push origin feature/descripcion-corta
```

Luego abrir el pull request correspondiente (ver siguiente sección).

## Script helper usage (scripts/new-work.sh)

To create a branch in an assisted way, use the [`scripts/new-work.sh`](scripts/new-work.sh) script:

```bash
./scripts/new-work.sh [type] [issue-number] [descriptive-name]
```

All arguments are optional and can be given in any order. When executed, the first thing it asks is:

> Does this work correspond to a GitHub issue? [y/N]

- **If yes:** it asks for the issue number, fetches its title from GitHub, and uses it to build the branch name.
- **If no:** it interactively asks for the type (`feature`, `hotfix`, `devops`, `chore`, `release`), a descriptive name, and, if there are uncommitted changes, the commit message.

**Note:** This script does NOT create a Pull Request. It only creates the branch, commits changes, and pushes to origin. To create the PR, wait for CI, and merge towards `develop`, use [`scripts/sync-develop.sh`](scripts/sync-develop.sh).

Examples:

```bash
# Fully interactive (the script asks for type, name, etc.)
./scripts/new-work.sh

# Type + issue number (name is derived from the issue title)
./scripts/new-work.sh feature 42

# Type + issue + custom name
./scripts/new-work.sh devops 5 update-docs

# Only issue number (type and name are prompted interactively)
./scripts/new-work.sh 42
```

More info: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Commit message template

The project uses a commit message template stored in [`.gitmessage`](.gitmessage). It is activated via:

```bash
git config commit.template .gitmessage
```

The template enforces the convention:

```
<type>: <short description> [(<TRACEABILITY_ID>)] [Closes #<ISSUE_NUMBER>]
```

Where:
- `<type>`: `feature`, `hotfix`, `devops`, `chore` or `release`
- `<short description>`: imperative mood, lowercase, no period at the end
- `<TRACEABILITY_ID>`: `FEAT-NNN`, `T-NNN`, `HOTFIX-NNN`, `DEVOPS-NNN` or `AC-NNN`
- `<ISSUE_NUMBER>`: GitHub issue number closed by this commit (optional)

Examples:

```
feature: implement Client getters and setters (FEAT-001) Closes #18
devops: add commit message template (DEVOPS-159) Closes #187
```

All commits created with [`scripts/new-work.sh`](scripts/new-work.sh) use traceability IDs in their messages.

## Sync scripts usage

### scripts/sync-develop.sh

Push changes from a feature/hotfix/devops branch to `develop`. It updates the changelog, waits for CI checks to pass on the PR, and merges towards `develop` if there are no conflicts:

```bash
./scripts/sync-develop.sh [type] [descriptive-name]
```

Examples:

```bash
# Fully interactive
./scripts/sync-develop.sh

# Feature type with name
./scripts/sync-develop.sh feature implement-client-getters

# Devops type with name
./scripts/sync-develop.sh devops add-changelog-generator
```

### scripts/sync-main.sh

Synchronize `develop` into `main` via a release PR. It updates the changelog before creating the PR:

```bash
./scripts/sync-main.sh [descriptive-name]
```

Example:

```bash
# Sync release
./scripts/sync-main.sh sync-release-v1-0-0
```

### scripts/generate-changelog.sh

Automatically generate and update `CHANGELOG.md` from commit history:

```bash
./scripts/generate-changelog.sh [mode] [output-file]
```

Modes: `release` (from last tag to HEAD), `sync` (from develop to main), `all` (full history).

Example:

```bash
# Full changelog
./scripts/generate-changelog.sh all CHANGELOG.md
```

## Uso del script auxiliar (scripts/new-work.sh)

Para crear una rama y un Pull Request de forma asistida, usa el script [`scripts/new-work.sh`](scripts/new-work.sh):

```bash
./scripts/new-work.sh [tipo] [numero-issue] [nombre-descriptivo]
```

Todos los argumentos son opcionales y pueden ir en cualquier orden. Al ejecutarlo, lo primero que pregunta es:

> ¿Corresponde este trabajo a un issue de GitHub? [y/N]

- **Si sí:** pide el número de issue, obtiene su título de GitHub y lo usa para construir el nombre de la rama. El cuerpo del PR incluye `Closes #N` (para el issue y sus sub-issues), de modo que **GitHub los cierre automáticamente al hacer merge**.
- **Si no:** pide de forma interactiva el tipo (`feature`, `hotfix`, `devops`, `chore`, `release`), un nombre descriptivo y, si hay cambios sin commitear, el mensaje de commit.

El cuerpo del Pull Request sigue la [plantilla de PR de GitHub](.github/pull_request_template.md) y se rellena con los archivos modificados, el tipo de PR marcado, el ID de trazabilidad y los ítems del checklist que se pueden confirmar automáticamente.

Ejemplos:

```bash
# Todo interactivo (el script pregunta tipo, nombre, etc.)
./scripts/new-work.sh

# Tipo + número de issue (el nombre se deriva del título del issue)
./scripts/new-work.sh feature 42

# Tipo + issue + nombre personalizado
./scripts/new-work.sh devops 5 actualizar-plan-implementacion

# Solo número de issue (tipo y nombre se piden interactivamente)
./scripts/new-work.sh 42
```

Más información: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Uso de los scripts de sincronización

### scripts/sync-develop.sh

Sube cambios de una rama feature/hotfix/devops a `develop`. Actualiza el changelog, espera a que pasen las comprobaciones de CI en el PR, y fusiona hacia `develop` si no hay conflictos:

```bash
./scripts/sync-develop.sh [tipo] [nombre-descriptivo]
```

Ejemplos:

```bash
# Todo interactivo
./scripts/sync-develop.sh

# Tipo feature con nombre
./scripts/sync-develop.sh feature implement-client-getters

# Tipo devops con nombre
./scripts/sync-develop.sh devops add-changelog-generator
```

### scripts/sync-main.sh

Sincroniza `develop` hacia `main` mediante un PR de tipo release. Actualiza el changelog antes de crear el PR:

```bash
./scripts/sync-main.sh [nombre-descriptivo]
```

Ejemplo:

```bash
# Sincronizar release
./scripts/sync-main.sh sync-release-v1-0-0
```

### scripts/generate-changelog.sh

Genera y actualiza automáticamente `CHANGELOG.md` desde el historial de commits:

```bash
./scripts/generate-changelog.sh [modo] [archivo-salida]
```

Modos: `release` (desde el último tag hasta HEAD), `sync` (desde develop hasta main), `all` (historial completo).

Ejemplo:

```bash
# Changelog completo
./scripts/generate-changelog.sh all CHANGELOG.md
```

## Plantilla de mensajes de commit

El proyecto usa una plantilla de mensajes de commit almacenada en [`.gitmessage`](.gitmessage). Se activa con:

```bash
git config commit.template .gitmessage
```

La plantilla impone la convención:

```
<tipo>: <descripción corta> [(<ID_TRAZABILIDAD>)] [Closes #<NÚMERO_ISSUE>]
```

Donde:
- `<tipo>`: `feature`, `hotfix`, `devops`, `chore` o `release`
- `<descripción corta>`: modo imperativo, minúsculas, sin punto final
- `<ID_TRAZABILIDAD>`: `FEAT-NNN`, `T-NNN`, `HOTFIX-NNN`, `DEVOPS-NNN` o `AC-NNN`
- `<NÚMERO_ISSUE>`: número de issue de GitHub cerrado por este commit (opcional)

Ejemplos:

```
feature: implement Client getters and setters (FEAT-001) Closes #18
devops: add commit message template (DEVOPS-159) Closes #187
```

Todos los PR creados con [`scripts/new-work.sh`](scripts/new-work.sh) usan IDs de trazabilidad en sus títulos y cuerpos.

## Pull requests

Cada PR debe indicar su tipo en la plantilla de pull request:

- **`feature`**: implementa una feature nueva.
- **`hotfix`**: arreglo puntual de un bug.
- **`devops`**: infraestructura, CI, scripts, documentación o configuración.
- **`release`**: sincroniza `develop` hacia `main`.

### PRs de feature / hotfix / devops

1. La rama origen es `feature/…`, `hotfix/…` o `devops/…`.
2. La rama destino es `develop`.
3. Indicar el ID de trazabilidad del issue que cierra este PR (ej. `Closes #123 — FEAT-001`).
4. Listar los acceptance criteria cumplidos (`AC-001`, `AC-002`, …).
5. Tras la revisión y que la CI pase, fusionar hacia `develop`.
6. **Eliminar la rama** tras el merge.
7. **Cerrar el issue correspondiente** (feature/task/hotfix) cuando se completen todos sus acceptance criteria.

### PRs de release

1. La rama origen es `release/…`.
2. La rama destino es `main`.
3. No hay pipeline de releases: el PR solo sincroniza `main` con `develop`.
4. Tras el merge en `main`, crear una etiqueta de versión (ej. `v1.0.0`).

## Compilar el proyecto

```bash
make build
```

El build por defecto está en `build/` en modo `Debug`.

## Añadir pruebas unitarias

1. Crear un archivo en `tests/unit/` (por ejemplo, `tests/unit/test_foo.cpp`).
2. Usar CppUTest (`#include "CppUTest/TestHarness.h"`, macros `TEST_GROUP` y `TEST`).
3. Agregar el archivo al ejecutable `unit_tests` en `tests/CMakeLists.txt`.
4. Ejecutar `make test-unit` o `ctest --test-dir build -L unit --output-on-failure`.

Requisitos: sin dependencias externas, determinista, sin operaciones de sistema de archivos ni red a menos que sea esencial, un comportamiento por prueba.

## Añadir pruebas de integración

1. Crear un archivo en `tests/integration/`.
2. Registrar el ejecutable en `tests/CMakeLists.txt` y añadir una prueba con `add_test(...)` y la etiqueta `integration`.
3. Ejecutar `make test-integration` o `ctest --test-dir build -L integration --output-on-failure`.

Requisitos: independiente, limpia recursos temporales, sin depender del orden de ejecución, sin modificar datos de producción.

## Ejecutar todas las comprobaciones

```bash
make build
make test
make valgrind
```

Para sanitizadores (AddressSanitizer + UndefinedBehaviorSanitizer):

```bash
make sanitize
```

## Convenciones de código básicas

- C++98 estricto: no usar `unique_ptr`, `shared_ptr`, lambdas, `auto`, `nullptr` ni características de C++11 o posteriores.
- Nombres claros, funciones pequeñas y responsabilidades simples.
- RAII y propiedad explícita; evitar asignación dinámica innecesaria y punteros raw propietarios.
- Advertencias del compilador activas: `-Wall -Wextra -Werror -Wpedantic -std=c++98`.
- Formato coherente (.clang-format).
- Usar los IDs de trazabilidad (`FEAT-…`, `T-…`, `HOTFIX-…`, `DEVOPS-…`, `AC-…`) en los mensajes de commit y en las descripciones de PR.

## Pull request

- Describir el cambio y por qué es necesario.
- Indicar el tipo de PR (`feature`, `hotfix`, `devops` o `release`).
- Añadir o actualizar pruebas que cubran el nuevo comportamiento.
- Listar los acceptance criteria cumplidos.
- Verificar `make build`, `make test` y `make valgrind` localmente.
- Asegurarse de que CI pasa antes de solicitar revisión.
