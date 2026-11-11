#ifndef TICKRESULT_HPP
#define TICKRESULT_HPP

#include <string>
#include <set>
#include <map>

/**
 * @brief Represents the result of a tick iteration comming from a ISocketService implementation
 * instance
 */
struct TickResult {

    /**
     * @brief Represents the outputs to be sent to each file descriptor in this tick <fd, output>
     */
    std::map<int,std::string> outputs;

    /**
     * @brief Represents the file descriptors to be closed in this tick
     */
    std::set<int> toClose;

    TickResult();

    TickResult(const std::map<int,std::string>& outputs, const std::set<int>& toClose);
};

#endif // TICKRESULT_HPP