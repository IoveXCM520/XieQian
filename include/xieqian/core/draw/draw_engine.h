#pragma once

#include <cstddef>
#include <optional>
#include <random>
#include <string>
#include <vector>

#include "xieqian/core/roster/roster.h"

namespace xieqian::core {

class DrawEngine
{
public:
    explicit DrawEngine(std::mt19937_64 rng);

    [[nodiscard]] std::optional<std::string> drawOne(const Roster &roster);

    // 不放回抽取：结果互不重复，请求数量超过可用人数时返回全部可用参与者。
    [[nodiscard]] std::vector<std::string> drawMultiple(const Roster &roster, std::size_t count);

private:
    std::mt19937_64 rng_;
};

}  // namespace xieqian::core
