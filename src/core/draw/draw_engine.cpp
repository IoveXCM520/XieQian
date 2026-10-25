#include "xieqian/core/draw/draw_engine.h"

#include <algorithm>
#include <utility>

namespace xieqian::core {

DrawEngine::DrawEngine(std::mt19937_64 rng) : rng_(std::move(rng)) {}

std::optional<std::string> DrawEngine::drawOne(const Roster &roster)
{
    const std::vector<Participant> candidates = roster.enabledParticipants();
    if (candidates.empty()) {
        return std::nullopt;
    }

    std::uniform_int_distribution<std::size_t> pick(0, candidates.size() - 1);
    return candidates[pick(rng_)].name;
}

std::vector<std::string> DrawEngine::drawMultiple(const Roster &roster, std::size_t count)
{
    std::vector<Participant> candidates = roster.enabledParticipants();
    std::shuffle(candidates.begin(), candidates.end(), rng_);

    if (count < candidates.size()) {
        candidates.resize(count);
    }

    std::vector<std::string> winners;
    winners.reserve(candidates.size());
    for (const Participant &participant : candidates) {
        winners.push_back(participant.name);
    }
    return winners;
}

}  // namespace xieqian::core
