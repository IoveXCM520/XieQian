#pragma once

#include <cstddef>
#include <optional>
#include <random>
#include <string>
#include <vector>

#include "xieqian/core/roster/roster.h"

namespace xieqian::core {

enum class DrawStrategy { Random, NoRepeat, Weighted };

class DrawEngine
{
public:
    explicit DrawEngine(std::mt19937_64 rng);

    [[nodiscard]] std::optional<std::string> drawOne(const Roster &roster);

    // 不放回抽取：结果互不重复，请求数量超过可用人数时返回全部可用参与者。
    [[nodiscard]] std::vector<std::string> drawMultiple(const Roster &roster, std::size_t count);

    // 按策略从 pool 中抽取至多 count 名，结果互不重复；count 超过池容量时返回整个池。
    [[nodiscard]] std::vector<Participant> draw(const std::vector<Participant> &pool, int count, DrawStrategy strategy);

    // NoRepeat 策略下累积的中签记录，清空名单时应同步重置。
    void clearDrawnHistory();

private:
    [[nodiscard]] std::vector<Participant> drawWeighted(const std::vector<Participant> &pool, std::size_t count);

    // 中签记录以学号为准，缺学号时退化为姓名。
    [[nodiscard]] static std::string participantId(const Participant &participant);

    std::mt19937_64 rng_;
    std::vector<std::string> drawnIds_;
};

}  // namespace xieqian::core
