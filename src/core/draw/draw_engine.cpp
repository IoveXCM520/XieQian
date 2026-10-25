#include "xieqian/core/draw/draw_engine.h"

#include <algorithm>
#include <utility>

namespace xieqian::core {

DrawEngine::DrawEngine(std::mt19937_64 rng) : rng_(std::move(rng)) {}

std::optional<std::string> DrawEngine::drawOne(const Roster &roster)
{
    const std::vector<Participant> winners = draw(roster.enabledParticipants(), 1, DrawStrategy::Random);
    if (winners.empty()) {
        return std::nullopt;
    }
    return winners.front().name;
}

std::vector<std::string> DrawEngine::drawMultiple(const Roster &roster, std::size_t count)
{
    std::vector<std::string> winners;
    const std::vector<Participant> picked =
        draw(roster.enabledParticipants(), static_cast<int>(count), DrawStrategy::Random);
    winners.reserve(picked.size());
    for (const Participant &participant : picked) {
        winners.push_back(participant.name);
    }
    return winners;
}

std::vector<Participant> DrawEngine::draw(const std::vector<Participant> &pool, int count, DrawStrategy strategy)
{
    std::vector<Participant> winners;
    if (count <= 0 || pool.empty()) {
        return winners;
    }

    const auto wanted = std::min(static_cast<std::size_t>(count), pool.size());
    if (strategy == DrawStrategy::Weighted) {
        return drawWeighted(pool, wanted);
    }

    // 只移动索引，避免在大名单上复制 Participant；最后按索引回填中签者。
    std::vector<std::size_t> unseen;
    std::vector<std::size_t> seen;
    unseen.reserve(pool.size());
    if (strategy == DrawStrategy::NoRepeat) {
        seen.reserve(pool.size());
        for (std::size_t index = 0; index < pool.size(); ++index) {
            const auto id = participantId(pool[index]);
            const bool drawn = std::find(drawnIds_.begin(), drawnIds_.end(), id) != drawnIds_.end();
            (drawn ? seen : unseen).push_back(index);
        }
    } else {
        for (std::size_t index = 0; index < pool.size(); ++index) {
            unseen.push_back(index);
        }
    }

    std::shuffle(unseen.begin(), unseen.end(), rng_);
    std::shuffle(seen.begin(), seen.end(), rng_);

    winners.reserve(wanted);
    for (const std::size_t index : unseen) {
        if (winners.size() == wanted) {
            break;
        }
        winners.push_back(pool[index]);
    }
    for (const std::size_t index : seen) {
        if (winners.size() == wanted) {
            break;
        }
        winners.push_back(pool[index]);
    }

    if (strategy == DrawStrategy::NoRepeat) {
        for (const Participant &winner : winners) {
            const auto id = participantId(winner);
            if (std::find(drawnIds_.begin(), drawnIds_.end(), id) == drawnIds_.end()) {
                drawnIds_.push_back(id);
            }
        }
    }
    return winners;
}

std::vector<std::vector<Participant>> DrawEngine::randomGroup(const std::vector<Participant> &pool,
                                                              int groupCount)
{
    std::vector<std::vector<Participant>> groups;
    if (groupCount <= 0 || pool.empty()) {
        return groups;
    }

    const auto groupTotal = std::min(static_cast<std::size_t>(groupCount), pool.size());
    std::vector<Participant> shuffled = pool;
    std::shuffle(shuffled.begin(), shuffled.end(), rng_);

    const std::size_t base = shuffled.size() / groupTotal;
    const std::size_t remainder = shuffled.size() % groupTotal;

    groups.resize(groupTotal);
    std::size_t cursor = 0;
    for (std::size_t group = 0; group < groupTotal; ++group) {
        const std::size_t size = base + (group < remainder ? 1 : 0);
        groups[group].assign(shuffled.begin() + static_cast<std::ptrdiff_t>(cursor),
                             shuffled.begin() + static_cast<std::ptrdiff_t>(cursor + size));
        cursor += size;
    }
    return groups;
}

std::vector<Participant> DrawEngine::randomSeat(const std::vector<Participant> &pool)
{
    std::vector<Participant> seats = pool;
    std::shuffle(seats.begin(), seats.end(), rng_);
    return seats;
}

void DrawEngine::clearDrawnHistory()
{
    drawnIds_.clear();
}

bool DrawEngine::isDrawn(const Participant &participant) const
{
    const auto id = participantId(participant);
    return std::find(drawnIds_.begin(), drawnIds_.end(), id) != drawnIds_.end();
}

std::vector<Participant> DrawEngine::drawWeighted(const std::vector<Participant> &pool, std::size_t count)
{
    std::vector<Participant> remaining = pool;
    std::vector<Participant> winners;
    winners.reserve(count);

    std::uniform_real_distribution<double> unit(0.0, 1.0);
    while (winners.size() < count && !remaining.empty()) {
        double totalWeight = 0.0;
        for (const Participant &participant : remaining) {
            totalWeight += std::max(0.0, participant.weight);
        }

        std::size_t picked = remaining.size() - 1;
        if (totalWeight <= 0.0) {
            std::uniform_int_distribution<std::size_t> uniform(0, remaining.size() - 1);
            picked = uniform(rng_);
        } else {
            double cursor = unit(rng_) * totalWeight;
            for (std::size_t index = 0; index < remaining.size(); ++index) {
                const double weight = std::max(0.0, remaining[index].weight);
                if (cursor < weight) {
                    picked = index;
                    break;
                }
                cursor -= weight;
            }
        }

        winners.push_back(remaining[picked]);
        remaining.erase(remaining.begin() + static_cast<std::ptrdiff_t>(picked));
    }
    return winners;
}

}  // namespace xieqian::core
