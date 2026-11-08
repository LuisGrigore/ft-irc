#include "Client.hpp"

Client::Client(int fd)
    : fd(fd), nick(), username(), realname(), hostname(), authenticated(false), registered(false),
      closing(false) {}

Client::~Client() {}

// Getters

int Client::getFd() const { return fd; }

const std::string& Client::getNick() const { return nick; }

const std::string& Client::getUsername() const { return username; }

const std::string& Client::getRealname() const { return realname; }

const std::string& Client::getHostname() const { return hostname; }

// Setters

void Client::setFd(int fd) { this->fd = fd; }

void Client::setNick(const std::string& nick) { this->nick = nick; }

void Client::setUsername(const std::string& username) { this->username = username; }

void Client::setRealname(const std::string& realname) { this->realname = realname; }

void Client::setHostname(const std::string& hostname) { this->hostname = hostname; }

void Client::setAuthenticated(bool authenticated) { this->authenticated = authenticated; }

void Client::setRegistered(bool registered) { this->registered = registered; }

void Client::setClosing(bool closing) { this->closing = closing; }

// Predicates

bool Client::isAuthenticated() const { return authenticated; }

bool Client::isRegistered() const { return registered; }

bool Client::isClosing() const { return closing; }