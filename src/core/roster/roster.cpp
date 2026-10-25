#include "xieqian/core/roster/roster.h"

#include <algorithm>
#include <iterator>
#include <utility>

namespace xieqian::core {

void Roster::add(std::string name, bool enabled)
{
    participants_.push_back(Participant{std::move(name), enabled});
}

void Roster::clear()
{
    participants_.clear();
}

void Roster::setEnabled(std::size_t index, bool enabled)
{
    participants_.at(index).enabled = enabled;
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
