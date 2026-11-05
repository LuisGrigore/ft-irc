# Flags comunes para los ejecutables de prueba (proyecto, no de CppUTest).
set(TEST_WARNING_FLAGS ${PROJECT_WARNING_FLAGS})

set(TEST_COMPILE_SANITIZER_FLAGS)
set(TEST_LINK_SANITIZER_FLAGS)

if(ENABLE_SANITIZERS AND (CMAKE_CXX_COMPILER_ID MATCHES "^(GNU|Clang)$"))
    set(TEST_COMPILE_SANITIZER_FLAGS -fsanitize=address,undefined -fno-omit-frame-pointer)
    set(TEST_LINK_SANITIZER_FLAGS -fsanitize=address,undefined)
endif()

set(CPPUTEST_INCLUDE_DIRS
    ${cpputest_SOURCE_DIR}/include
    ${cpputest_SOURCE_DIR}/CppUTestExt/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../include
)

add_executable(unit_tests unit/test_counter.cpp test_main.cpp)
target_link_libraries(unit_tests PRIVATE counter CppUTestExt CppUTest)
target_include_directories(unit_tests PRIVATE ${CPPUTEST_INCLUDE_DIRS})
target_compile_options(unit_tests PRIVATE ${TEST_WARNING_FLAGS} ${TEST_COMPILE_SANITIZER_FLAGS})
if(TEST_LINK_SANITIZER_FLAGS)
    target_link_options(unit_tests PRIVATE ${TEST_LINK_SANITIZER_FLAGS})
endif()

add_executable(integration_tests integration/test_counter_integration.cpp test_main.cpp)
target_link_libraries(integration_tests PRIVATE counter CppUTestExt CppUTest)
target_include_directories(integration_tests PRIVATE ${CPPUTEST_INCLUDE_DIRS})
target_compile_options(integration_tests PRIVATE ${TEST_WARNING_FLAGS} ${TEST_COMPILE_SANITIZER_FLAGS})
if(TEST_LINK_SANITIZER_FLAGS)
    target_link_options(integration_tests PRIVATE ${TEST_LINK_SANITIZER_FLAGS})
endif()

add_test(NAME unit_tests COMMAND unit_tests)
add_test(NAME integration_tests COMMAND integration_tests)
set_tests_properties(unit_tests PROPERTIES LABELS "unit")
set_tests_properties(integration_tests PROPERTIES LABELS "integration")
