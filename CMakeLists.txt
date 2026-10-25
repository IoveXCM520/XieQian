cmake_minimum_required(VERSION 3.20)
project(XieQian VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# 开启 Qt 的自动处理（MOC, UIC, RCC）
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 核心逻辑库
file(GLOB_RECURSE CORE_SOURCES "src/core/*.cpp")
add_library(xieqian_core STATIC ${CORE_SOURCES})
target_include_directories(xieqian_core PUBLIC include)

# 查找 Qt6
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2)
qt_standard_project_setup()

# UI 应用可执行文件
file(GLOB_RECURSE UI_SOURCES "src/ui/*.cpp" "src/ui/*.h")
add_executable(XieQian WIN32 ${UI_SOURCES} ui/qml.qrc)
target_link_libraries(XieQian PRIVATE xieqian_core Qt6::Quick Qt6::QuickControls2)

# 测试可执行文件 (使用系统安装的 Catch2)
find_package(Catch2 3 REQUIRED)
file(GLOB_RECURSE TEST_SOURCES "tests/*.cpp")
add_executable(xieqian_tests ${TEST_SOURCES})
target_link_libraries(xieqian_tests PRIVATE xieqian_core Catch2::Catch2WithMain)

enable_testing()
include(Catch)
catch_discover_tests(xieqian_tests)
