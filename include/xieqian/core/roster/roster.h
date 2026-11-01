#pragma once

#include <cstddef>
#include <string>
#include <vector>

namespace xieqian::core {

struct Participant {
    std::string name;
    std::string studentId;
    std::string group;
    bool enabled = true;
    double weight = 1.0;
    // 动态权重用：累计中签次数与连续中签次数，抽中后权重自动衰减
    int drawCount = 0;
    int streak = 0;
};

// 参与者标识：学号优先，缺学号时使用姓名。
[[nodiscard]] std::string participantId(const Participant &participant);

// 动态权重：baseWeight * exp(-drawCount / 3) * max(0.1, 1 - streak * 0.2)
[[nodiscard]] double dynamicWeight(const Participant &participant);

class Roster
{
public:
    void add(Participant participant);
    void add(std::string name, bool enabled = true);
    void clear();

    void setEnabled(std::size_t index, bool enabled);
    void setWeight(std::size_t index, double weight);

    // 按下标移除参与者；下标越界时返回 false。
    bool removeAt(std::size_t index);

    [[nodiscard]] std::size_t size() const;
    [[nodiscard]] const Participant &at(std::size_t index) const;
    [[nodiscard]] std::vector<Participant> enabledParticipants() const;

    // 记录一次开奖：中签者 drawCount 与 streak 各加一，其余人 streak 归零；
    // 只按标识匹配，找不到的标识忽略。
    void recordWins(const std::vector<std::string> &winnerIds);

    // 清空 drawCount 与 streak，用于重置抽奖状态。
    void resetDrawStats();

private:
    std::vector<Participant> participants_;
};

}  // namespace xieqian::core
