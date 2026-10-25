---
name: cpp-conventions
description: 撷签项目 C++ 开发规范。编写、修改或审查本项目任何 C++ 代码时使用，约束内存管理、依赖隔离、错误处理、命名、头文件与常量。
---

# 撷签项目 C++ 开发规范
1. 内存管理：绝对禁止裸 new/delete，必须使用 RAII（std::unique_ptr, std::shared_ptr）。
2. 依赖隔离：src/core/ 目录下的代码是纯 C++ 逻辑，严禁包含任何 UI 框架头文件或系统特定 API（如 <windows.h>）。
3. 错误处理：优先使用返回值表达错误（如 std::optional 或自定义 Result），尽量避免抛出异常。
4. 命名规范：类型（类/结构体/枚举）使用 PascalCase；函数和局部变量使用 camelCase；私有成员变量前缀加 m_。
5. 头文件：一律使用 #pragma once。
6. 常量：优先使用 constexpr，杜绝魔法数字。
