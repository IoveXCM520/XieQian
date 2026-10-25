#include <catch2/catch_test_macros.hpp>

#include <algorithm>
#include <random>
#include <set>
#include <string>
#include <utility>
#include <vector>

#include "xieqian/core/draw/draw_engine.h"
#include "xieqian/core/roster/roster.h"

using xieqian::core::DrawEngine;
using xieqian::core::Participant;

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
        participant.group = "G" + std::to_string(index % 3);
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

std::vector<Participant> flatten(const std::vector<std::vector<Participant>> &groups)
{
    std::vector<Participant> all;
    for (const std::vector<Participant> &group : groups) {
        all.insert(all.end(), group.begin(), group.end());
    }
    return all;
}

bool allNamesUnique(const std::vector<Participant> &participants)
{
    return nameSet(participants).size() == participants.size();
}

std::vector<std::size_t> groupSizes(const std::vector<std::vector<Participant>> &groups)
{
    std::vector<std::size_t> sizes;
    sizes.reserve(groups.size());
    for (const std::vector<Participant> &group : groups) {
        sizes.push_back(group.size());
    }
    return sizes;
}

std::size_t maxGroupSize(const std::vector<std::vector<Participant>> &groups)
{
    std::size_t maximum = 0;
    for (const std::vector<Participant> &group : groups) {
        maximum = std::max(maximum, group.size());
    }
    return maximum;
}

std::size_t minGroupSize(const std::vector<std::vector<Participant>> &groups)
{
    if (groups.empty()) {
        return 0;
    }
    std::size_t minimum = groups.front().size();
    for (const std::vector<Participant> &group : groups) {
        minimum = std::min(minimum, group.size());
    }
    return minimum;
}

// 将一次分组结果序列化，用于判断多次调用是否产生了不同结果。
std::string groupsSignature(const std::vector<std::vector<Participant>> &groups)
{
    std::string signature;
    for (const std::vector<Participant> &group : groups) {
        signature += "[";
        for (const Participant &participant : group) {
            signature += participant.name;
            signature += ",";
        }
        signature += "]";
    }
    return signature;
}

std::string seatsSignature(const std::vector<Participant> &seats)
{
    std::string signature;
    for (const Participant &participant : seats) {
        signature += participant.name;
        signature += ",";
    }
    return signature;
}

}  // namespace

TEST_CASE("randomGroup splits ten participants into sizes 4,3,3", "[draw][grouping]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    const auto groups = engine.randomGroup(pool, 3);

    REQUIRE(groups.size() == 3);
    REQUIRE(groups[0].size() == 4);
    REQUIRE(groups[1].size() == 3);
    REQUIRE(groups[2].size() == 3);

    std::vector<std::size_t> sizes = groupSizes(groups);
    std::sort(sizes.begin(), sizes.end());
    REQUIRE(sizes == std::vector<std::size_t>{3, 3, 4});
}

TEST_CASE("randomGroup keeps every participant exactly once", "[draw][grouping]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    const auto groups = engine.randomGroup(pool, 3);
    const std::vector<Participant> all = flatten(groups);

    REQUIRE(all.size() == pool.size());
    REQUIRE(allNamesUnique(all));
    REQUIRE(nameSet(all) == nameSet(pool));
}

TEST_CASE("randomGroup balances group sizes when count does not divide pool", "[draw][grouping]") {
    const std::vector<std::pair<std::size_t, int>> cases = {
        {7, 3},
        {5, 2},
        {8, 3},
        {11, 4},
        {2, 2},
    };

    for (const auto &[people, groupCount] : cases) {
        DrawEngine engine(fixedGenerator());
        const std::vector<Participant> pool = makePool(people);

        const auto groups = engine.randomGroup(pool, groupCount);

        REQUIRE(groups.size() == static_cast<std::size_t>(groupCount));
        REQUIRE(flatten(groups).size() == people);
        REQUIRE(allNamesUnique(flatten(groups)));
        REQUIRE(nameSet(flatten(groups)) == nameSet(pool));
        REQUIRE(maxGroupSize(groups) - minGroupSize(groups) <= 1);
    }
}

TEST_CASE("randomGroup puts the remainder in the leading groups", "[draw][grouping]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(7);

    const auto groups = engine.randomGroup(pool, 3);

    REQUIRE(groups.size() == 3);
    REQUIRE(groups[0].size() == 3);
    REQUIRE(groups[1].size() == 2);
    REQUIRE(groups[2].size() == 2);
}

TEST_CASE("randomGroup clamps group count to pool size", "[draw][grouping]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(3);

    const auto groups = engine.randomGroup(pool, 5);

    REQUIRE(groups.size() == 3);
    for (const std::vector<Participant> &group : groups) {
        REQUIRE(group.size() == 1);
    }
    REQUIRE(allNamesUnique(flatten(groups)));
    REQUIRE(nameSet(flatten(groups)) == nameSet(pool));
}

TEST_CASE("randomGroup returns empty on non-positive group count or empty pool", "[draw][grouping][edge]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(5);

    REQUIRE(engine.randomGroup(pool, 0).empty());
    REQUIRE(engine.randomGroup(pool, -1).empty());
    REQUIRE(engine.randomGroup(pool, -100).empty());
    REQUIRE(engine.randomGroup({}, 3).empty());
    REQUIRE(engine.randomGroup({}, 0).empty());
}

TEST_CASE("randomGroup preserves participant fields", "[draw][grouping]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(6);

    const auto groups = engine.randomGroup(pool, 4);
    const std::vector<Participant> all = flatten(groups);

    REQUIRE(all.size() == pool.size());

    std::vector<std::pair<std::string, std::string>> expected;
    for (const Participant &participant : pool) {
        expected.emplace_back(participant.name, participant.studentId);
    }

    std::vector<std::pair<std::string, std::string>> actual;
    for (const Participant &participant : all) {
        actual.emplace_back(participant.name, participant.studentId);
        REQUIRE_FALSE(participant.studentId.empty());
    }

    std::sort(expected.begin(), expected.end());
    std::sort(actual.begin(), actual.end());
    REQUIRE(actual == expected);
}

TEST_CASE("randomGroup is reproducible with the same seed", "[draw][grouping]") {
    const std::vector<Participant> pool = makePool(10);

    DrawEngine first(fixedGenerator());
    DrawEngine second(fixedGenerator());

    REQUIRE(groupsSignature(first.randomGroup(pool, 3)) == groupsSignature(second.randomGroup(pool, 3)));
    REQUIRE(groupsSignature(first.randomGroup(makePool(7), 2)) ==
            groupsSignature(second.randomGroup(makePool(7), 2)));
}

TEST_CASE("randomGroup produces varying layouts across calls", "[draw][grouping][randomness]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    std::set<std::string> signatures;
    for (int round = 0; round < 20; ++round) {
        const auto groups = engine.randomGroup(pool, 3);
        REQUIRE(groups.size() == 3);
        REQUIRE(flatten(groups).size() == pool.size());
        signatures.insert(groupsSignature(groups));
    }

    REQUIRE(signatures.size() >= 2);
}

TEST_CASE("randomSeat returns a permutation of the pool", "[draw][seat]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    const auto seats = engine.randomSeat(pool);

    REQUIRE(seats.size() == pool.size());
    REQUIRE(allNamesUnique(seats));
    REQUIRE(nameSet(seats) == nameSet(pool));

    std::vector<std::pair<std::string, std::string>> expected;
    std::vector<std::pair<std::string, std::string>> actual;
    for (const Participant &participant : pool) {
        expected.emplace_back(participant.name, participant.studentId);
    }
    for (const Participant &participant : seats) {
        actual.emplace_back(participant.name, participant.studentId);
    }
    std::sort(expected.begin(), expected.end());
    std::sort(actual.begin(), actual.end());
    REQUIRE(actual == expected);
}

TEST_CASE("randomSeat leaves the source pool untouched", "[draw][seat]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);
    const std::vector<Participant> before = pool;

    for (int round = 0; round < 20; ++round) {
        const auto seats = engine.randomSeat(pool);
        REQUIRE(seats.size() == pool.size());
    }

    REQUIRE(pool.size() == before.size());
    for (std::size_t index = 0; index < before.size(); ++index) {
        REQUIRE(pool[index].name == before[index].name);
        REQUIRE(pool[index].studentId == before[index].studentId);
    }
}

TEST_CASE("randomSeat handles empty and single-element pools", "[draw][seat][edge]") {
    DrawEngine engine(fixedGenerator());

    REQUIRE(engine.randomSeat({}).empty());

    const std::vector<Participant> single = makePool(1);
    const auto seats = engine.randomSeat(single);
    REQUIRE(seats.size() == 1);
    REQUIRE(seats.front().name == single.front().name);
    REQUIRE(seats.front().studentId == single.front().studentId);
}

TEST_CASE("randomSeat varies order across calls", "[draw][seat][randomness]") {
    DrawEngine engine(fixedGenerator());
    const std::vector<Participant> pool = makePool(10);

    std::set<std::string> orders;
    for (int round = 0; round < 20; ++round) {
        const auto seats = engine.randomSeat(pool);
        REQUIRE(seats.size() == pool.size());
        REQUIRE(nameSet(seats) == nameSet(pool));
        orders.insert(seatsSignature(seats));
    }

    REQUIRE(orders.size() >= 2);
}

TEST_CASE("randomSeat is reproducible with the same seed", "[draw][seat]") {
    const std::vector<Participant> pool = makePool(8);

    DrawEngine first(fixedGenerator());
    DrawEngine second(fixedGenerator());

    REQUIRE(seatsSignature(first.randomSeat(pool)) == seatsSignature(second.randomSeat(pool)));
}
