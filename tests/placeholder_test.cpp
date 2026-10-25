#include <catch2/catch_test_macros.hpp>

TEST_CASE("工程骨架按 C++20 标准构建", "[skeleton]") {
    REQUIRE(__cplusplus >= 202002L);
}
