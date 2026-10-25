#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <random>
#include <string>
#include <vector>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

using xieqian::core::DrawEngine;
using xieqian::core::Roster;

namespace {

std::mt19937_64 fixedGenerator()
{
    return std::mt19937_64(2024);
}

}  // namespace

TEST_CASE("空名单抽不出结果", "[draw]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;

    REQUIRE_FALSE(engine.drawOne(roster).has_value());
    REQUIRE(engine.drawMultiple(roster, 3).empty());
}

TEST_CASE("只有一名可用参与者时结果唯一", "[draw]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟", false);

    for (int attempt = 0; attempt < 20; ++attempt) {
        const auto winner = engine.drawOne(roster);
        REQUIRE(winner.has_value());
        REQUIRE(*winner == "苏婉宁");
    }
}

TEST_CASE("中奖者必定来自可用名单", "[draw]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟");
    roster.add("顾南乔");
    roster.add("白清让");
    roster.add("沈亦初", false);

    for (int attempt = 0; attempt < 50; ++attempt) {
        const auto winner = engine.drawOne(roster);
        REQUIRE(winner.has_value());
        REQUIRE(*winner != "沈亦初");
    }
}

TEST_CASE("多次抽取不放回且不超过可用人数", "[draw]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟");
    roster.add("顾南乔");

    const auto pair = engine.drawMultiple(roster, 2);
    REQUIRE(pair.size() == 2);
    REQUIRE(pair[0] != pair[1]);

    const auto all = engine.drawMultiple(roster, 10);
    REQUIRE(all.size() == 3);

    std::vector<std::string> sorted = all;
    std::sort(sorted.begin(), sorted.end());
    REQUIRE(std::unique(sorted.begin(), sorted.end()) == sorted.end());
}

TEST_CASE("抽取数量为零时返回空结果", "[draw]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;
    roster.add("苏婉宁");

    REQUIRE(engine.drawMultiple(roster, 0).empty());
}
