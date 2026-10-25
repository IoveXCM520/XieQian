#pragma once

#include <string>

#include "xieqian/core/roster/roster.h"

namespace xieqian::core {

class CsvParser
{
public:
    // 解析 "姓名,学号(可选),分组(可选),权重(可选)" 格式的 CSV。空行与表头会被跳过，
    // 权重缺失、无法解析或不是正数时回落为 1.0；
    // 解析成功后以文件内容替换 roster，失败时保留 roster 原状。
    bool parseFile(const std::string &filePath, Roster &roster);

    [[nodiscard]] const std::string &lastError() const;

private:
    std::string lastError_;
};

}  // namespace xieqian::core
