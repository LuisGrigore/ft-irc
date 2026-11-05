#ifndef COUNTER_HPP
#define COUNTER_HPP

/*
 * Ejemplo minimo de modulo de produccion (C++98).
 *
 * Diseno intencionalmente sencillo para validar la infraestructura de
 * construccion y pruebas, no para definir la arquitectura del proyecto.
 *
 * Decision no obvia:
 *   - La copia esta deshabilitada (constructora de copia y operador de
 *     asignacion declarados pero no definidos) porque la clase posee memoria
 *     dinamica (value_) y una copia implicita provocaria doble liberacion.
 *   - value_ se reserva en el monticulo y se libera en el destructor para
 *     poder ejercitar reserva/liberacion de memoria dinamica en las pruebas.
 */

class Counter {
public:
    Counter();
    explicit Counter(int initialValue);
    ~Counter();

    void increment();
    void decrement();
    void reset();
    int value() const;

private:
    int* value_;

    /*
     * C++98 no tiene = delete. Se declara sin definir para prohibir la copia.
     * No se proporciona implementacion a proposito.
     */
    Counter(const Counter&);
    Counter& operator=(const Counter&);
};

#endif /* COUNTER_HPP */
