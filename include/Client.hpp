#ifndef CLIENT_HPP
#define CLIENT_HPP

#include <string>

class Client {
  private:
    class ClientBuffer {
      private:
        std::string buffer;

      public:
        ClientBuffer();
        ~ClientBuffer();
        void push(const std::string& data);
        void push(char data);
        void push(const char* data);

        std::string peek(size_t length) const;
        void consume(size_t length);

        bool empty() const;
        size_t size() const;
        void clear();
    };

    int fd;
    std::string nick;
    std::string username;
    std::string realname;
    std::string hostname;
    bool authenticated;
    bool registered;
    bool closing;

    ClientBuffer inputBuffer;
    ClientBuffer outputBuffer;

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
    void setClosing(bool closing);

    // Predicates
    bool isAuthenticated() const;
    bool isRegistered() const;
    bool isClosing() const;
    bool isInputBufferEmpty() const;
    bool isOutputBufferEmpty() const;

    // IO Buffer methods
    /**
     * @brief Appends data to the end of the input buffer of the client.
     * @param data The data to be appended to the input buffer.
     */
    void pushInput(const std::string& data);

    /**
     * @brief Appends data to the end of the input buffer of the client.
     * @param data The data to be appended to the input buffer.
     */
    void pushInput(char data);

    /**
     * @brief Appends data to the end of the input buffer of the client.
     * @param data The data to be appended to the input buffer.
     */
    void pushInput(const char* data);

    /**
     * @brief Appends data to the end of the output buffer of the client.
     * @param data The data to be appended to the output buffer.
     */
    void pushOutput(const std::string& data);

    /**
     * @brief Appends data to the end of the output buffer of the client.
     * @param data The data to be appended to the output buffer.
     */
    void pushOutput(char data);

    /**
     * @brief Appends data to the end of the output buffer of the client.
     * @param data The data to be appended to the output buffer.
     */
    void pushOutput(const char* data);

    /**
     * @brief Retrieves the next line from the input buffer of the client consuming it.
     * @param line The string to store the retrieved line.
     * @return true if a line was successfully retrieved, false if there are no more complete lines.
     */
    bool getNextInputLine(std::string& line);

    /**
     * @brief Retrieves a specified number of characters from the output buffer of the client
     * without consuming them.
     * @param length The number of characters to retrieve.
     * @return The retrieved string, empty if the buffer is empty.
     */
    std::string peekOutput(size_t length) const;

    /**
     * @brief Consumes a specified number of characters from the output buffer of the client.
     * @param length The number of characters to consume.
     */
    void consumeOutput(size_t length);
};

#endif // CLIENT_HPP