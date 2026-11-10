#ifndef IRCSERVICE_HPP
#define IRCSERVICE_HPP

#include "./ClientManager.hpp"
#include "./ISocketService.hpp"
#include <string>

class IRCService : public ISocketService {
  private:
    ClientManager& clientManager;

  public:
    IRCService(ClientManager& clientManager);
    virtual ~IRCService();

    /**
     * @brief Handles a new client connection.
     * @param fd The file descriptor of the new client.
     */
    virtual void onConnect(int fd);

    /**
     * @brief Handles data received from a client.
     * @param fd The file descriptor of the client.
     * @param data The data received from the client.
     */
    virtual void onData(int fd, const std::string& data);

    /**
     * @brief Handles a client disconnection.
     * @param fd The file descriptor of the client.
     */
    virtual void onDisconnect(int fd);

    /**
     * @brief Performs a tick iteration, handling socket events and returning the result
     * @return TickResult containing the outputs and file descriptors to close
     */
    virtual TickResult tick();
};

#endif // IRCSERVICE_HPP