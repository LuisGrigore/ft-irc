#ifndef NICKMANAGER_HPP
#define NICKMANAGER_HPP

class NickManager {
  private:
    std::set<std::string> nicks;

  public:
    NickManager();
    ~NickManager();

    /*
     * @brief Checks if a nickname is available
     * @param nick The nickname to check
     * @return true if the nickname is available, false otherwise
     */
    bool isAvailable(const std::string& nick);

    /*
     * @brief Reserves a nickname
     * @param nick The nickname to reserve
     * @return true if the nickname was reserved, false otherwise
     */
    bool reserve(const std::string& nick);
    /*
     * @brief Releases a nickname
     * @param nick The nickname to release
     */
    void release(const std::string& nick);
    /*
     * @brief Checks if a nickname is valid
     * @param nick The nickname to check
     * @return true if the nickname is valid, false otherwise
     */
    bool isValid(const std::string& nick);
};

#endif // NICKMANAGER_HPP