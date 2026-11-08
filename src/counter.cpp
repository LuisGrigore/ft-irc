#include "counter.hpp"

Counter::Counter() : value_(new int(0)) {}

Counter::Counter(int initialValue) : value_(new int(initialValue)) {}

Counter::~Counter() {
    delete value_;
}

void Counter::increment() {
    (*value_)++;
}

void Counter::decrement() {
    (*value_)--;
}

void Counter::reset() {
    *value_ = 0;
}

int Counter::value() const {
    return *value_;
}
