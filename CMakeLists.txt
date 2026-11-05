cmake_minimum_required(VERSION 3.11)
project(ft_irc CXX)

# -----------------------------------------------------------------------------
# Estandar de C++: C++98 es obligatorio (AgentGuide.md, seccion 2).
#   - C++98 como estandar requerido.
#   - Sin extensiones del compilador.
#   - Sin uso accidental de C++11 o posterior.
# -----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$")
    # -Wall -Wextra -Werror -std=c++98, tal como exige el proyecto.
    # -Wpedantic se mantiene para detectar extensiones del compilador.
    set(PROJECT_WARNING_FLAGS -Wall -Wextra -Werror -Wpedantic -std=c++98)
else()
    set(PROJECT_WARNING_FLAGS "")
endif()

option(ENABLE_SANITIZERS "Habilitar AddressSanitizer y UndefinedBehaviorSanitizer" OFF)

# -----------------------------------------------------------------------------
# Dependencia: CppUTest 3.8 (ultima version compatible con C++98; la rama 4.x
# requiere C++11). Se descarga y compila como parte del proyecto con
# FetchContent para no exigir paquetes de sistema ocultos. Una clonacion
# limpia mas red y cmake es suficiente para construir y probar.
#
# Opciones intencionales para mantener el control de esta compilacion:
#   TESTS OFF: no se compilan los tests propios de CppUTest.
#   CPPUTEST_FLAGS OFF: CppUTest no inyecta flags globales en nuestra build.
#   C++11 OFF: CppUTest se compila estrictamente en C++98.
#   MEMORY_LEAK_DETECTION OFF: Valgrind y los sanitizadores son las
#         herramientas de comprobacion de memoria del proyecto.
# -----------------------------------------------------------------------------
include(FetchContent)

# CppUTest 3.8 requiere cmake_minimum_required(VERSION 2.8.7), cuya compatibilidad
# fue eliminada en CMake 4.x. Se solicita al menos la política 3.5 para poder
# incluirlo con este CMake.
if(NOT CMAKE_POLICY_VERSION_MINIMUM)
    set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "Versión mínima de políticas de CMake" FORCE)
endif()

set(TESTS OFF CACHE BOOL "" FORCE)
set(CPPUTEST_FLAGS OFF CACHE BOOL "" FORCE)
set(C++11 OFF CACHE BOOL "" FORCE)
set(MEMORY_LEAK_DETECTION OFF CACHE BOOL "" FORCE)
set(STD_CPP ON CACHE BOOL "" FORCE)
set(STD_C ON CACHE BOOL "" FORCE)
set(EXTENSIONS ON CACHE BOOL "" FORCE)
FetchContent_Declare(
    cpputest
    GIT_REPOSITORY https://github.com/cpputest/cpputest.git
    GIT_TAG v3.8
    GIT_SHALLOW ON
)
FetchContent_MakeAvailable(cpputest)

# Evitar el kludge roto de va_copy de CppUTest 3.8 en toolchains modernas:
# forzar una definición correcta antes de compilar sus fuentes.
target_compile_options(CppUTest PRIVATE
    -include ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cpputest_compat.h)
target_compile_options(CppUTestExt PRIVATE
    -include ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cpputest_compat.h)

# -----------------------------------------------------------------------------
# Biblioteca de produccion
# -----------------------------------------------------------------------------
add_library(counter STATIC src/counter.cpp)
target_include_directories(counter PUBLIC include)
target_compile_options(counter PRIVATE ${PROJECT_WARNING_FLAGS})

if(ENABLE_SANITIZERS AND (CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$"))
    target_compile_options(counter PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(counter PRIVATE -fsanitize=address,undefined)
endif()

# -----------------------------------------------------------------------------
# Pruebas (unitarias y de integracion)
# -----------------------------------------------------------------------------
include(CTest)
enable_testing()
add_subdirectory(tests)
