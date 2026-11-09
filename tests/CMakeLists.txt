# Common flags for test executables (project, not CppUTest).
set(TEST_WARNING_FLAGS ${PROJECT_WARNING_FLAGS})

set(TEST_COMPILE_SANITIZER_FLAGS)
set(TEST_LINK_SANITIZER_FLAGS)

if(ENABLE_SANITIZERS AND (CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$"))
    set(TEST_COMPILE_SANITIZER_FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer)
    set(TEST_LINK_SANITIZER_FLAGS -fsanitize=address,undefined)
endif()

# CppUTest headers (external dependency) are marked as system headers:
# -Werror does not apply to their own warnings, only to project code.
# The project's production include is not SYSTEM.
set(PROJECT_INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/../include)

add_executable(unit_tests unit/test_IRCService.cpp unit/test_Client.cpp unit/test_ClientManager.cpp unit/test_NickManager.cpp unit/test_counter.cpp test_main.cpp)
target_link_libraries(unit_tests PRIVATE ft_irc CppUTestExt CppUTest)
target_include_directories(unit_tests PRIVATE ${PROJECT_INCLUDE_DIRS})
target_compile_options(unit_tests PRIVATE ${TEST_WARNING_FLAGS} ${TEST_COMPILE_SANITIZER_FLAGS})
if(TEST_LINK_SANITIZER_FLAGS)
    target_link_options(unit_tests PRIVATE ${TEST_LINK_SANITIZER_FLAGS})
endif()

add_executable(integration_tests integration/test_counter_integration.cpp test_main.cpp)
target_link_libraries(integration_tests PRIVATE ft_irc CppUTestExt CppUTest)
target_include_directories(integration_tests PRIVATE ${PROJECT_INCLUDE_DIRS})
target_compile_options(integration_tests PRIVATE ${TEST_WARNING_FLAGS} ${TEST_COMPILE_SANITIZER_FLAGS})
if(TEST_LINK_SANITIZER_FLAGS)
    target_link_options(integration_tests PRIVATE ${TEST_LINK_SANITIZER_FLAGS})
endif()

# CppUTest headers as system headers:
# -isystem suppresses their warnings under -Werror, keeping -Werror strict
# for project code. set_source_files_properties only affects compilation,
# never linking (avoiding passing -isystem as linker input file).
set_source_files_properties(
	unit/test_IRCService.cpp
    unit/test_Client.cpp
	unit/test_ClientManager.cpp
	unit/test_NickManager.cpp
	unit/test_counter.cpp
    integration/test_counter_integration.cpp
    test_main.cpp
    PROPERTIES
    COMPILE_FLAGS "-isystem ${cpputest_SOURCE_DIR}/include -isystem ${cpputest_SOURCE_DIR}/CppUTestExt/include"
)

add_test(NAME unit_tests COMMAND unit_tests)
add_test(NAME integration_tests COMMAND integration_tests)
set_tests_properties(unit_tests PROPERTIES LABELS "unit")
set_tests_properties(integration_tests PROPERTIES LABELS "integration")
