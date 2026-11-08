/*
 * Compatibilidad de CppUTest 3.8 con toolchains modernas.
 *
 * CppUTest 3.8 incluye un "kludge" para VC++ V6 que redefine va_copy como
 * `copy = original`. Esa asignación no compila con glibc moderno, donde
 * va_list es un array de un elemento. Como se compila el proyecto en modo
 * -std=c++98, la biblioteca C no define va_copy (es una característica de
 * C99), por lo que el kludge se activa y rompe SimpleString.cpp.
 *
 * Este encabezado se fuerza con la opción del compilador -include solo al
 * compilar las fuentes de CppUTest, para proveer una va_copy correcta y
 * desactivar el kludge roto. No afecta al código de producción ni a las
 * pruebas del proyecto.
 */
#ifndef CPPUTEST_COMPAT_H
#define CPPUTEST_COMPAT_H

#ifndef va_copy
#define va_copy(destination, source) __builtin_va_copy(destination, source)
#endif

#endif /* CPPUTEST_COMPAT_H */
