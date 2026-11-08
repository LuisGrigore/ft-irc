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

    // Setters
    void setFd(int fd);
    void setNick(const std::string& nick);
    void setUsername(const std::string& username);
    void setRealname(const std::string& realname);
    void setHostname(const std::string& hostname);
    void setAuthenticated(bool authenticated);
    void setRegistered(bool registered);

    // Predicates
    bool isAuthenticated() const;
    bool isRegistered() const;
    bool isClosing() const;
    void setClosing(bool closing);
};

#endif // CLIENT_HPP