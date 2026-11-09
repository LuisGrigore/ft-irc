#include "../include/TickResult.hpp"

TickResult::Output::Output() : fd(-1), data("") {}

TickResult::Output::Output(int fd, const std::string& data) : fd(fd), data(data) {}

TickResult::TickResult() {}

TickResult::TickResult(const std::vector<Output>& outputs, const std::vector<int>& toClose)
    : outputs(outputs), toClose(toClose) {}
