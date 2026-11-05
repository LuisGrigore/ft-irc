#include "CppUTest/TestHarness.h"
#include "counter.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), no one provides the placement `new` operator
 * required by that macro. It is undefined here, only in test translation
 * units, to use the ordinary `new` from the standard library.
 */
#undef new

TEST_GROUP(CounterIntegration) {};

/*
 * Integration test: validates interaction of two Counter instances and
 * persistence of the result in a temporary file.
 *
 * Requirements from section 5.2 of AgentGuide.md:
 *   - Independent of other tests.
 *   - Cleans up the temporary resource it creates.
 *   - Does not depend on execution order.
 *   - Does not modify production data.
 */
TEST(CounterIntegration, TwoCountersInteractingAndFilePersistence) {
    Counter counterA(3);
    Counter counterB(7);

    counterA.increment();
    counterB.decrement();

    CHECK_EQUAL(4, counterA.value());
    CHECK_EQUAL(6, counterB.value());

    const int total = counterA.value() + counterB.value();

    const char* tempFile = "/tmp/counter_integration_test.tmp";

    FILE* file = std::fopen(tempFile, "w");
    CHECK(file != NULL);
    if (file != NULL) {
        char buffer[16];
        std::sprintf(buffer, "%d", total);
        std::fwrite(buffer, 1, std::strlen(buffer), file);
        std::fclose(file);
    }

    file = std::fopen(tempFile, "r");
    CHECK(file != NULL);

    char buffer[16] = {0};
    if (file != NULL) {
        std::fread(buffer, 1, sizeof(buffer) - 1, file);
        std::fclose(file);
    }

    CHECK_EQUAL(total, std::atoi(buffer));

    std::remove(tempFile);
}
