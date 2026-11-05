#include "CppUTest/CommandLineTestRunner.h"

/*
 * CppUTest fuerza `#define new new(__FILE__, __LINE__)` a través de
 * MemoryLeakDetectorNewMacros.h (incluido desde TestHarness.h). Como el
 * proyecto compila con detección de fugas de CppUTest desactivada
 * (MEMORY_LEAK_DETECTION OFF), se anula la macro para usar el `new` ordinario
 * de la biblioteca estándar. Este archivo no usa `new`, pero se anula por
 * coherencia con las unidades de traducción de las pruebas.
 */
#undef new

int main(int argc, char** argv) {
    return CommandLineTestRunner::RunAllTests(argc, argv);
}
