#ifndef ISOCKETSERVICE_HPP
#define ISOCKETSERVICE_HPP

#include "./TickResult.hpp"

class ISocketService {
  public:
    virtual ~ISocketService() {};

    /**
     * @brief Handles a new client connection.
     * @param fd The file descriptor of the new client.
     */
    virtual void onConnect(int fd) = 0;

    /**
     * @brief Handles data received from a client.
     * @param fd The file descriptor of the client.
     * @param data The data received from the client.
     */
    virtual void onData(int fd, const std::string& data) = 0;

    /**
     * @brief Handles a client disconnection.
     * @param fd The file descriptor of the client.
     */
    virtual void onDisconnect(int fd) = 0;

    /**
     * @brief Performs a tick iteration, handling socket events and returning the result
     * @param consumedBytes A map of the consummed bytes by the fds <fd,consumedBytes>
     * @return TickResult containing the outputs and file descriptors to close
     */
    virtual TickResult tick(const std::map<int,int>& consumedBytes) = 0;
};

#endif // ISOCKETSERVICE_HPP