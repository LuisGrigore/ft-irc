# Guia de contribuccion

Documento practico para incorporarse al proyecto. El proyecto esta escrito en
**C++98** y usa CMake, CTest, CppUTest, Valgrind y GitHub Actions (según el
`AgentGuide.md`).

## Organiza del trabajo: Features, Tasks y acceptance criteria

Todo el trabajo se organiza en **issues** con **IDs de trazabilidad** para
poder referenciarlos desde commits, ramas y pull requests.

### Tipos de issue

| Tipo | ID de ejemplo | Rama asociada | Descripción |
|---|---|---|---|
| Feature | `FEAT-001` | `feature/…` | Unidad de trabajo de alto nivel. Tiene acceptance criteria y puede desglosarse en tasks. |
| Task | `T-001` | `feature/…` (de su feature padre) | Unidad de trabajo menor. Es un **subissue** de una feature padre. |
| Hotfix | `HOTFIX-001` | `hotfix/…` | Arreglo puntual de un bug crítico. |
| Devops | `DEVOPS-001` | `devops/…` | Infraestructura, CI, scripts, documentación o configuración del repositorio. |

### IDs de trazabilidad

Cada issue debe llevar un ID de trazabilidad en su título o cuerpo:

- Feature: `FEAT-NNN`
- Task: `T-NNN`
- Hotfix: `HOTFIX-NNN`
- Devops: `DEVOPS-NNN`

Las **acceptance criteria** (criterios de aceptación) también llevan su propio
ID para trazabilidad, por ejemplo `AC-001`, `AC-002`. Una feature se considera
completa solo cuando todas sus acceptance criteria (y las de sus tasks) están
cumplidas y validadas.

### Crear una feature

1. Abre una issue de tipo **Feature** usando la plantilla de GitHub.
2. Asigna un ID `FEAT-NNN`.
3. Define los acceptance criteria (`AC-…`).
4. Si es necesario, desglosa la feature en tasks: abre issues de tipo **Task**
   con ID `T-NNN`, indicando la feature padre (`FEAT-NNN`) y sus propios
   acceptance criteria.

### Crear un hotfix

1. Abre una issue de tipo **Hotfix** usando la plantilla de GitHub.
2. Asigna un ID `HOTFIX-NNN`.
3. Describe el bug, su impacto y los acceptance criteria para darlo por resuelto.

### Crear un issue de devops

Para cambios de infraestructura, CI, scripts, documentación o configuración del
repositorio, abre una issue de tipo **Devops** con ID `DEVOPS-NNN`.

## Tipos de rama

| Prefijo | Propósito | Origen | Destino del PR |
|---|---|---|---|
| `feature/` | Implementar una feature | `develop` | `develop` |
| `hotfix/` | Arreglo puntual de un bug | `develop` | `develop` |
| `devops/` | Infraestructura, CI, documentación, repo | `develop` | `develop` |
| `release/` | Sincronizar `develop` hacia `main` | `develop` | `main` |

**Nota:** No existe un pipeline de releases. Un PR de tipo `release` solo
sincroniza `main` con `develop`; tras el merge, crear una etiqueta de versión
en `main`.

## Crear una rama

Siempre parta desde `develop` actualizado:

```bash
git checkout develop
git pull origin develop
git checkout -b feature/descripcion-corta      # o hotfix/..., devops/..., release/...
```

Cuando termine:

```bash
git add -A
git commit -m "tipo: descripción breve (FEAT-001)"
git push origin feature/descripcion-corta
```

Luego abra el pull request correspondiente (ver sección siguiente).

## Pull requests

Cada PR debe indicar su tipo en la plantilla de pull request:

- **`feature`**: implementa una feature nueva.
- **`hotfix`**: arreglo puntual de un bug.
- **`devops`**: infraestructura, CI, scripts, documentación o configuración.
- **`release`**: sincroniza `develop` hacia `main`.

### PRs de feature / hotfix / devops

1. La rama origen es `feature/…`, `hotfix/…` o `devops/…`.
2. La rama destino es `develop`.
3. Indique el ID de trazabilidad del issue que cierra (ej. `Closes #123 — FEAT-001`).
4. Liste los acceptance criteria cumplidos (`AC-001`, `AC-002`, …).
5. Tras la revisión y que la CI pase, fusione hacia `develop`.
6. **Elimine la rama** tras el merge.
7. **Cierre el issue correspondiente** (feature/task/hotfix) cuando se completen
   todas sus acceptance criteria.

### PRs de release

1. La rama origen es `release/…`.
2. La rama destino es `main`.
3. No hay pipeline de releases: el PR solo sincroniza `main` con `develop`.
4. Tras el merge en `main`, cree una etiqueta de versión (ej. `v1.0.0`).

## Compilar el proyecto

```bash
make build
```

El build por defecto esta en `build/` en modo `Debug`.

## Anadir pruebas unitarias

1. Cree un archivo en `tests/unit/` (por ejemplo, `tests/unit/test_foo.cpp`).
2. Use CppUTest (`#include "CppUTest/TestHarness.h"`, macros `TEST_GROUP` y
   `TEST`).
3. Agregue el archivo al ejecutable `unit_tests` en `tests/CMakeLists.txt`.
4. Ejecute `make test-unit` o `ctest --test-dir build -L unit --output-on-failure`.

Requisitos: sin dependencias externas, determinista, sin operaciones de
sistema de archivos ni red a menos que sea esencial, un comportamiento por
prueba.

## Anadir pruebas de integracion

1. Cree un archivo en `tests/integration/`.
2. Registre el ejecutable en `tests/CMakeLists.txt` y anada una prueba con
   `add_test(...)` y la etiqueta `integration`.
3. Ejecute `make test-integration` o
   `ctest --test-dir build -L integration --output-on-failure`.

Requisitos: independiente, limpia recursos temporales, sin depender del orden
de ejecucion, sin modificar datos de produccion.

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

## Convenciones de codigo basicas

- C++98 estricto: no use `unique_ptr`, `shared_ptr`, lambdas, `auto`,
  `nullptr` ni características de C++11 o posteriores.
- Nombres claros, funciones pequenas y responsabilidades simples.
- RAII y propiedad explicita; evite asignacion dinamica innecesaria y punteros
  raw propietarios.
- Advertencias del compilador activas: `-Wall -Wextra -Werror -Wpedantic -std=c++98`.
- Formato coherente (.clang-format).
- Use los IDs de trazabilidad (`FEAT-…`, `T-…`, `HOTFIX-…`, `DEVOPS-…`,
  `AC-…`) en los mensajes de commit y en las descripciones de PR.

## Pull request

- Describa el cambio y por qué es necesario.
- Indique el tipo de PR (`feature`, `hotfix`, `devops` o `release`).
- Adicione o actualice pruebas que cubran el nuevo comportamiento.
- Liste los acceptance criteria cumplidos.
- Verifique `make build`, `make test` y `make valgrind` localmente.
- Asegurese de que CI pasa antes de solicitar revision.
