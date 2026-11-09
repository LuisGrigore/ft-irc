#include "../include/IRCService.hpp"

IRCService::IRCService(ClientManager& clientManager) : clientManager(clientManager) {}

IRCService::~IRCService() {}

void IRCService::onConnect(int fd) { clientManager.addClient(fd); }

void IRCService::onData(int fd, const std::string& data) {
    if (data.empty())
        return;

    Client* client = clientManager.findClient(fd);
    if (client != NULL) {
        client->pushInput(data);
        clientManager.setDirty(fd, true);
    }
}

void IRCService::onDisconnect(int fd) {
    Client* client = clientManager.findClient(fd);
    if (client != NULL)
        clientManager.removeClient(fd);
}