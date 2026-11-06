#include "CppUTest/TestHarness.h"
#include "counter.hpp"

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), no one provides the placement `new` operator
 * required by that macro. It is undefined here, only in test translation
 * units, to use the ordinary `new` from the standard library.
 */
#undef new

TEST_GROUP(Counter) {};

TEST(Counter, InitialValueIsZero) {
    Counter counter;
    CHECK_EQUAL(0, counter.value());
}

TEST(Counter, InitialValueIsProvidedValue) {
    Counter counter(42);
    CHECK_EQUAL(42, counter.value());
}

TEST(Counter, IncrementIncreasesValue) {
    Counter counter;
    counter.increment();
    CHECK_EQUAL(1, counter.value());
}

TEST(Counter, DecrementDecreasesValue) {
    Counter counter(5);
    counter.decrement();
    CHECK_EQUAL(4, counter.value());
}

TEST(Counter, ResetSetsValueToZero) {
    Counter counter(7);
    counter.reset();
    CHECK_EQUAL(0, counter.value());
}

/*
 * Exercises dynamic memory allocation and deallocation on the heap, as
 * required by section 13 of AgentGuide.md.
 */
TEST(Counter, DynamicMemoryAllocationAndDeallocation) {
    Counter* counter = new Counter(10);
    CHECK_EQUAL(10, counter->value());
    counter->increment();
    CHECK_EQUAL(11, counter->value());
    delete counter;
}
