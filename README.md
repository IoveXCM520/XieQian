# 撷签（XieQian）

![Windows Build](https://github.com/IoveXCM520/XieQian/actions/workflows/build.yml/badge.svg?branch=main)

面向教育场景的现代离线抽奖系统，基于 C++20 与 Qt 6 构建，适用于课堂提问、活动抽签与名单管理等场景。

## 项目简介

撷签取“撷取签文”之意。核心抽奖、名单与历史数据管理完全离线运行；选配的 DeepSeek AI 功能用于生成测试名单与颁奖词，需要网络连接及构建期注入的 API Key。

## 核心特性

- **三种抽奖模式**：大转盘、翻牌抽签、盲盒开箱，支持单人与多人抽取。
- **抽奖策略**：随机、防连抽（NoRepeat）与按权重抽取。
- **AI 能力**：一键生成测试名单，为中奖者撰写幽默或励志的颁奖词。
- **教学工具**：随机分组与 6 列随机座位表，支持一键重新生成。
- **数据自定义存储**：名单、历史与设置自动保存；安装时可指定数据目录，适配带还原卡的机房环境，建议选择非系统盘。
- **体验细节**：宣纸水墨视觉、金箔粒子贺卡、音效与动效开关、全屏与快捷键。

## 技术栈

| 层面 | 选型 |
| --- | --- |
| 语言 | C++20 |
| UI | Qt 6.8（Qt Quick / Quick Controls 2） |
| 构建 | CMake 3.20+ |
| 网络与并发 | Qt Network、Qt Concurrent |
| 测试 | Catch2 v3 |
| 持续集成 | GitHub Actions（windows-latest） |
| 安装包 | Inno Setup |

## 构建与运行

云端构建由 GitHub Actions 完成：安装 Qt 6.8.3（MSVC 2022 64 位）与 Catch2，执行 CMake Release 配置与编译，运行 ctest，随后用 windeployqt 收集运行时依赖，最后通过 Inno Setup 生成安装包并上传构建产物。

在本机构建需要 CMake 3.20+、Qt 6.8（含 Multimedia、Network、Concurrent 模块）、MSVC 2022 与 Catch2 v3：

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest -C Release --test-dir build --output-on-failure
```

需要 AI 功能时，在配置阶段注入 DeepSeek API Key：

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release -DDEEPSEEK_API_KEY=your-key
```

密钥在编译期写入程序；未配置时其余功能不受影响，AI 操作会提示“未配置 AI 密钥”。

推送 `v*` 格式的 tag 会触发自动发布，GitHub Release 附带安装包 `XieQian-Setup-<version>.exe` 与免安装压缩包 `XieQian-Windows.zip`。

## 开源协议

本项目采用 [MIT License](LICENSE) 发布，Copyright (c) 2026 IoveXCM520。
