#ifndef IRCSERVICE_HPP
#define IRCSERVICE_HPP

#include "./ClientManager.hpp"
#include <string>

class IRCService {
  private:
    ClientManager& clientManager;

  public:
    IRCService(ClientManager& clientManager);
    ~IRCService();

    /**
     * @brief Handles a new client connection.
     * @param fd The file descriptor of the new client.
     */
    void onConnect(int fd);

    /**
     * @brief Handles data received from a client.
     * @param fd The file descriptor of the client.
     * @param data The data received from the client.
     */
    void onData(int fd, const std::string& data);

    /**
     * @brief Handles a client disconnection.
     * @param fd The file descriptor of the client.
     */
    void onDisconnect(int fd);
};

#endif // IRCSERVICE_HPP