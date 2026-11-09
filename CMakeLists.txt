cmake_minimum_required(VERSION 3.11)
project(ft_irc CXX)

# -----------------------------------------------------------------------------
# C++ standard: C++98 is mandatory (AgentGuide.md, section 2).
#   - C++98 as required standard.
#   - No compiler extensions.
#   - No accidental use of C++11 or later.
# -----------------------------------------------------------------------------
set(CMAKE_CXX_STANDARD 98)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$")
    # -Wall -Wextra -Werror -std=c++98, as required by the project.
    # -Wpedantic is kept to detect compiler extensions.
    set(PROJECT_WARNING_FLAGS -Wall -Wextra -Werror -Wpedantic -std=c++98)
else()
    set(PROJECT_WARNING_FLAGS "")
endif()

option(ENABLE_SANITIZERS "Enable AddressSanitizer and UndefinedBehaviorSanitizer" OFF)

# -----------------------------------------------------------------------------
# Dependency: CppUTest 3.8 (latest version compatible with C++98; branch 4.x
# requires C++11). It is downloaded and compiled as part of the project using
# FetchContent so that no hidden system packages are required. A clean clone
# with network and cmake is enough to build and test.
#
# Intentional options to keep control of this build:
#   TESTS OFF: do not compile CppUTest's own tests.
#   CPPUTEST_FLAGS OFF: CppUTest does not inject global flags into our build.
#   C++11 OFF: CppUTest is compiled strictly in C++98.
#   MEMORY_LEAK_DETECTION OFF: Valgrind and the sanitizers are the project's
#         memory checking tools.
# -----------------------------------------------------------------------------
include(FetchContent)

# CppUTest 3.8 requires cmake_minimum_required(VERSION 2.8.7), whose compatibility
# was removed in CMake 4.x. At least policy 3.5 is requested to include it
# with this CMake.
if(NOT CMAKE_POLICY_VERSION_MINIMUM)
    set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "Minimum CMake policy version" FORCE)
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

# Avoid the broken va_copy kludge of CppUTest 3.8 on modern toolchains:
# force a correct definition before compiling its sources.
target_compile_options(CppUTest PRIVATE
    -include ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cpputest_compat.h)
target_compile_options(CppUTestExt PRIVATE
    -include ${CMAKE_CURRENT_SOURCE_DIR}/cmake/cpputest_compat.h)

# -----------------------------------------------------------------------------
# Production library
# -----------------------------------------------------------------------------
add_library(ft_irc STATIC src/counter.cpp src/Client.cpp src/ClientManager.cpp src/NickManager.cpp src/IRCService.cpp)
target_include_directories(ft_irc PUBLIC include)
target_compile_options(ft_irc PRIVATE ${PROJECT_WARNING_FLAGS})

if(ENABLE_SANITIZERS AND (CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$"))
    target_compile_options(ft_irc PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
    target_link_options(ft_irc PRIVATE -fsanitize=address,undefined)
endif()

# -----------------------------------------------------------------------------
# Tests (unit and integration)
# -----------------------------------------------------------------------------
include(CTest)
enable_testing()
add_subdirectory(tests)
