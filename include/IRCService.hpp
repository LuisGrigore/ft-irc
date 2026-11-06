#ifndef IRCSERVICE_HPP
#define IRCSERVICE_HPP

#include <string>
#include <set>

#include "./TickResult.hpp"
#include "./ClientManager.hpp"
#include "./NickManager.hpp"
#include "./ChannelManager.hpp"

class IRCService : public ISocketService {
private:
	/**
	 * @brief The password for the IRC server
	 */
	std::string password;
	/**
	 * @brief A set of client file descriptors that have pending updates
	 */
	std::set<int> dirtyClients;
	/**
	 * @brief A set of client file descriptors that have pending output
	 */
	std::set<int> outputDirty;
	/**
	 * @brief A set of client file descriptors that have requested to close
	 */
	std::set<int> closeRequests;
	/**
	 * @brief A pointer to the client manager
	 */
	ClientManager* clientManager;
	/**
	 * @brief A pointer to the nickname manager
	 */
	NickManager* nickManager;
	/**
	 * @brief A pointer to the channel manager
	 */
	ChannelManager* channelManager;
public:
    IRCService();
    ~IRCService();

    virtual void onConnect(int fd) override;
	virtual void onData(int fd, const std::string& data) override;
    virtual void onDisconnect(int fd) override;
	virtual TickResult tick() override;

};

#endif // IRCSERVICE_HPP