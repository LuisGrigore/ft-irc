#ifndef CLIENT_HPP
#define CLIENT_HPP

#include <string>

class Client {
  private:
    int fd;
    std::string nick;
    std::string username;
    std::string realname;
    std::string hostname;
    std::string inputBuffer;
    std::string outputBuffer;
    bool authenticated;
    bool registered;
    bool closing;

  public:
    Client(int fd);
    ~Client();

    // Getters
    int getFd() const;
    const std::string& getNick() const;
    const std::string& getUsername() const;
    const std::string& getRealname() const;
    const std::string& getHostname() const;
    const std::string& getInputBuffer() const;
    const std::string& getOutputBuffer() const;

    // Setters
    void setFd(int fd);
    void setNick(const std::string& nick);
    void setUsername(const std::string& username);
    void setRealname(const std::string& realname);
    void setHostname(const std::string& hostname);
    void setInputBuffer(const std::string& inputBuffer);
    void setOutputBuffer(const std::string& outputBuffer);
    void setAuthenticated(bool authenticated);
    void setRegistered(bool registered);

    // Predicates
    bool isAuthenticated() const;
    bool isRegistered() const;
    bool isClosing() const;
    void setClosing(bool closing);
};

#endif // CLIENT_HPP