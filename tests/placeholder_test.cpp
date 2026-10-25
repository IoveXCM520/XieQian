#include <catch2/catch_test_macros.hpp>

TEST_CASE("Skeleton builds as C++20", "[skeleton]") {
    REQUIRE(__cplusplus >= 202002L);
}
