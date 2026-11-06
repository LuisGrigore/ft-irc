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

    int getFd() const;
    const std::string& getNick() const;
    void setNick(const std::string& nick);
    const std::string& getUsername() const;
    void setUsername(const std::string& username);
    const std::string& getRealname() const;
    void setRealname(const std::string& realname);
    const std::string& getHostname() const;
    void setHostname(const std::string& hostname);
    const std::string& getInputBuffer() const;
    void setInputBuffer(const std::string& inputBuffer);
    const std::string& getOutputBuffer() const;
    void setOutputBuffer(const std::string& outputBuffer);
    bool is_authenticated() const;
    void set_authenticated(bool authenticated);
    bool is_registered() const;
    void set_registered(bool registered);
    bool is_closing() const;
    void set_closing(bool closing);
};

#endif // CLIENT_HPP