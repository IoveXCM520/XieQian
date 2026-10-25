#include "xieqian/core/io/csv_parser.h"

#include <cstddef>
#include <fstream>
#include <utility>
#include <vector>

namespace xieqian::core {
namespace {

std::string trim(const std::string &value)
{
    const char *whitespace = " \t\r\n";
    const auto first = value.find_first_not_of(whitespace);
    if (first == std::string::npos) {
        return {};
    }
    const auto last = value.find_last_not_of(whitespace);
    return value.substr(first, last - first + 1);
}

std::vector<std::string> splitFields(const std::string &line)
{
    std::vector<std::string> fields;
    std::string field;
    for (const char ch : line) {
        if (ch == ',') {
            fields.push_back(trim(field));
            field.clear();
        } else {
            field.push_back(ch);
        }
    }
    fields.push_back(trim(field));
    return fields;
}

void stripUtf8Bom(std::string &line)
{
    const std::string bom = "\xEF\xBB\xBF";
    if (line.compare(0, bom.size(), bom) == 0) {
        line.erase(0, bom.size());
    }
}

}  // namespace

bool CsvParser::parseFile(const std::string &filePath, Roster &roster)
{
    lastError_.clear();

    std::ifstream file(filePath);
    if (!file.is_open()) {
        lastError_ = "无法打开文件: " + filePath;
        return false;
    }

    std::vector<Participant> parsed;
    std::string line;
    std::size_t lineNumber = 0;
    bool headerChecked = false;

    while (std::getline(file, line)) {
        ++lineNumber;
        if (lineNumber == 1) {
            stripUtf8Bom(line);
        }
        line = trim(line);
        if (line.empty()) {
            continue;
        }

        if (!headerChecked) {
            headerChecked = true;
            if (line.find("姓名") != std::string::npos) {
                continue;
            }
        }

        const std::vector<std::string> fields = splitFields(line);
        if (fields.empty() || fields[0].empty()) {
            lastError_ = "第 " + std::to_string(lineNumber) + " 行缺少姓名";
            return false;
        }

        Participant participant;
        participant.name = fields[0];
        if (fields.size() > 1) {
            participant.studentId = fields[1];
        }
        if (fields.size() > 2) {
            participant.group = fields[2];
        }
        parsed.push_back(std::move(participant));
    }

    roster.clear();
    for (const Participant &participant : parsed) {
        roster.add(participant);
    }
    return true;
}

const std::string &CsvParser::lastError() const
{
    return lastError_;
}

}  // namespace xieqian::core
