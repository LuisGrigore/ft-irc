#include "ClientManager.hpp"
#include "CppUTest/TestHarness.h"

#include <algorithm>
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

TEST_GROUP(ClientManager){};

namespace {

    bool containsClient(const std::vector<Client*>& clients, Client* target) {
        return std::find(clients.begin(), clients.end(), target) != clients.end();
    }

} // namespace

// Find Client By Fd

TEST(ClientManager, FindClientByFdReturnsNullWhenManagerIsEmpty_AC_003) {
    ClientManager manager;

    CHECK_TRUE(manager.findClient(5) == NULL);
}

TEST(ClientManager, FindClientByFdReturnsClientWithMatchingFd_AC_003) {
    ClientManager manager;

    manager.addClient(5);

    Client* client = manager.findClient(5);
    CHECK_TRUE(client != NULL);
    CHECK_EQUAL(5, client->getFd());
}

TEST(ClientManager, FindClientByFdReturnsNullWhenFdDoesNotExist_AC_003) {
    ClientManager manager;

    manager.addClient(5);

    CHECK_TRUE(manager.findClient(99) == NULL);
}

TEST(ClientManager, FindClientByFdReturnsCorrectClientAmongMany_AC_003) {
    ClientManager manager;

    manager.addClient(5);
    manager.addClient(6);
    manager.addClient(7);

    Client* client = manager.findClient(6);
    CHECK_TRUE(client != NULL);
    CHECK_EQUAL(6, client->getFd());
}

TEST(ClientManager, FindClientByFdReturnsSamePointerOnRepeatedCalls_AC_003) {
    ClientManager manager;

    manager.addClient(5);

    POINTERS_EQUAL(manager.findClient(5), manager.findClient(5));
}

// Find Client By Nick

TEST(ClientManager, FindClientByNickReturnsNullWhenManagerIsEmpty_AC_003) {
    ClientManager manager;

    CHECK_TRUE(manager.findClient(std::string("testuser")) == NULL);
}

TEST(ClientManager, FindClientByNickReturnsClientWithMatchingNick_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    Client* added = manager.findClient(5);
    added->setNick("testuser");

    Client* found = manager.findClient(std::string("testuser"));

    CHECK_TRUE(found != NULL);
    POINTERS_EQUAL(added, found);
    CHECK_EQUAL(5, found->getFd());
}

TEST(ClientManager, FindClientByNickReturnsNullWhenNickDoesNotExist_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.findClient(5)->setNick("testuser");

    CHECK_TRUE(manager.findClient(std::string("unknown")) == NULL);
}

TEST(ClientManager, FindClientByNickReturnsCorrectClientAmongMany_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);
    manager.addClient(7);
    manager.findClient(5)->setNick("alice");
    manager.findClient(6)->setNick("bob");
    manager.findClient(7)->setNick("carol");

    Client* found = manager.findClient(std::string("bob"));

    CHECK_TRUE(found != NULL);
    CHECK_EQUAL(6, found->getFd());
}

TEST(ClientManager, FindClientByNickIsCaseSensitive_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.findClient(5)->setNick("testuser");

    CHECK_TRUE(manager.findClient(std::string("TestUser")) == NULL);
}

TEST(ClientManager, FindClientByNickReflectsNickChanges_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    Client* client = manager.findClient(5);

    client->setNick("oldnick");
    client->setNick("newnick");

    CHECK_TRUE(manager.findClient(std::string("oldnick")) == NULL);
    POINTERS_EQUAL(client, manager.findClient(std::string("newnick")));
}

TEST(ClientManager, FindClientByNickAndByFdReturnSameClient_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.findClient(5)->setNick("testuser");

    POINTERS_EQUAL(manager.findClient(5), manager.findClient(std::string("testuser")));
}

// Add Client

TEST(ClientManager, AddClientMakesClientFindableByFd_AC_003) {
    ClientManager manager;

    manager.addClient(5);

    CHECK_TRUE(manager.findClient(5) != NULL);
}

TEST(ClientManager, AddClientCreatesClientWithGivenFd_AC_003) {
    ClientManager manager;

    manager.addClient(12);

    CHECK_EQUAL(12, manager.findClient(12)->getFd());
}

TEST(ClientManager, AddClientCreatesClientWithDefaultState_AC_003) {
    ClientManager manager;

    manager.addClient(5);

    Client* client = manager.findClient(5);
    CHECK_FALSE(client->isAuthenticated());
    CHECK_FALSE(client->isRegistered());
    CHECK_FALSE(client->isClosing());
    CHECK_TRUE(client->isInputBufferEmpty());
    CHECK_TRUE(client->isOutputBufferEmpty());
}

TEST(ClientManager, AddClientIncreasesNumberOfManagedClients_AC_003) {
    ClientManager manager;

    manager.addClient(5);
    CHECK_EQUAL(1, (int)manager.listClients().size());

    manager.addClient(6);
    CHECK_EQUAL(2, (int)manager.listClients().size());
}

TEST(ClientManager, AddClientKeepsPreviouslyAddedClients_AC_003) {
    ClientManager manager;

    manager.addClient(5);
    Client* first = manager.findClient(5);
    manager.addClient(6);

    POINTERS_EQUAL(first, manager.findClient(5));
    CHECK_TRUE(manager.findClient(6) != NULL);
}

TEST(ClientManager, AddClientCreatesDistinctObjectsForDifferentFds_AC_003) {
    ClientManager manager;

    manager.addClient(5);
    manager.addClient(6);

    CHECK_TRUE(manager.findClient(5) != manager.findClient(6));
}

TEST(ClientManager, AddClientDoesNotShareStateBetweenClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);

    manager.findClient(5)->setNick("alice");
    manager.findClient(5)->setAuthenticated(true);

    CHECK_TRUE(manager.findClient(6)->getNick().empty());
    CHECK_FALSE(manager.findClient(6)->isAuthenticated());
}

// Remove Client

TEST(ClientManager, RemoveClientMakesClientNotFindableByFd_AC_003) {
    ClientManager manager;
    manager.addClient(5);

    manager.removeClient(5);

    CHECK_TRUE(manager.findClient(5) == NULL);
}

TEST(ClientManager, RemoveClientMakesClientNotFindableByNick_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.findClient(5)->setNick("testuser");

    manager.removeClient(5);

    CHECK_TRUE(manager.findClient(std::string("testuser")) == NULL);
}

TEST(ClientManager, RemoveClientDecreasesNumberOfManagedClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);

    manager.removeClient(5);

    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(ClientManager, RemoveClientDoesNotAffectOtherClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);
    manager.addClient(7);
    Client* second = manager.findClient(6);
    Client* third = manager.findClient(7);

    manager.removeClient(5);

    POINTERS_EQUAL(second, manager.findClient(6));
    POINTERS_EQUAL(third, manager.findClient(7));
}

TEST(ClientManager, RemoveClientWithUnknownFdDoesNothing_AC_003) {
    ClientManager manager;
    manager.addClient(5);

    manager.removeClient(99);

    CHECK_TRUE(manager.findClient(5) != NULL);
    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(ClientManager, RemoveClientOnEmptyManagerDoesNothing_AC_003) {
    ClientManager manager;

    manager.removeClient(5);

    CHECK_TRUE(manager.listClients().empty());
}

TEST(ClientManager, RemoveClientTwiceDoesNothingTheSecondTime_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);

    manager.removeClient(5);
    manager.removeClient(5);

    CHECK_TRUE(manager.findClient(5) == NULL);
    CHECK_TRUE(manager.findClient(6) != NULL);
    CHECK_EQUAL(1, (int)manager.listClients().size());
}

TEST(ClientManager, ClientCanBeAddedAgainAfterBeingRemoved_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.findClient(5)->setNick("testuser");
    manager.removeClient(5);

    manager.addClient(5);

    Client* client = manager.findClient(5);
    CHECK_TRUE(client != NULL);
    CHECK_EQUAL(5, client->getFd());
    CHECK_TRUE(client->getNick().empty());
}

// List Clients

TEST(ClientManager, ListClientsReturnsEmptyVectorWhenManagerIsEmpty_AC_003) {
    ClientManager manager;

    CHECK_TRUE(manager.listClients().empty());
}

TEST(ClientManager, ListClientsReturnsSingleClientAfterOneAdd_AC_003) {
    ClientManager manager;
    manager.addClient(5);

    std::vector<Client*> clients = manager.listClients();

    CHECK_EQUAL(1, (int)clients.size());
    POINTERS_EQUAL(manager.findClient(5), clients[0]);
}

TEST(ClientManager, ListClientsReturnsAllAddedClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);
    manager.addClient(7);

    std::vector<Client*> clients = manager.listClients();

    CHECK_EQUAL(3, (int)clients.size());
    CHECK_TRUE(containsClient(clients, manager.findClient(5)));
    CHECK_TRUE(containsClient(clients, manager.findClient(6)));
    CHECK_TRUE(containsClient(clients, manager.findClient(7)));
}

TEST(ClientManager, ListClientsDoesNotContainRemovedClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);
    Client* removed = manager.findClient(5);
    Client* kept = manager.findClient(6);

    manager.removeClient(5);
    std::vector<Client*> clients = manager.listClients();

    CHECK_EQUAL(1, (int)clients.size());
    CHECK_FALSE(containsClient(clients, removed));
    CHECK_TRUE(containsClient(clients, kept));
}

TEST(ClientManager, ListClientsReturnsEmptyVectorAfterRemovingAllClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);

    manager.removeClient(5);
    manager.removeClient(6);

    CHECK_TRUE(manager.listClients().empty());
}

TEST(ClientManager, ListClientsReturnsPointersToManagedClients_AC_003) {
    ClientManager manager;
    manager.addClient(5);

    std::vector<Client*> clients = manager.listClients();
    clients[0]->setNick("testuser");

    STRCMP_EQUAL("testuser", manager.findClient(5)->getNick().c_str());
}

TEST(ClientManager, ModifyingReturnedVectorDoesNotAffectManager_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    manager.addClient(6);

    std::vector<Client*> clients = manager.listClients();
    clients.clear();

    CHECK_EQUAL(2, (int)manager.listClients().size());
    CHECK_TRUE(manager.findClient(5) != NULL);
    CHECK_TRUE(manager.findClient(6) != NULL);
}

TEST(ClientManager, ListClientsIsCallableOnConstManager_AC_003) {
    ClientManager manager;
    manager.addClient(5);
    const ClientManager& constManager = manager;

    CHECK_EQUAL(1, (int)constManager.listClients().size());
}