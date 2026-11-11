#include "../include/TickResult.hpp"

TickResult::TickResult() {}

TickResult::TickResult(const std::map<int, std::string>& outputs, const std::set<int>& toClose)
    : outputs(outputs), toClose(toClose) {}
