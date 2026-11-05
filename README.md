# ft_irc

Proyecto de ejemplo en **C++98** inicializado segun el `AgentGuide.md` de este
repositorio. El objetivo es partir de una base limpia, sencilla y facil de
contribuir: estructura clara, compilacion en C++98 aplicada a nivel de build,
pruebas unitarias y de integracion, deteccion de fugas de memoria con Valgrind,
sanitizadores opcionales, analisis estatico mediante advertencias del compilador
y un pipeline ligero de integración continua con GitHub Actions.

## Estructura del repositorio

```text
.
├── .github/workflows/ci.yml   # Pipeline de integracion continua
├── include/                   # Cabeceras publicas
├── src/                       # Codigo de produccion
├── tests/
│   ├── CMakeLists.txt
│   ├── unit/                  # Pruebas unitarias (etiqueta "unit")
│   └── integration/           # Pruebas de integracion (etiqueta "integration")
├── build/                     # Generado por la compilacion (no se commitea)
├── CMakeLists.txt             # Build system principal
├── Makefile                   # Comandos de desarrollo
├── .gitignore
├── .clang-format
├── README.md
├── CONTRIBUTING.md
└── AgentGuide.md
```

## Requisitos y dependencias

- CMake 3.11 o superior.
- Compilador C++ compatible con C++98 (GCC o Clang).
- GNU Make.
- Valgrind (para comprobacion de memoria).
- CppUTest 3.8: se descarga y compila automaticamente como parte del proyecto
  mediante CMake `FetchContent` (no hay que instalarlo a mano).

## Instrucciones de compilacion

Desde la raiz del repositorio:

```bash
make build
```

Esto configura CMake en el directorio `build/` (`CMAKE_BUILD_TYPE=Debug`) y
compila la biblioteca de produccion y los ejecutables de prueba. El estandar
C++98 se fuerza con:

```cmake
set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
```

## Instrucciones de pruebas

Todas las pruebas se ejecutan mediante CTest:

```bash
# Todas las pruebas
make test

# Solo pruebas unitarias
make test-unit

# Solo pruebas de integracion
make test-integration
```

Equivalente con ctest directamente:

```bash
ctest --test-dir build --output-on-failure
ctest --test-dir build -L unit --output-on-failure
ctest --test-dir build -L integration --output-on-failure
```

Las pruebas devuelven un codigo de salida distinto de cero si fallan.

## Valgrind

Valgrind es la herramienta principal de comprobacion de memoria. Se ejecuta
con comprobacion completa de fugas y trata las fugas `definite` e `indirect`
como errores:

```bash
make valgrind
```

Equivalente:

```bash
valgrind \
  --leak-check=full \
  --show-leak-kinds=all \
  --errors-for-leak-kinds=definite,indirect \
  --error-exitcode=1 \
  ./build/tests/unit_tests
```

## Sanitizadores (opcional)

Compila y ejecuta las pruebas con AddressSanitizer + UndefinedBehaviorSanitizer
en un directorio de build separado (`build-asan/`), sin activarlos en las
compilaciones de produccion por defecto:

```bash
make sanitize
```

Equivalente:

```bash
cmake -S . -B build-asan -DCMAKE_BUILD_TYPE=Debug -DENABLE_SANITIZERS=ON
cmake --build build-asan
ctest --test-dir build-asan --output-on-failure
```

## Limpiar

```bash
make clean
```

Elimina los directorios `build/` y `build-asan/` con todos los artefactos
generados.

## Flujo de trabajo con Git

El repositorio sigue una estrategia sencilla basada en ramas:

```text
main
  |
  └── develop
        |
        ├── feature/feature-name
        ├── fix/bug-description
        └── refactor/refactor-description
```

1. `main`: siempre estable. Solo recibe cambios de `develop` mediante pull
   request con CI verde.
2. `develop`: rama de integracion. Recibe las funcionalidades terminadas.
3. Ramas `feature/*`, `fix/*`, `refactor/*`: una por tarea, creadas desde
   `develop`.

```bash
git checkout develop
git pull origin develop
git checkout -b feature/mi-feature
# ... trabajar, commitear, subir ...
git push origin feature/mi-feature
# Crear pull request hacia develop, revisar y fusionar.
```

Cuando una version este lista, se abre un pull request de `develop` a `main`,
se fusiona tras pasar la CI y se crea una etiqueta de version.

Se recomienda proteger `main` (y `develop`) en GitHub: exigir pull requests,
exigir comprobaciones de CI aprobadas, bloquear pushes directos y bloquear
pushes forzados. Estas opciones no se configuran automaticamente desde el
repositorio; requieren configuracion manual en GitHub.

## Licencia

CppUTest (dependencia de pruebas) se descarga bajo su propia licencia (BSD-like,
ver repositorio de CppUTest). El resto del proyecto es de ejemplo sin licencia
asignada.
