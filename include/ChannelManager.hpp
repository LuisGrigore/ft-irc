#ifndef CHANNELMANAGER_HPP
#define CHANNELMANAGER_HPP

#include "./Client.hpp"

class ChannelManager {
  public:
    /*
     * @brief Removes a client from all channels they are currently in
     * @param client The client to remove from all channels
     */
    void removeClientFromAllChannels(Client* client);
};

#endif // CHANNELMANAGER_HPP