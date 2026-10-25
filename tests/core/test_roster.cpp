#include <catch2/catch_test_macros.hpp>

#include "xieqian/core/roster/roster.h"

using xieqian::core::Roster;

TEST_CASE("名单默认为空", "[roster]") {
    Roster roster;

    REQUIRE(roster.size() == 0);
    REQUIRE(roster.enabledParticipants().empty());
}

TEST_CASE("加入参与者后保持插入顺序", "[roster]") {
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟");

    REQUIRE(roster.size() == 2);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(1).name == "林砚舟");
    REQUIRE(roster.at(0).enabled);
    REQUIRE(roster.at(1).enabled);
}

TEST_CASE("禁用状态决定参与者是否进入可用名单", "[roster]") {
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟", false);
    roster.add("顾南乔");

    const auto initiallyEnabled = roster.enabledParticipants();
    REQUIRE(initiallyEnabled.size() == 2);
    REQUIRE(initiallyEnabled[0].name == "苏婉宁");
    REQUIRE(initiallyEnabled[1].name == "顾南乔");

    roster.setEnabled(1, true);
    REQUIRE(roster.enabledParticipants().size() == 3);

    roster.setEnabled(0, false);
    const auto afterDisable = roster.enabledParticipants();
    REQUIRE(afterDisable.size() == 2);
    REQUIRE(afterDisable[0].name == "林砚舟");
    REQUIRE(afterDisable[1].name == "顾南乔");
}

TEST_CASE("清空名单后不再保留参与者", "[roster]") {
    Roster roster;
    roster.add("苏婉宁");
    roster.clear();

    REQUIRE(roster.size() == 0);
    REQUIRE(roster.enabledParticipants().empty());
}
