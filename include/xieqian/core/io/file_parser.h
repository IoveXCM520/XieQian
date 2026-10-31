#pragma once

#include <string>

#include "xieqian/core/roster/roster.h"

namespace xieqian::core {

class FileParser
{
public:
    // 按扩展名选择解析方式：
    // - .csv：解析 "姓名,学号(可选),分组(可选),权重(可选)"，空行与表头会被跳过，
    //   权重缺失、无法解析或不是正数时回落为 1.0；
    // - 其它（.txt 等）：把空格、制表符、逗号、换行都当作分隔符，每个片段视为一个姓名。
    // 解析成功后以文件内容替换 roster，失败时保留 roster 原状。
    bool parseFile(const std::string &filePath, Roster &roster);

    [[nodiscard]] const std::string &lastError() const;

private:
    std::string lastError_;
};

}  // namespace xieqian::core
