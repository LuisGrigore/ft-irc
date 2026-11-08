#include "Client.hpp"
#include "CppUTest/TestHarness.h"

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), no one provides the placement `new` operator
 * required by that macro. It is undefined here, only in test translation
 * units, to use the ordinary `new` from the standard library.
 */
#undef new

TEST_GROUP(Client){};

TEST(Client, GetFdReturnsCorrectValue_AC_001) {
    Client client(5);
    CHECK_EQUAL(5, client.getFd());
}

TEST(Client, GetNickReturnsCorrectValue_AC_001) {
    Client client(5);
    client.setNick("testuser");
    STRCMP_EQUAL("testuser", client.getNick().c_str());
}

TEST(Client, GetUsernameReturnsCorrectValue_AC_001) {
    Client client(5);
    client.setUsername("testuser");
    STRCMP_EQUAL("testuser", client.getUsername().c_str());
}

TEST(Client, GetRealnameReturnsCorrectValue_AC_001) {
    Client client(5);
    client.setRealname("Test User");
    STRCMP_EQUAL("Test User", client.getRealname().c_str());
}

TEST(Client, GetHostnameReturnsCorrectValue_AC_001) {
    Client client(5);
    client.setHostname("localhost");
    STRCMP_EQUAL("localhost", client.getHostname().c_str());
}

TEST(Client, NewClientIsNotAuthenticatedNorRegisteredNorClosing) {
    Client client(5);
    CHECK_FALSE(client.isAuthenticated());
    CHECK_FALSE(client.isRegistered());
    CHECK_FALSE(client.isClosing());
}

TEST(Client, SettersUpdateStateFlags_AC_001) {
    Client client(5);
    client.setAuthenticated(true);
    client.setRegistered(true);
    client.setClosing(true);
    CHECK_TRUE(client.isAuthenticated());
    CHECK_TRUE(client.isRegistered());
    CHECK_TRUE(client.isClosing());
}

TEST(Client, SetFdUpdatesValue_AC_001) {
    Client client(5);
    client.setFd(9);
    CHECK_EQUAL(9, client.getFd());
}

TEST(Client, SettersCanResetStateFlagsToFalse) {
    Client client(5);
    client.setAuthenticated(true);
    client.setRegistered(true);
    client.setClosing(true);

    client.setAuthenticated(false);
    client.setRegistered(false);
    client.setClosing(false);

    CHECK_FALSE(client.isAuthenticated());
    CHECK_FALSE(client.isRegistered());
    CHECK_FALSE(client.isClosing());
}