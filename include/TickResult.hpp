#ifndef TICKRESULT_HPP
#define TICKRESULT_HPP

#include <string>
#include <vector>

/**
 * @brief Represents the result of a tick iteration comming from a ISocketService implementation
 * instance
 */
struct TickResult {
    /**
     * @brief Represents an output to be sent to a file descriptor
     */
    struct Output {
        int fd;
        std::string data;

        Output();

        Output(int fd, const std::string& data);
    };

    /**
     * @brief Represents the outputs to be sent to each file descriptor in this tick
     */
    std::vector<Output> outputs;

    /**
     * @brief Represents the file descriptors to be closed in this tick
     */
    std::vector<int> toClose;

    TickResult();

    TickResult(const std::vector<Output>& outputs, const std::vector<int>& toClose);
};

#endif // TICKRESULT_HPP