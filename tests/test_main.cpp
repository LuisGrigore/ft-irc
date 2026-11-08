#include "CppUTest/CommandLineTestRunner.h"

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), the macro is undefined to use the ordinary
 * `new` from the standard library. This file does not use `new`, but it is
 * undefined for consistency with test translation units.
 */
#undef new

int main(int argc, char** argv) {
    return CommandLineTestRunner::RunAllTests(argc, argv);
}
