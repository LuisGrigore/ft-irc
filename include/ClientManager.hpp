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

    Client* findClient(int fd);
    Client* findClient(const std::string& nick);
    void addClient(Client* client);
    void removeClient(int fd);
    std::vector<Client*> listClients() const;
};

#endif // CLIENTMANAGER_HPP