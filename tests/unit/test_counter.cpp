#include "CppUTest/TestHarness.h"
#include "counter.hpp"

/*
 * CppUTest fuerza `#define new new(__FILE__, __LINE__)` a través de
 * MemoryLeakDetectorNewMacros.h (incluido desde TestHarness.h). Como el
 * proyecto compila con detección de fugas de CppUTest desactivada
 * (MEMORY_LEAK_DETECTION OFF), nadie provee el operador `new` de posicionamiento
 * que requiere esa macro. Se anula aquí, solo en las unidades de traducción de
 * las pruebas, para usar el `new` ordinario de la biblioteca estándar.
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
 * Ejercita reserva y liberacion de memoria dinamica en el monticulo, tal
 * como pide la seccion 13 del AgentGuide.md.
 */
TEST(Counter, DynamicMemoryAllocationAndDeallocation) {
    Counter* counter = new Counter(10);
    CHECK_EQUAL(10, counter->value());
    counter->increment();
    CHECK_EQUAL(11, counter->value());
    delete counter;
}
