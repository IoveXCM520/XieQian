#include <atomic>
#include <catch2/catch_approx.hpp>
#include <catch2/catch_test_macros.hpp>
#include <filesystem>
#include <fstream>
#include <string>
#include <system_error>

#include "xieqian/core/io/file_parser.h"
#include "xieqian/core/roster/roster.h"

using xieqian::core::FileParser;
using xieqian::core::Roster;

namespace {

class TempFile {
   public:
    TempFile(const std::string &contents, const std::string &extension = ".csv") {
        static std::atomic<int> counter{0};
        const std::string name =
            "xieqian_file_parser_" + std::to_string(counter.fetch_add(1)) + extension;
        path_ = (std::filesystem::temp_directory_path() / name).string();
        std::ofstream out(path_, std::ios::binary | std::ios::trunc);
        out.write(contents.data(), static_cast<std::streamsize>(contents.size()));
    }

    ~TempFile() {
        std::error_code error;
        std::filesystem::remove(path_, error);
    }

    TempFile(const TempFile &) = delete;
    TempFile &operator=(const TempFile &) = delete;

    const std::string &path() const {
        return path_;
    }

   private:
    std::string path_;
};

}  // namespace

TEST_CASE("File parser accepts an empty file", "[csv]") {
    const TempFile file("");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 0);
    REQUIRE(parser.lastError().empty());
}

TEST_CASE("File parser skips a header-only file", "[csv]") {
    const TempFile file("姓名,学号,分组\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 0);
}

TEST_CASE("File parser reads rows with blank lines and mixed line endings", "[csv]") {
    const TempFile file(
        "姓名,学号,分组\r\n"
        "苏婉宁,2023001,一组\r\n"
        "\r\n"
        "林砚舟,,二组\n"
        "  \n"
        "顾南乔,2023003,三组\r\n");
    Roster roster;
    roster.add("旧成员");
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 3);

    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(0).studentId == "2023001");
    REQUIRE(roster.at(0).group == "一组");
    REQUIRE(roster.at(0).enabled);

    REQUIRE(roster.at(1).name == "林砚舟");
    REQUIRE(roster.at(1).studentId.empty());
    REQUIRE(roster.at(1).group == "二组");
    REQUIRE(roster.at(1).enabled);

    REQUIRE(roster.at(2).name == "顾南乔");
    REQUIRE(roster.at(2).studentId == "2023003");
    REQUIRE(roster.at(2).group == "三组");
    REQUIRE(roster.at(2).enabled);
}

TEST_CASE("File parser accepts single-column rows", "[csv]") {
    const TempFile file("苏婉宁\n林砚舟\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 2);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(0).studentId.empty());
    REQUIRE(roster.at(0).group.empty());
    REQUIRE(roster.at(1).name == "林砚舟");
    REQUIRE(roster.at(1).studentId.empty());
    REQUIRE(roster.at(1).group.empty());
}

TEST_CASE("File parser reports a missing file without touching the roster", "[csv]") {
    const std::string path =
        (std::filesystem::temp_directory_path() / "xieqian_file_parser_missing_file.csv").string();
    Roster roster;
    roster.add("旧成员");
    FileParser parser;

    REQUIRE_FALSE(parser.parseFile(path, roster));
    REQUIRE_FALSE(parser.lastError().empty());
    REQUIRE(roster.size() == 1);
    REQUIRE(roster.at(0).name == "旧成员");
}

TEST_CASE("File parser rejects a CSV row with an empty name and keeps the roster", "[csv]") {
    const TempFile file(
        "姓名,学号,分组\n"
        ",2023001,一组\n");
    Roster roster;
    roster.add("旧成员");
    FileParser parser;

    REQUIRE_FALSE(parser.parseFile(file.path(), roster));
    REQUIRE_FALSE(parser.lastError().empty());
    REQUIRE(roster.size() == 1);
    REQUIRE(roster.at(0).name == "旧成员");
}

TEST_CASE("File parser strips a UTF-8 BOM before the header", "[csv]") {
    const std::string bom = "\xEF\xBB\xBF";
    const TempFile file(bom + "姓名,学号,分组\r\n苏婉宁,2023001,一组\r\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 1);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(0).studentId == "2023001");
    REQUIRE(roster.at(0).group == "一组");
}

TEST_CASE("File parser keeps the student id when the group is missing", "[csv]") {
    const TempFile file("姓名,学号\n苏婉宁,2023001\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 1);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(0).studentId == "2023001");
    REQUIRE(roster.at(0).group.empty());
}

TEST_CASE("File parser defaults the weight to one when the column is missing", "[csv][weight]") {
    const TempFile file(
        "姓名,学号,分组\n"
        "苏婉宁,2023001,一组\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 1);
    REQUIRE(roster.at(0).weight == Catch::Approx(1.0));
}

TEST_CASE("File parser reads the optional weight column", "[csv][weight]") {
    const TempFile file(
        "姓名,学号,分组,权重\n"
        "苏婉宁,2023001,一组,2.5\n"
        "林砚舟,2023002,二组,\n"
        "顾南乔,2023003,三组,abc\n"
        "白清让,2023004,四组,0\n"
        "温言澈,2023005,五组,-3\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 5);

    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(0).weight == Catch::Approx(2.5));

    REQUIRE(roster.at(1).name == "林砚舟");
    REQUIRE(roster.at(1).weight == Catch::Approx(1.0));

    REQUIRE(roster.at(2).name == "顾南乔");
    REQUIRE(roster.at(2).weight == Catch::Approx(1.0));

    REQUIRE(roster.at(3).name == "白清让");
    REQUIRE(roster.at(3).weight == Catch::Approx(1.0));

    REQUIRE(roster.at(4).name == "温言澈");
    REQUIRE(roster.at(4).weight == Catch::Approx(1.0));
}

TEST_CASE("File parser accepts a fractional weight with surrounding spaces", "[csv][weight]") {
    const TempFile file(
        "姓名,学号,分组,权重\n"
        "苏婉宁,2023001,一组, 0.75 \n"
        "林砚舟,2023002,二组,3\n");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 2);
    REQUIRE(roster.at(0).weight == Catch::Approx(0.75));
    REQUIRE(roster.at(1).weight == Catch::Approx(3.0));
}

TEST_CASE("Text parser splits names on spaces, commas and line breaks", "[txt]") {
    const TempFile file("苏婉宁 林砚舟,顾南乔\r\n白清让\t沈亦初\n\n温言澈\n", ".txt");
    Roster roster;
    roster.add("旧成员");
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 6);

    const char *expected[] = {"苏婉宁", "林砚舟", "顾南乔", "白清让", "沈亦初", "温言澈"};
    for (std::size_t i = 0; i < 6; ++i) {
        REQUIRE(roster.at(i).name == expected[i]);
        REQUIRE(roster.at(i).enabled);
        REQUIRE(roster.at(i).weight == Catch::Approx(1.0));
    }
}

TEST_CASE("Text parser skips a header line", "[txt]") {
    const TempFile file("姓名 学号\n苏婉宁 2023001 林砚舟\n", ".txt");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 3);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(1).name == "2023001");
    REQUIRE(roster.at(2).name == "林砚舟");
}

TEST_CASE("Text parser strips a UTF-8 BOM and ignores stray separators", "[txt]") {
    const std::string bom = "\xEF\xBB\xBF";
    const TempFile file(bom + ",,苏婉宁,,  ,林砚舟,\r\n", ".txt");
    Roster roster;
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 2);
    REQUIRE(roster.at(0).name == "苏婉宁");
    REQUIRE(roster.at(1).name == "林砚舟");
}

TEST_CASE("Text parser accepts an empty file", "[txt]") {
    const TempFile file("", ".txt");
    Roster roster;
    roster.add("旧成员");
    FileParser parser;

    REQUIRE(parser.parseFile(file.path(), roster));
    REQUIRE(roster.size() == 0);
}
