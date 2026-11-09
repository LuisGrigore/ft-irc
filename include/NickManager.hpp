#ifndef NICKMANAGER_HPP
#define NICKMANAGER_HPP

#include <set>
#include <string>

class NickManager {
  private:
    std::set<std::string> nicks;

    static const std::string::size_type NICK_MAX_LENGTH = 30;

    static bool isLetter(char c);
    static bool isDigit(char c);
    static bool isSpecial(char c);

    static std::string normalize(const std::string& nick);

  public:
    NickManager();
    ~NickManager();

    /**
     * @brief Checks if a nickname is available
     * @param nick The nickname to check
     * @return true if the nickname is available, false otherwise
     */
    bool isAvailable(const std::string& nick) const;

    /**
     * @brief Reserves a nickname
     * @param nick The nickname to reserve
     * @return true if the nickname was reserved, false otherwise
     */
    bool reserve(const std::string& nick);

    /**
     * @brief Releases a nickname
     * @param nick The nickname to release
     */
    void release(const std::string& nick);

    /**
     * @brief Checks if a nickname is valid
     * @param nick The nickname to check
     * @return true if the nickname is valid, false otherwise
     */
    bool isValid(const std::string& nick) const;
};

#endif // NICKMANAGER_HPP