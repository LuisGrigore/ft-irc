#include "../include/NickManager.hpp"

NickManager::NickManager() : nicks() {}

NickManager::~NickManager() {}

bool NickManager::isAvailable(const std::string& nick) {
    return nicks.find(normalize(nick)) == nicks.end();
}

bool NickManager::reserve(const std::string& nick) {
    if (isValid(nick) && isAvailable(nick)) {
        nicks.insert(normalize(nick));
        return true;
    }
    return false;
}

void NickManager::release(const std::string& nick) { nicks.erase(normalize(nick)); }

std::string NickManager::normalize(const std::string& nick) {
    std::string result = nick;
    for (std::string::size_type i = 0; i < result.size(); ++i) {
        if (result[i] >= 'A' && result[i] <= 'Z')
            result[i] = static_cast<char>(result[i] + ('a' - 'A'));
    }
    return result;
}

// Validation logic based on RFC 2812

const std::string::size_type NickManager::NICK_MAX_LENGTH;

bool NickManager::isLetter(char c) { return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z'); }

bool NickManager::isDigit(char c) { return c >= '0' && c <= '9'; }

// RFC 2812 "special": [ ] \ ` _ ^ { | }
bool NickManager::isSpecial(char c) {
    return c == '[' || c == ']' || c == '\\' || c == '`' || c == '_' || c == '^' || c == '{' ||
           c == '|' || c == '}';
}

bool NickManager::isValid(const std::string& nick) {
    if (nick.empty() || nick.size() > NICK_MAX_LENGTH)
        return false;

    // First character: letter or special
    if (!isLetter(nick[0]) && !isSpecial(nick[0]))
        return false;

    // Remaining characters: letter, digit, special or '-'
    for (std::string::size_type i = 1; i < nick.size(); ++i) {
        char c = nick[i];
        if (!isLetter(c) && !isDigit(c) && !isSpecial(c) && c != '-')
            return false;
    }
    return true;
}