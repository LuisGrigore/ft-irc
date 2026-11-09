#include "CppUTest/TestHarness.h"
#include "NickManager.hpp"

#include <string>

/*
 * CppUTest forces `#define new new(__FILE__, __LINE__)` through
 * MemoryLeakDetectorNewMacros.h (included from TestHarness.h). As the
 * project compiles with CppUTest leak detection disabled
 * (MEMORY_LEAK_DETECTION OFF), no one provides the placement `new` operator
 * required by that macro. It is undefined here, only in test translation
 * units, to use the ordinary `new` from the standard library.
 */
#undef new

TEST_GROUP(NickManager){};

// Is Available

TEST(NickManager, IsAvailableReturnsTrueForUnreservedNick_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, IsAvailableReturnsFalseForReservedNick_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    CHECK_FALSE(manager.isAvailable("alice"));
}

TEST(NickManager, IsAvailableReturnsTrueForDifferentNickThanReservedOne_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    CHECK_TRUE(manager.isAvailable("bob"));
}

TEST(NickManager, IsAvailableReturnsTrueAfterNickIsReleased_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.release("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, IsAvailableDoesNotReserveTheNick_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isAvailable("alice"));
    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, IsAvailableTracksEachNickIndependently_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.reserve("bob");
    manager.release("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
    CHECK_FALSE(manager.isAvailable("bob"));
    CHECK_TRUE(manager.isAvailable("carol"));
}

// Reserve

TEST(NickManager, ReserveReturnsFalseForInvalidNick_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.reserve(""));
    CHECK_FALSE(manager.reserve("1alice"));
    CHECK_FALSE(manager.reserve("ali ce"));
    CHECK_FALSE(manager.reserve("#alice"));
    CHECK_FALSE(manager.reserve("abcdefghijklmnopqrstuvwxyz12345"));
}

TEST(NickManager, ReserveDoesNotStoreInvalidNick_AC_004) {
    NickManager manager;

    manager.reserve("1alice");

    CHECK_TRUE(manager.isAvailable("1alice"));
}

TEST(NickManager, ReserveReturnsTrueForAvailableNick_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.reserve("alice"));
}

TEST(NickManager, ReserveMakesNickUnavailable_AC_004) {
    NickManager manager;

    manager.reserve("alice");

    CHECK_FALSE(manager.isAvailable("alice"));
}

TEST(NickManager, ReserveReturnsFalseForAlreadyReservedNick_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    CHECK_FALSE(manager.reserve("alice"));
}

TEST(NickManager, ReserveKeepsNickUnavailableAfterFailedReserve_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    manager.reserve("alice");

    CHECK_FALSE(manager.isAvailable("alice"));
}

TEST(NickManager, ReserveAllowsReservingDifferentNicks_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.reserve("alice"));
    CHECK_TRUE(manager.reserve("bob"));
    CHECK_TRUE(manager.reserve("carol"));
}

TEST(NickManager, ReserveDoesNotAffectOtherNicks_AC_004) {
    NickManager manager;

    manager.reserve("alice");

    CHECK_TRUE(manager.isAvailable("bob"));
}

TEST(NickManager, ReserveReturnsTrueAgainAfterNickIsReleased_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.release("alice");

    CHECK_TRUE(manager.reserve("alice"));
}

// Release

TEST(NickManager, ReleaseMakesReservedNickAvailable_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    manager.release("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, ReleaseDoesNotAffectOtherReservedNicks_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.reserve("bob");

    manager.release("alice");

    CHECK_FALSE(manager.isAvailable("bob"));
}

TEST(NickManager, ReleaseOfUnreservedNickDoesNothing_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    manager.release("bob");

    CHECK_TRUE(manager.isAvailable("bob"));
    CHECK_FALSE(manager.isAvailable("alice"));
}

TEST(NickManager, ReleaseOnEmptyManagerDoesNothing_AC_004) {
    NickManager manager;

    manager.release("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, ReleaseTwiceDoesNothingTheSecondTime_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.reserve("bob");

    manager.release("alice");
    manager.release("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
    CHECK_FALSE(manager.isAvailable("bob"));
}

TEST(NickManager, ReleasedNickCanBeReservedAgain_AC_004) {
    NickManager manager;
    manager.reserve("alice");
    manager.release("alice");

    manager.reserve("alice");

    CHECK_FALSE(manager.isAvailable("alice"));
}

// Case Insensitivity

TEST(NickManager, IsAvailableReturnsFalseForReservedNickWithDifferentCase_AC_004) {
    NickManager manager;
    manager.reserve("Alice");

    CHECK_FALSE(manager.isAvailable("alice"));
    CHECK_FALSE(manager.isAvailable("ALICE"));
    CHECK_FALSE(manager.isAvailable("aLiCe"));
}

TEST(NickManager, ReserveReturnsFalseForReservedNickWithDifferentCase_AC_004) {
    NickManager manager;
    manager.reserve("Alice");

    CHECK_FALSE(manager.reserve("alice"));
    CHECK_FALSE(manager.reserve("ALICE"));
}

TEST(NickManager, ReleaseIgnoresCaseOfTheNick_AC_004) {
    NickManager manager;
    manager.reserve("Alice");

    manager.release("ALICE");

    CHECK_TRUE(manager.isAvailable("Alice"));
    CHECK_TRUE(manager.isAvailable("alice"));
}

TEST(NickManager, ReserveSucceedsWithAnyCaseAfterRelease_AC_004) {
    NickManager manager;
    manager.reserve("Alice");
    manager.release("alice");

    CHECK_TRUE(manager.reserve("ALICE"));
    CHECK_FALSE(manager.isAvailable("Alice"));
}

TEST(NickManager, CaseInsensitivityDoesNotAffectDifferentNicks_AC_004) {
    NickManager manager;
    manager.reserve("Alice");

    CHECK_TRUE(manager.isAvailable("Bob"));
    CHECK_TRUE(manager.reserve("BOB"));
}

TEST(NickManager, IsValidAcceptsNickRegardlessOfCase_AC_004) {
    NickManager manager;
    manager.reserve("Alice");

    CHECK_TRUE(manager.isValid("alice"));
    CHECK_TRUE(manager.isValid("ALICE"));
}

// Is Valid: accepted nicknames

TEST(NickManager, IsValidAcceptsSimpleLetterNick_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("alice"));
}

TEST(NickManager, IsValidAcceptsSingleLetterNick_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("a"));
}

TEST(NickManager, IsValidAcceptsUppercaseLetters_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("ALICE"));
    CHECK_TRUE(manager.isValid("Alice"));
}

TEST(NickManager, IsValidAcceptsDigitsAfterFirstCharacter_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("alice123"));
    CHECK_TRUE(manager.isValid("a1b2c3"));
}

TEST(NickManager, IsValidAcceptsHyphenAfterFirstCharacter_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("nick-name"));
}

TEST(NickManager, IsValidAcceptsSpecialCharactersAsFirstCharacter_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("[nick"));
    CHECK_TRUE(manager.isValid("]nick"));
    CHECK_TRUE(manager.isValid("\\nick"));
    CHECK_TRUE(manager.isValid("`nick"));
    CHECK_TRUE(manager.isValid("_nick"));
    CHECK_TRUE(manager.isValid("^nick"));
    CHECK_TRUE(manager.isValid("{nick"));
    CHECK_TRUE(manager.isValid("|nick"));
    CHECK_TRUE(manager.isValid("}nick"));
}

TEST(NickManager, IsValidAcceptsSpecialCharactersAfterFirstCharacter_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("a[b"));
    CHECK_TRUE(manager.isValid("a_b"));
    CHECK_TRUE(manager.isValid("a|b"));
    CHECK_TRUE(manager.isValid("a{b}"));
}

TEST(NickManager, IsValidAcceptsNickLongerThanNineCharacters_AC_004) {
    NickManager manager;

    CHECK_TRUE(manager.isValid("abcdefghij"));
}

TEST(NickManager, IsValidAcceptsNickWithMaximumLength_AC_004) {
    NickManager manager;

    // 30 characters
    CHECK_TRUE(manager.isValid("abcdefghijklmnopqrstuvwxyz1234"));
}

// Is Valid: rejected nicknames

TEST(NickManager, IsValidRejectsEmptyNick_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid(""));
}

TEST(NickManager, IsValidRejectsNickLongerThanMaximumLength_AC_004) {
    NickManager manager;

    // 31 characters
    CHECK_FALSE(manager.isValid("abcdefghijklmnopqrstuvwxyz12345"));
}

TEST(NickManager, IsValidRejectsNickStartingWithDigit_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("1alice"));
    CHECK_FALSE(manager.isValid("9"));
}

TEST(NickManager, IsValidRejectsNickStartingWithHyphen_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("-alice"));
}

TEST(NickManager, IsValidRejectsNickContainingSpaces_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("ali ce"));
    CHECK_FALSE(manager.isValid(" alice"));
    CHECK_FALSE(manager.isValid("alice "));
    CHECK_FALSE(manager.isValid(" "));
}

TEST(NickManager, IsValidRejectsNickStartingWithChannelPrefix_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("#alice"));
    CHECK_FALSE(manager.isValid("&alice"));
}

TEST(NickManager, IsValidRejectsNickStartingWithColon_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid(":alice"));
}

TEST(NickManager, IsValidRejectsNickContainingProtocolReservedCharacters_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("ali,ce"));
    CHECK_FALSE(manager.isValid("ali!ce"));
    CHECK_FALSE(manager.isValid("ali@ce"));
    CHECK_FALSE(manager.isValid("ali*ce"));
    CHECK_FALSE(manager.isValid("ali?ce"));
    CHECK_FALSE(manager.isValid("ali:ce"));
    CHECK_FALSE(manager.isValid("ali.ce"));
}

TEST(NickManager, IsValidRejectsNickContainingControlCharacters_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("ali\rce"));
    CHECK_FALSE(manager.isValid("ali\nce"));
    CHECK_FALSE(manager.isValid("ali\tce"));
}

TEST(NickManager, IsValidRejectsNickContainingNonAsciiCharacters_AC_004) {
    NickManager manager;

    CHECK_FALSE(manager.isValid("ali\xC3\xB1"
                                "o"));
}

// Is Valid: independence from reservation state

TEST(NickManager, IsValidDoesNotDependOnReservationState_AC_004) {
    NickManager manager;
    manager.reserve("alice");

    CHECK_TRUE(manager.isValid("alice"));
    CHECK_TRUE(manager.isValid("bob"));
}

TEST(NickManager, IsValidDoesNotReserveTheNick_AC_004) {
    NickManager manager;

    manager.isValid("alice");

    CHECK_TRUE(manager.isAvailable("alice"));
}