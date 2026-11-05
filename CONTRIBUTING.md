# Guia de contribuccion

Documento practico para incorporarse al proyecto. El proyecto esta escrito en
**C++98** y usa CMake, CTest, CppUTest, Valgrind y GitHub Actions (según el
`AgentGuide.md`).

## Empezar

1. Clonar el repositorio.
2. Ejecutar `make build` para configurar y compilar.
3. Ejecutar `make test` para correr todas las pruebas.

Un clon limpio debe ser suficiente para construir y probar el proyecto.

## Crear una rama de funcionalidad

El proyecto usa `main` (estable) y `develop` (integracion):

```bash
git checkout develop
git pull origin develop
git checkout -b feature/descripcion-corta
```

Cuando termine:

1. Suba la rama: `git push origin feature/descripcion-corta`.
2. Abra un pull request hacia `develop`.
3. Asegurese de que la CI pasa.
4. Revise los cambios y fusione en `develop`.
5. Elimine la rama de funcionalidad.

Lo mismo se aplica para correcciones (`fix/*`) y refactorizaciones
(`refactor/*`).

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
- Advertencias del compilador activas: `-Wall -Wextra -Wpedantic`.
- Formato coherente (.clang-format).

## Pull request

- Describa el cambio y por qué es necesario.
- Adicione o actualice pruebas que cubran el nuevo comportamiento.
- Verifique `make build`, `make test` y `make valgrind` localmente.
- Asegurese de que CI pasa antes de solicitar revision.
