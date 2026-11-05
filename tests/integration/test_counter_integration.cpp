#include "CppUTest/TestHarness.h"
#include "counter.hpp"

#include <cstdio>
#include <cstdlib>
#include <cstring>

/*
 * CppUTest fuerza `#define new new(__FILE__, __LINE__)` a través de
 * MemoryLeakDetectorNewMacros.h (incluido desde TestHarness.h). Como el
 * proyecto compila con detección de fugas de CppUTest desactivada
 * (MEMORY_LEAK_DETECTION OFF), nadie provee el operador `new` de posicionamiento
 * que requiere esa macro. Se anula aquí, solo en las unidades de traducción de
 * las pruebas, para usar el `new` ordinario de la biblioteca estándar.
 */
#undef new

TEST_GROUP(CounterIntegration) {};

/*
 * Prueba de integracion: valida la interaccion de dos instancias de Counter
 * y la persistencia del resultado en un archivo temporal.
 *
 * Requisitos de la seccion 5.2 del AgentGuide.md:
 *   - Independiente de otras pruebas.
 *   - Limpia el recurso temporal que crea.
 *   - No depende del orden de ejecucion.
 *   - No modifica datos de produccion.
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
