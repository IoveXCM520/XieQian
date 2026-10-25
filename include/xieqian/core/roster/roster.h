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
};

class Roster
{
public:
    void add(Participant participant);
    void add(std::string name, bool enabled = true);
    void clear();

    void setEnabled(std::size_t index, bool enabled);

    [[nodiscard]] std::size_t size() const;
    [[nodiscard]] const Participant &at(std::size_t index) const;
    [[nodiscard]] std::vector<Participant> enabledParticipants() const;

private:
    std::vector<Participant> participants_;
};

}  // namespace xieqian::core
