#ifndef NICKMANAGER_HPP
#define NICKMANAGER_HPP

class NickManager {
  private:
    std::set<std::string> nicks;

  public:
    NickManager();
    ~NickManager();

    bool isAvailable(const std::string& nick);
    bool reserve(const std::string& nick);
    void release(const std::string& nick);
    bool isValid(const std::string& nick);
};

#endif // NICKMANAGER_HPP