#include "xieqian/core/roster/roster.h"

#include <algorithm>
#include <cmath>
#include <iterator>
#include <utility>

namespace xieqian::core {

void Roster::add(Participant participant)
{
    participants_.push_back(std::move(participant));
}

void Roster::add(std::string name, bool enabled)
{
    Participant participant;
    participant.name = std::move(name);
    participant.enabled = enabled;
    participants_.push_back(std::move(participant));
}

void Roster::clear()
{
    participants_.clear();
}

void Roster::setEnabled(std::size_t index, bool enabled)
{
    participants_.at(index).enabled = enabled;
}

void Roster::setWeight(std::size_t index, double weight)
{
    participants_.at(index).weight = weight;
}

bool Roster::removeAt(std::size_t index)
{
    if (index >= participants_.size()) {
        return false;
    }

    participants_.erase(participants_.begin() + static_cast<std::ptrdiff_t>(index));
    return true;
}

std::string participantId(const Participant &participant)
{
    return participant.studentId.empty() ? participant.name : participant.studentId;
}

double dynamicWeight(const Participant &participant)
{
    const double base = std::max(0.0, participant.weight);
    const double decay = std::exp(-static_cast<double>(participant.drawCount) / 3.0);
    const double streakFactor = std::max(0.1, 1.0 - static_cast<double>(participant.streak) * 0.2);
    return base * decay * streakFactor;
}

void Roster::recordWins(const std::vector<std::string> &winnerIds)
{
    for (Participant &participant : participants_) {
        const bool won = std::find(winnerIds.begin(), winnerIds.end(), participantId(participant)) !=
                         winnerIds.end();
        if (won) {
            ++participant.drawCount;
            ++participant.streak;
        } else {
            participant.streak = 0;
        }
    }
}

void Roster::resetDrawStats()
{
    for (Participant &participant : participants_) {
        participant.drawCount = 0;
        participant.streak = 0;
    }
}

std::size_t Roster::size() const
{
    return participants_.size();
}

const Participant &Roster::at(std::size_t index) const
{
    return participants_.at(index);
}

std::vector<Participant> Roster::enabledParticipants() const
{
    std::vector<Participant> enabled;
    std::copy_if(participants_.begin(), participants_.end(), std::back_inserter(enabled),
                 [](const Participant &participant) { return participant.enabled; });
    return enabled;
}

}  // namespace xieqian::core
