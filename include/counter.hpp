#ifndef COUNTER_HPP
#define COUNTER_HPP

/*
 * Minimal example of a production module (C++98).
 *
 * Intentionally simple design to validate build and test infrastructure,
 * not to define the project's architecture.
 *
 * Non-obvious decision:
 *   - Copy is disabled (copy constructor and assignment operator declared but
 *     not defined) because the class owns dynamic memory (value_) and an
 *     implicit copy would cause double free.
 *   - value_ is allocated on the heap and freed in the destructor so that
 *     allocation/deallocation of dynamic memory can be exercised in tests.
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
     * C++98 does not have = delete. It is declared without definition to
     * prohibit copying. No implementation is provided on purpose.
     */
    Counter(const Counter&);
    Counter& operator=(const Counter&);
};

#endif /* COUNTER_HPP */
