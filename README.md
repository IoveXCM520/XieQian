# 撷签（XieQian）

![Windows Build](https://github.com/IoveXCM520/XieQian/actions/workflows/build.yml/badge.svg?branch=main)

为课堂提问与聚会抽签准备的 Windows 桌面应用：转盘先定答案再旋转，名单、历史与自定义转盘都留在本机，断网也能用。基于 C++20 与 Qt 6 构建，界面采用 iOS 设置页的分组卡片风格。

当前版本：**v1.1.1** ｜ 平台：Windows 10 / 11（x64） ｜ 许可：MIT

## 抽签

- **大转盘**：先从名单里定下结果，再旋转到对应扇区，指针停的位置始终就是选中的人。
- **权重扇区**：扇区宽度按权重绘制，看到的宽窄就是实际概率。
- **动态权重**（可在开发者控制台开启）：被选中越多，下一次出现得越少。
- **快捷键**：空格开始抽签，Esc 关闭结果卡。

## 名单

- 导入 CSV / TXT，或让内置 AI 通道识别一张名单截图。
- 逐人启用 / 停用，也可以把某人移出名单。
- 按姓名去重，重复导入不会让同一个人占两个位置。
- 名单页可查看每个人的被选中次数与连续次数。

## 自定义转盘

- 命名保存多只转盘，在主页标签条上随时切换。
- 长按或右键删除；删除转盘不影响已经产生的历史。

## 历史

- 记录每一次结果与时间，可一键抹除。
- 自定义转盘的结果也会写入历史。

## 工具

- **高级计算器**：括号、乘方、三角与对数、科学计数法、省略乘号的写法（如 `2x`、`3(x+1)`）都支持；半截表达式会自动补齐。
- **函数图像**：直角坐标、参数方程与隐式方程，带描点生长动画；也可以写一句话让 AI 转换成表达式。

## 数据

- 全部状态保存在一个本地 `data.json`：名单、历史、自定义转盘、偏好设置与 AI 配置。
- 支持导出备份与从备份恢复。
- 安装时可指定数据目录，适配带还原卡的机房环境（建议选非系统盘）。
- 写入做了 220ms 合并、单线程异步落盘与临时文件原子替换，避免卡顿与半截文件。

## AI 配置

- 文本类能力（函数表达式转换等）使用你在「设置 → AI 配置」里填写的 Key，支持任何 OpenAI 兼容接口，默认填 `https://api.deepseek.com`。
- 图片识别（名单截图、成绩单）走应用内置通道，不消耗你自己的 Key。
- Key 只保存在本机 `data.json` 中，不写入仓库、不上传。

## 下载

前往 [Releases](https://github.com/IoveXCM520/XieQian/releases/latest) 取最新版本，提供两个产物：

| 文件 | 说明 |
| --- | --- |
| `XieQian-Setup-x.y.z.exe` | 安装包，安装时可选择数据目录 |
| `XieQian-Windows.zip` | 免安装压缩包，解压即用 |

## 从源码构建

需要 CMake 3.20+、Qt 6.8（含 Quick、QuickControls2、Widgets、Multimedia、Network、Concurrent）、MSVC 2022 与 Catch2 v3：

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release
ctest -C Release --test-dir build --output-on-failure
```

云端由 GitHub Actions（windows-latest）完成同一套流程：安装 Qt 与 Catch2 → CMake Release 构建 → ctest → windeployqt → Inno Setup 打包；推送 `v*` 标签会同时生成 GitHub Release。

## 项目结构

```
include/xieqian/core/   纯 C++ 核心接口（抽签引擎、名单、文件解析）
src/core/               核心实现，不依赖 Qt
src/ui/                 Qt 桥接层（BackendBridge、AiManager）
ui/qml/                 Qt Quick 界面（Main.qml、pages/、components/）
tests/                  Catch2 单元测试
```

## 已知限制

- 只在 Windows 10 / 11 x64 上验证过，macOS 与 Linux 未测试。
- 多人抽取与颁奖词生成目前只有后端实现，界面暂未开放。
- 设置页的「音效」开关会保存偏好，但还没接上音频播放。

## 许可

本项目采用 [MIT License](LICENSE) 发布，Copyright (c) 2026 IoveXCM520。
