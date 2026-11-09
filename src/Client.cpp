#include "../include/Client.hpp"

Client::Client(int fd)
    : fd(fd), nick(), username(), realname(), hostname(), authenticated(false), registered(false),
      closing(false), inputBuffer(), outputBuffer() {}

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

bool Client::isInputBufferEmpty() const { return inputBuffer.empty(); }

bool Client::isOutputBufferEmpty() const { return outputBuffer.empty(); }

// ClientBuffer class

Client::ClientBuffer::ClientBuffer() : buffer() {}
Client::ClientBuffer::~ClientBuffer() {}

// ClientBuffer push methods

void Client::ClientBuffer::push(const std::string& data) { buffer += data; }

void Client::ClientBuffer::push(char data) { buffer += data; }

void Client::ClientBuffer::push(const char* data) { buffer += data; }

// ClientBuffer access methods

std::string Client::ClientBuffer::peek(size_t length) const { return buffer.substr(0, length); }

void Client::ClientBuffer::consume(size_t length) { buffer.erase(0, length); }

// ClientBuffer predicates

bool Client::ClientBuffer::empty() const { return buffer.empty(); }

size_t Client::ClientBuffer::size() const { return buffer.size(); }

void Client::ClientBuffer::clear() { buffer.clear(); }

// Client input buffer methods

void Client::pushInput(const std::string& data) { inputBuffer.push(data); }

void Client::pushInput(char data) { inputBuffer.push(data); }

void Client::pushInput(const char* data) { inputBuffer.push(data); }

bool Client::getNextInputLine(std::string& line) {
    size_t pos = inputBuffer.peek(inputBuffer.size()).find("\r\n");
    if (pos == std::string::npos) {
        return false; // No complete line available
    }
    line = inputBuffer.peek(pos);
    inputBuffer.consume(pos + 2); // Consume the line and the end of line characters
    return true;
}

// Client output buffer methods

void Client::pushOutput(const std::string& data) { outputBuffer.push(data); }

void Client::pushOutput(char data) { outputBuffer.push(data); }

void Client::pushOutput(const char* data) { outputBuffer.push(data); }

std::string Client::peekOutput(size_t length) const { return outputBuffer.peek(length); }

void Client::consumeOutput(size_t length) { outputBuffer.consume(length); }
