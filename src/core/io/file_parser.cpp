#include "xieqian/core/io/file_parser.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstddef>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <utility>
#include <vector>

namespace xieqian::core {
namespace {

constexpr double kDefaultWeight = 1.0;

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

std::vector<std::string> splitTokens(const std::string &line)
{
    std::vector<std::string> tokens;
    std::string token;
    for (const char ch : line) {
        if (ch == ',' || std::isspace(static_cast<unsigned char>(ch)) != 0) {
            if (!token.empty()) {
                tokens.push_back(token);
                token.clear();
            }
        } else {
            token.push_back(ch);
        }
    }
    if (!token.empty()) {
        tokens.push_back(token);
    }
    return tokens;
}

void stripUtf8Bom(std::string &line)
{
    const std::string bom = "\xEF\xBB\xBF";
    if (line.compare(0, bom.size(), bom) == 0) {
        line.erase(0, bom.size());
    }
}

double parseWeight(const std::string &value)
{
    if (value.empty()) {
        return kDefaultWeight;
    }

    char *end = nullptr;
    const double parsed = std::strtod(value.c_str(), &end);
    if (end == value.c_str() || *end != '\0' || !std::isfinite(parsed) || parsed <= 0.0) {
        return kDefaultWeight;
    }
    return parsed;
}

bool hasCsvExtension(const std::string &filePath)
{
    std::string extension = std::filesystem::path(filePath).extension().string();
    std::transform(extension.begin(), extension.end(), extension.begin(), [](unsigned char ch) {
        return static_cast<char>(std::tolower(ch));
    });
    return extension == ".csv";
}

bool isHeaderLine(const std::string &line)
{
    return line.find("姓名") != std::string::npos;
}

}  // namespace

bool FileParser::parseFile(const std::string &filePath, Roster &roster)
{
    lastError_.clear();

    std::ifstream file(filePath);
    if (!file.is_open()) {
        lastError_ = "无法打开文件: " + filePath;
        return false;
    }

    const bool csvMode = hasCsvExtension(filePath);

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
            if (isHeaderLine(line)) {
                continue;
            }
        }

        if (csvMode) {
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
            if (fields.size() > 3) {
                participant.weight = parseWeight(fields[3]);
            }
            parsed.push_back(std::move(participant));
            continue;
        }

        for (const std::string &token : splitTokens(line)) {
            Participant participant;
            participant.name = token;
            parsed.push_back(std::move(participant));
        }
    }

    roster.clear();
    for (const Participant &participant : parsed) {
        roster.add(participant);
    }
    return true;
}

const std::string &FileParser::lastError() const
{
    return lastError_;
}

}  // namespace xieqian::core
