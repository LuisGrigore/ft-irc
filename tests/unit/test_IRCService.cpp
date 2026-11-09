#include "CppUTest/TestHarness.h"
#include "IRCService.hpp"

#include <set>
#include <string>
#include <vector>

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), no one provides the placement `new` operator
 * required by that macro. It is undefined here, only in test translation
 * units, to use the ordinary `new` from the standard library.
 */
#undef new

TEST_GROUP(IRCService) {
    ClientManager manager;
    IRCService* service;

    void setup() { service = new IRCService(manager); }

    void teardown() { delete service; }
};

// On Connect

TEST(IRCService, OnConnectAddsClientToManager_AC_003) {
    service->onConnect(5);

    CHECK_TRUE(manager.findClient(5) != NULL);
}

TEST(IRCService, OnConnectCreatesClientWithGivenFd_AC_003) {
    service->onConnect(12);

    CHECK_EQUAL(12, manager.findClient(12)->getFd());
}

TEST(IRCService, OnConnectCreatesClientWithDefaultState_AC_003) {
    service->onConnect(5);

    Client* client = manager.findClient(5);
    CHECK_FALSE(client->isAuthenticated());
    CHECK_FALSE(client->isRegistered());
    CHECK_FALSE(client->isClosing());
    CHECK_TRUE(client->isInputBufferEmpty());
    CHECK_TRUE(client->isOutputBufferEmpty());
}

TEST(IRCService, OnConnectWithDifferentFdsCreatesDistinctClients_AC_003) {
    service->onConnect(5);
    service->onConnect(6);

    CHECK_EQUAL(2, (int)manager.listClients().size());
    CHECK_TRUE(manager.findClient(5) != manager.findClient(6));
}

TEST(IRCService, OnConnectKeepsPreviouslyConnectedClients_AC_003) {
    service->onConnect(5);
    Client* first = manager.findClient(5);
    first->setNick("alice");
    first->setAuthenticated(true);

    service->onConnect(6);

    POINTERS_EQUAL(first, manager.findClient(5));
    STRCMP_EQUAL("alice", manager.findClient(5)->getNick().c_str());
    CHECK_TRUE(manager.findClient(5)->isAuthenticated());
}

TEST(IRCService, OnConnectDoesNotMarkClientAsDirty_AC_003) {
    service->onConnect(5);

    CHECK_FALSE(manager.isDirty(5));
    CHECK_TRUE(manager.getDirtyClients().empty());
}

// On Data

TEST(IRCService, OnDataWithUnknownFdDoesNothing_AC_003) {
    service->onData(99, "NICK alice\r\n");

    CHECK_TRUE(manager.findClient(99) == NULL);
    CHECK_TRUE(manager.listClients().empty());
    CHECK_TRUE(manager.getDirtyClients().empty());
}

TEST(IRCService, OnDataWithUnknownFdDoesNotAffectExistingClients_AC_003) {
    service->onConnect(5);

    service->onData(99, "NICK alice\r\n");

    CHECK_TRUE(manager.findClient(5)->isInputBufferEmpty());
    CHECK_FALSE(manager.isDirty(5));
    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(IRCService, OnDataStoresDataInClientInputBuffer_AC_003) {
    service->onConnect(5);

    service->onData(5, "NICK alice\r\n");

    CHECK_FALSE(manager.findClient(5)->isInputBufferEmpty());
}

TEST(IRCService, OnDataMarksClientAsDirty_AC_003) {
    service->onConnect(5);

    service->onData(5, "NICK alice\r\n");

    CHECK_TRUE(manager.isDirty(5));
    CHECK_EQUAL(1, (int)manager.getDirtyClients().count(5));
}

TEST(IRCService, OnDataWithEmptyStringKeepsInputBufferEmpty_AC_003) {
    service->onConnect(5);

    service->onData(5, "");

    CHECK_TRUE(manager.findClient(5)->isInputBufferEmpty());
}

TEST(IRCService, OnDataWithEmptyStringDoesNotMarkClientAsDirty_AC_003) {
    service->onConnect(5);

    service->onData(5, "");

    CHECK_FALSE(manager.isDirty(5));
    CHECK_TRUE(manager.getDirtyClients().empty());
}

TEST(IRCService, OnDataCalledMultipleTimesKeepsClientDirtyOnce_AC_003) {
    service->onConnect(5);

    service->onData(5, "NICK ali");
    service->onData(5, "ce\r\n");
    service->onData(5, "USER alice 0 * :Alice\r\n");

    CHECK_FALSE(manager.findClient(5)->isInputBufferEmpty());
    CHECK_TRUE(manager.isDirty(5));
    CHECK_EQUAL(1, (int)manager.getDirtyClients().size());
}

TEST(IRCService, OnDataOnlyAffectsGivenClient_AC_003) {
    service->onConnect(5);
    service->onConnect(6);

    service->onData(5, "NICK alice\r\n");

    CHECK_FALSE(manager.findClient(5)->isInputBufferEmpty());
    CHECK_TRUE(manager.isDirty(5));
    CHECK_TRUE(manager.findClient(6)->isInputBufferEmpty());
    CHECK_FALSE(manager.isDirty(6));
}

TEST(IRCService, OnDataFromSeveralClientsMarksEachOneAsDirty_AC_003) {
    service->onConnect(5);
    service->onConnect(6);
    service->onConnect(7);

    service->onData(5, "NICK alice\r\n");
    service->onData(7, "NICK carol\r\n");

    std::set<int> dirty = manager.getDirtyClients();
    CHECK_EQUAL(2, (int)dirty.size());
    CHECK_EQUAL(1, (int)dirty.count(5));
    CHECK_EQUAL(0, (int)dirty.count(6));
    CHECK_EQUAL(1, (int)dirty.count(7));
}

TEST(IRCService, OnDataDoesNotChangeAuthenticationOrRegistrationState_AC_003) {
    service->onConnect(5);

    service->onData(5, "PASS secret\r\n");

    Client* client = manager.findClient(5);
    CHECK_FALSE(client->isAuthenticated());
    CHECK_FALSE(client->isRegistered());
    CHECK_FALSE(client->isClosing());
}

TEST(IRCService, OnDataDoesNotRemoveOrAddClients_AC_003) {
    service->onConnect(5);
    service->onConnect(6);

    service->onData(5, "NICK alice\r\n");

    CHECK_EQUAL(2, (int)manager.listClients().size());
    CHECK_TRUE(manager.findClient(5) != NULL);
    CHECK_TRUE(manager.findClient(6) != NULL);
}

// On Disconnect

TEST(IRCService, OnDisconnectMakesClientNotFindableByFd_AC_003) {
    service->onConnect(5);

    service->onDisconnect(5);

    CHECK_TRUE(manager.findClient(5) == NULL);
}

TEST(IRCService, OnDisconnectMakesClientNotFindableByNick_AC_003) {
    service->onConnect(5);
    manager.findClient(5)->setNick("testuser");

    service->onDisconnect(5);

    CHECK_TRUE(manager.findClient(std::string("testuser")) == NULL);
}

TEST(IRCService, OnDisconnectDecreasesNumberOfManagedClients_AC_003) {
    service->onConnect(5);
    service->onConnect(6);

    service->onDisconnect(5);

    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(IRCService, OnDisconnectDoesNotAffectOtherClients_AC_003) {
    service->onConnect(5);
    service->onConnect(6);
    service->onConnect(7);
    Client* second = manager.findClient(6);
    Client* third = manager.findClient(7);

    service->onDisconnect(5);

    POINTERS_EQUAL(second, manager.findClient(6));
    POINTERS_EQUAL(third, manager.findClient(7));
}

TEST(IRCService, OnDisconnectWithUnknownFdDoesNothing_AC_003) {
    service->onConnect(5);

    service->onDisconnect(99);

    CHECK_TRUE(manager.findClient(5) != NULL);
    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(IRCService, OnDisconnectOnEmptyManagerDoesNothing_AC_003) {
    service->onDisconnect(5);

    CHECK_TRUE(manager.listClients().empty());
}

TEST(IRCService, OnDisconnectTwiceDoesNothingTheSecondTime_AC_003) {
    service->onConnect(5);
    service->onConnect(6);

    service->onDisconnect(5);
    service->onDisconnect(5);

    CHECK_TRUE(manager.findClient(5) == NULL);
    CHECK_TRUE(manager.findClient(6) != NULL);
    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(IRCService, OnDisconnectRemovesClientFromDirtyClients_AC_003) {
    service->onConnect(5);
    service->onData(5, "NICK alice\r\n");

    service->onDisconnect(5);

    CHECK_FALSE(manager.isDirty(5));
    CHECK_TRUE(manager.getDirtyClients().empty());
}

TEST(IRCService, OnDisconnectKeepsOtherDirtyClients_AC_003) {
    service->onConnect(5);
    service->onConnect(6);
    service->onData(5, "NICK alice\r\n");
    service->onData(6, "NICK bob\r\n");

    service->onDisconnect(5);

    CHECK_FALSE(manager.isDirty(5));
    CHECK_TRUE(manager.isDirty(6));
    CHECK_EQUAL(1, (int)manager.getDirtyClients().size());
}

TEST(IRCService, ClientCanReconnectWithSameFdAfterDisconnect_AC_003) {
    service->onConnect(5);
    manager.findClient(5)->setNick("testuser");
    service->onData(5, "NICK testuser\r\n");
    service->onDisconnect(5);

    service->onConnect(5);

    Client* client = manager.findClient(5);
    CHECK_TRUE(client != NULL);
    CHECK_EQUAL(5, client->getFd());
    CHECK_TRUE(client->getNick().empty());
    CHECK_TRUE(client->isInputBufferEmpty());
    CHECK_FALSE(manager.isDirty(5));
}