#ifndef CLIENTMANAGER_HPP
#define CLIENTMANAGER_HPP

#include <map>
#include <vector>

#include "./Client.hpp"

class ClientManager {
  private:
    std::map<int, Client*> clients;

  public:
    ClientManager();
    ~ClientManager();

    /*
     * @brief Finds a client by its file descriptor.
     * @param fd The file descriptor of the client to find.
     * @return A pointer to the Client object if found, nullptr otherwise.
     */
    Client* findClient(int fd);
    /*
     * @brief Finds a client by its nickname.
     * @param nick The nickname of the client to find.
     * @return A pointer to the Client object if found, nullptr otherwise.
     */
    Client* findClient(const std::string& nick);
    /*
     * @brief Creates a new client and adds it to the manager.
     * @param fd The file descriptor of the new client.
     */
    void addClient(int fd);
    /*
     * @brief Removes a client from the manager by its file descriptor.
     * @param fd The file descriptor of the client to remove.
     */
    void removeClient(int fd);
    /*
     * @brief Retrieves a vector of all clients managed by the ClientManager.
     * @return A vector containing pointers to all Client objects.
     */
    std::vector<Client*> listClients() const;
};

#endif // CLIENTMANAGER_HPP