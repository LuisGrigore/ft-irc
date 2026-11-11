#include "../include/ClientManager.hpp"

ClientManager::ClientManager() {}

ClientManager::~ClientManager() {
    for (std::map<int, Client*>::iterator it = clients.begin(); it != clients.end(); ++it) {
        delete it->second;
    }
    clients.clear();
}

void ClientManager::addClient(int fd) {
    if (clients.find(fd) == clients.end()) {
        clients[fd] = new Client(fd);
    }
}

void ClientManager::removeClient(int fd) {
    std::map<int, Client*>::iterator it = clients.find(fd);
    if (it != clients.end()) {
        delete it->second;
        clients.erase(it);
		dirtyClients.erase(fd);
    }
}

Client* ClientManager::findClient(int fd) {
    std::map<int, Client*>::iterator it = clients.find(fd);
    if (it != clients.end()) {
        return it->second;
    }
    return NULL;
}

Client* ClientManager::findClient(const std::string& nick) {
    for (std::map<int, Client*>::iterator it = clients.begin(); it != clients.end(); ++it) {
        if (it->second->getNick() == nick) {
            return it->second;
        }
    }
    return NULL;
}

std::vector<Client*> ClientManager::listClients() const {
    std::vector<Client*> clientList;
    for (std::map<int, Client*>::const_iterator it = clients.begin(); it != clients.end(); ++it) {
        clientList.push_back(it->second);
    }
    return clientList;
}

void ClientManager::setDirty(int fd, bool isDirty) {
    if (isDirty) {
        dirtyClients.insert(fd);
    } else {
        dirtyClients.erase(fd);
    }
}

const std::set<int> ClientManager::getDirtyClients() const { return dirtyClients; }

bool ClientManager::isDirty(int fd) const { return dirtyClients.find(fd) != dirtyClients.end(); }
