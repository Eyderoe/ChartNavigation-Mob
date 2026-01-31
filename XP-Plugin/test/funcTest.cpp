#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN

#include "doctest.h"
#include "../func.hpp"

std::array<char, 512> str2array (const std::string_view str) {
    std::array<char, 512> data{};
    for (int i = 0; i < str.length(); i++)
        data[i] = static_cast<char>(str[i]);
    return data;
}

TEST_CASE("getString") {
    CHECK(getString(str2array("a"), 0) == "a");

    CHECK(getString(str2array(" b "), 0) == "b");
    CHECK(getString(str2array(" c"), 0) == "c");
    CHECK(getString(str2array("d "), 0) == "d");

    CHECK(getString(str2array(" ab "), 0) == "ab");

    CHECK(getString(str2array("ab cd ef gh i jkl"),1) == "ghijk");
}
