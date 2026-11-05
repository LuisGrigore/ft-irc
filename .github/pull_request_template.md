# Plantilla de Pull Request

## Tipo de PR
Marca con una `x` el tipo correspondiente:

- [ ] `feature` — implementa una feature nueva (rama `feature/`)
- [ ] `hotfix` — arreglo puntual de un bug (rama `hotfix/`)
- [ ] `devops` — infraestructura, CI, scripts, documentación o configuración del repositorio (rama `devops/`)
- [ ] `release` — sincroniza `develop` hacia `main` (rama `release/`)

## Rama origen y destino

- **Rama origen:** `feature/…`, `hotfix/…`, `devops/…` o `release/…`
- **Rama destino:** `develop` (para feature/hotfix/devops) o `main` (para release)

## Issue(s) relacionado(s)

Indica el ID de trazabilidad de la issue que cierra este PR:

- Feature: `FEAT-001`
- Task: `T-001`
- Hotfix: `HOTFIX-001`

> Ejemplo: `Closes #123 — FEAT-001`

## Acceptance criteria completadas

Lista los IDs de aceptación que se cumplen con este PR:

- [ ] `AC-001` — …
- [ ] `AC-002` — …

## Cambios realizados

Describe brevemente qué se modificó, añadió o eliminó.

## Lista de verificación antes de pedir revisión

- [ ] Se creó la rama desde `develop` (`git checkout develop && git pull && git checkout -b feature/…`)
- [ ] El código cumple C++98 (`-std=c++98`, sin `unique_ptr`, lambdas, `auto`, etc.)
- [ ] Se compiló con `-Wall -Wextra -Werror -Wpedantic -std=c++98`
- [ ] `make build` termina sin errores
- [ ] `make test` pasa (unit + integration)
- [ ] `make valgrind` pasa sin fugas ni errores
- [ ] `make sanitize` pasa (si aplica)
- [ ] Se actualizó la documentación si es necesario
- [ ] Se usaron los IDs de trazabilidad en commits y mensajes

## Instrucciones para el merge

- **Para PRs de tipo `feature`, `hotfix` o `devops`:** fusionar hacia `develop`, **eliminar la rama** tras el merge y **cerrar el issue correspondiente** (feature/task/hotfix) cuando se completen todas sus acceptance criteria.
- **Para PRs de tipo `release`:** fusionar `develop` hacia `main` (sincronización directa, no hay pipeline de releases). Tras el merge, crear una etiqueta de versión en `main`.
