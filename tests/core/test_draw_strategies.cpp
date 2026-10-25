#include <catch2/catch_test_macros.hpp>

#include <random>
#include <set>
#include <string>
#include <vector>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

using xieqian::core::DrawEngine;
using xieqian::core::DrawStrategy;
using xieqian::core::Participant;
using xieqian::core::Roster;

namespace {

std::mt19937_64 fixedGenerator()
{
    return std::mt19937_64(2024);
}

std::vector<Participant> makePool(std::size_t size)
{
    std::vector<Participant> pool;
    pool.reserve(size);
    for (std::size_t index = 0; index < size; ++index) {
        Participant participant;
        participant.name = "P" + std::to_string(index);
        participant.studentId = "2024" + std::to_string(100 + index);
        pool.push_back(participant);
    }
    return pool;
}

std::set<std::string> nameSet(const std::vector<Participant> &participants)
{
    std::set<std::string> names;
    for (const Participant &participant : participants) {
        names.insert(participant.name);
    }
    return names;
}

bool allNamesUnique(const std::vector<Participant> &participants)
{
    return nameSet(participants).size() == participants.size();
}

}  // namespace

TEST_CASE("NoRepeat draws unique winners across consecutive calls", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    const auto first = engine.draw(pool, 5, DrawStrategy::NoRepeat);
    REQUIRE(first.size() == 5);
    REQUIRE(allNamesUnique(first));

    const auto second = engine.draw(pool, 5, DrawStrategy::NoRepeat);
    REQUIRE(second.size() == 5);
    REQUIRE(allNamesUnique(second));

    const std::set<std::string> poolNames = nameSet(pool);
    const std::set<std::string> firstNames = nameSet(first);
    for (const Participant &winner : second) {
        REQUIRE(poolNames.contains(winner.name));
        REQUIRE_FALSE(firstNames.contains(winner.name));
    }
}

TEST_CASE("NoRepeat falls back to drawn participants when pool exhausted", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(5);

    const auto first = engine.draw(pool, 5, DrawStrategy::NoRepeat);
    REQUIRE(first.size() == 5);
    REQUIRE(allNamesUnique(first));

    const auto second = engine.draw(pool, 3, DrawStrategy::NoRepeat);
    REQUIRE(second.size() == 3);
    REQUIRE(allNamesUnique(second));

    const std::set<std::string> firstNames = nameSet(first);
    for (const Participant &winner : second) {
        REQUIRE(firstNames.contains(winner.name));
    }
}

TEST_CASE("Random strategy ignores NoRepeat history", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(5);

    const auto exhaustive = engine.draw(pool, 5, DrawStrategy::NoRepeat);
    REQUIRE(exhaustive.size() == 5);

    const auto randomPair = engine.draw(pool, 3, DrawStrategy::Random);
    REQUIRE(randomPair.size() == 3);
    REQUIRE(allNamesUnique(randomPair));

    const auto randomAfter = engine.draw(pool, 2, DrawStrategy::Random);
    REQUIRE(randomAfter.size() == 2);
    REQUIRE(allNamesUnique(randomAfter));
}

TEST_CASE("clearDrawnHistory makes previous winners eligible again", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(3);

    int replays = 0;
    for (int round = 0; round < 30; ++round) {
        const auto batch = engine.draw(pool, 2, DrawStrategy::NoRepeat);
        REQUIRE(batch.size() == 2);
        REQUIRE(allNamesUnique(batch));

        engine.clearDrawnHistory();

        const auto repeated = engine.draw(pool, 2, DrawStrategy::NoRepeat);
        REQUIRE(repeated.size() == 2);
        REQUIRE(allNamesUnique(repeated));
        if (nameSet(repeated) == nameSet(batch)) {
            ++replays;
        }

        engine.clearDrawnHistory();
    }

    // 清空历史后两名已中签者应重新进入未中签池，因此存在与上一批完全相同的结果。
    REQUIRE(replays > 0);

    const std::vector<Participant> pair = makePool(2);
    const auto firstPair = engine.draw(pair, 2, DrawStrategy::NoRepeat);
    REQUIRE(firstPair.size() == 2);
    REQUIRE(allNamesUnique(firstPair));

    engine.clearDrawnHistory();

    const auto secondPair = engine.draw(pair, 2, DrawStrategy::NoRepeat);
    REQUIRE(secondPair.size() == 2);
    REQUIRE(allNamesUnique(secondPair));
    REQUIRE(nameSet(secondPair) == nameSet(firstPair));
}

TEST_CASE("Zero, negative and oversized counts are bounded", "[draw][strategy]") {
    const std::vector<Participant> pool = makePool(5);
    const std::vector<DrawStrategy> strategies = {DrawStrategy::Random, DrawStrategy::NoRepeat,
                                                  DrawStrategy::Weighted};

    for (const DrawStrategy strategy : strategies) {
        DrawEngine engine(fixedGenerator());

        REQUIRE(engine.draw({}, 3, strategy).empty());
        REQUIRE(engine.draw(pool, 0, strategy).empty());
        REQUIRE(engine.draw(pool, -4, strategy).empty());

        const auto truncated = engine.draw(pool, 10, strategy);
        REQUIRE(truncated.size() == pool.size());
        REQUIRE(allNamesUnique(truncated));
        REQUIRE(nameSet(truncated) == nameSet(pool));
    }
}

TEST_CASE("Weighted with equal weights behaves like uniform draw", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(5);

    const auto winners = engine.draw(pool, 3, DrawStrategy::Weighted);
    REQUIRE(winners.size() == 3);
    REQUIRE(allNamesUnique(winners));

    const std::set<std::string> poolNames = nameSet(pool);
    for (const Participant &winner : winners) {
        REQUIRE(poolNames.contains(winner.name));
    }
}

TEST_CASE("Weighted favours high weight participants", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    std::vector<Participant> pool = makePool(2);
    pool[0].weight = 100.0;
    pool[1].weight = 1.0;

    int heavy = 0;
    int light = 0;
    for (int attempt = 0; attempt < 400; ++attempt) {
        const auto winners = engine.draw(pool, 1, DrawStrategy::Weighted);
        REQUIRE(winners.size() == 1);
        if (winners.front().name == pool[0].name) {
            ++heavy;
        } else {
            REQUIRE(winners.front().name == pool[1].name);
            ++light;
        }
    }

    REQUIRE(heavy > light);
    REQUIRE(heavy >= 350);
}

TEST_CASE("Weighted skips participants with non-positive weights", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    std::vector<Participant> pool = makePool(3);
    pool[0].weight = 0.0;
    pool[1].weight = -2.5;
    pool[2].weight = 1.0;

    for (int attempt = 0; attempt < 200; ++attempt) {
        const auto winners = engine.draw(pool, 1, DrawStrategy::Weighted);
        REQUIRE(winners.size() == 1);
        REQUIRE(winners.front().name == pool[2].name);
    }
}

TEST_CASE("Weighted falls back to uniform when all weights are zero", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    std::vector<Participant> pool = makePool(5);
    for (Participant &participant : pool) {
        participant.weight = 0.0;
    }

    const auto winners = engine.draw(pool, 5, DrawStrategy::Weighted);
    REQUIRE(winners.size() == 5);
    REQUIRE(allNamesUnique(winners));
    REQUIRE(nameSet(winners) == nameSet(pool));
}

TEST_CASE("Weighted draws without replacement", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    std::vector<Participant> pool = makePool(5);
    pool[0].weight = 10.0;
    pool[1].weight = 0.0;
    pool[2].weight = 3.0;
    pool[3].weight = 0.5;
    pool[4].weight = 7.0;

    const auto winners = engine.draw(pool, 5, DrawStrategy::Weighted);
    REQUIRE(winners.size() == 5);
    REQUIRE(allNamesUnique(winners));
    REQUIRE(nameSet(winners) == nameSet(pool));
}

TEST_CASE("Weighted skips zero weight while positive weights remain", "[draw][strategy][weighted]") {
    DrawEngine engine(fixedGenerator());
    std::vector<Participant> pool = makePool(5);
    pool[0].weight = 10.0;
    pool[1].weight = 0.0;
    pool[2].weight = 3.0;
    pool[3].weight = 0.5;
    pool[4].weight = 7.0;

    const std::set<std::string> expected = {pool[0].name, pool[2].name, pool[3].name, pool[4].name};

    const auto winners = engine.draw(pool, 4, DrawStrategy::Weighted);
    REQUIRE(winners.size() == 4);
    REQUIRE(allNamesUnique(winners));
    REQUIRE(nameSet(winners) == expected);
}

TEST_CASE("Random strategy draws without replacement", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(5);
    const std::set<std::string> poolNames = nameSet(pool);

    const auto subset = engine.draw(pool, 3, DrawStrategy::Random);
    REQUIRE(subset.size() == 3);
    REQUIRE(allNamesUnique(subset));
    for (const Participant &winner : subset) {
        REQUIRE(poolNames.contains(winner.name));
    }

    const auto all = engine.draw(pool, 10, DrawStrategy::Random);
    REQUIRE(all.size() == 5);
    REQUIRE(allNamesUnique(all));
    REQUIRE(nameSet(all) == poolNames);
}

TEST_CASE("DrawOne returns the only enabled participant", "[draw][strategy]") {
    DrawEngine engine(fixedGenerator());
    Roster roster;
    roster.add("苏婉宁");
    roster.add("林砚舟", false);
    roster.add("顾南乔", false);

    for (int attempt = 0; attempt < 30; ++attempt) {
        const auto winner = engine.drawOne(roster);
        REQUIRE(winner.has_value());
        REQUIRE(*winner == "苏婉宁");
    }
}
