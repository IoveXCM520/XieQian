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

    // 随机分组：打乱名单后均匀分配，各组人数差不超过 1，余数优先补到靠前的组；
    // groupCount 超过池容量时按池容量分组，groupCount 非正或池为空时返回空列表。
    [[nodiscard]] std::vector<std::vector<Participant>> randomGroup(const std::vector<Participant> &pool,
                                                                     int groupCount);

    // 随机排座位：返回打乱顺序后的名单副本，原池顺序不变。
    [[nodiscard]] std::vector<Participant> randomSeat(const std::vector<Participant> &pool);

    // NoRepeat 策略下累积的中签记录，清空名单时应同步重置。
    void clearDrawnHistory();

    [[nodiscard]] bool isDrawn(const Participant &participant) const;

private:
    [[nodiscard]] std::vector<Participant> drawWeighted(const std::vector<Participant> &pool, std::size_t count);

    std::mt19937_64 rng_;
    std::vector<std::string> drawnIds_;
};

}  // namespace xieqian::core
