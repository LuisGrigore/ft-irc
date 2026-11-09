#ifndef CLIENTMANAGER_HPP
#define CLIENTMANAGER_HPP

#include <map>
#include <set>
#include <vector>

#include "./Client.hpp"

class ClientManager {
  private:
    std::map<int, Client*> clients;
    /**
     * @brief A set of file descriptors for clients that have been modified and need to be
     * processed.
     */
    std::set<int> dirtyClients;

  public:
    ClientManager();
    ~ClientManager();

    /**
     * @brief Finds a client by its file descriptor.
     * @param fd The file descriptor of the client to find.
     * @return A pointer to the Client object if found, nullptr otherwise.
     */
    Client* findClient(int fd);

    /**
     * @brief Finds a client by its nickname.
     * @param nick The nickname of the client to find.
     * @return A pointer to the Client object if found, nullptr otherwise.
     */
    Client* findClient(const std::string& nick);

    /**
     * @brief Creates a new client and adds it to the manager.
     * @param fd The file descriptor of the new client.
     */
    void addClient(int fd);

    /**
     * @brief Removes a client from the manager by its file descriptor.
     * @param fd The file descriptor of the client to remove.
     */
    void removeClient(int fd);

    /**
     * @brief Retrieves a vector of all clients managed by the ClientManager.
     * @return A vector containing pointers to all Client objects.
     */
    std::vector<Client*> listClients() const;

    /**
     * @brief Sets the dirty status of a client.
     * @param fd The file descriptor of the client to mark as dirty.
     * @param isDirty The dirty status to set, true means that the client is dirty and needs to be
     * processed, false otherwise.
     */
    void setDirty(int fd, bool isDirty);

    /**
     * @brief Retrieves the set of file descriptors for clients that have been modified and need to
     * be processed.
     * @return A set containing the file descriptors of dirty clients.
     */
    std::set<int> getDirtyClients() const;

    /**
     * @brief Checks if a client has been modified and needs to be processed.
     * @param fd The file descriptor of the client to check.
     * @return true if the client is dirty, false otherwise.
     */
    bool isDirty(int fd) const;
};

#endif // CLIENTMANAGER_HPP