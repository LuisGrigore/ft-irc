#ifndef BASE_EXCEPTION_HPP
#define BASE_EXCEPTION_HPP

#include <cstring>
#include <stdexcept>

class BaseException : public std::runtime_error {
  protected:
    const int errorCode;

    BaseException(const std::string& message, int errorCode)
        : std::runtime_error(message + ": " + std::strerror(errorCode)), errorCode(errorCode) {}

  public:
    template <typename BuilderType> class Builder {
      protected:
        std::string _message = "";
        int _errorCode = -1;

      public:
        BuilderType& message(const std::string& message) {
            this->_message = message;
            return static_cast<BuilderType&>(*this);
        };
        BuilderType& errorCode(int errorCode) {
            this->_errorCode = errorCode;
            return static_cast<BuilderType&>(*this);
        };
        BuilderType& cause(const std::exception& cause) {
            this->_message += "-> Caused by: " + std::string(cause.what());
            return static_cast<BuilderType&>(*this);
        };
    };

    int getErrorCode() const noexcept { return errorCode; }
};

#endif // BASE_EXCEPTION_HPP