#ifndef ISOCKETSERVICE_HPP
#define ISOCKETSERVICE_HPP

#include <string>

#include "./TickResult.hpp"

class ISocketService {
public:
	/**
	 * @brief Called when a client connects to the server
	 * @param fd The file descriptor of the connected client
	 */
	virtual void onConnect(int fd) = 0;
	/**
	 * @brief Called when data is received from a client
	 * @param fd The file descriptor of the client
	 * @param data The received data
	 */
	virtual void onData(int fd, const std::string& data) = 0;
	/**
	 * @brief Called when a client disconnects from the server
	 * @param fd The file descriptor of the disconnected client
	 */
	virtual void onDisconnect(int fd) = 0;
	/**
	 * @brief Called to update the service state
	 * @return The result of the update
	 */
	virtual TickResult tick() = 0;
};

#endif // ISOCKETSERVICE_HPP