---
verified_at: 2026-08-05T00:02:31+08:00
verified_commit: 99f61ee
verified_against:
  - git:99f61ee
  - installed-app
  - Sources/
  - Tests/
  - Package.swift
  - Scripts/
review_after: 2026-08-18
supersedes:
  - docs/archive/project-state-before-memory-refactor-2026-08-04.md
---

# Awake Time 当前状态

## 目标与阶段

提供以醒来时刻为个人 `00:00` 的本地 macOS 菜单栏时钟。公开 v1.0.0 已有发布包；当前源码包含尚未进入 release 的睡眠提醒、预计睡觉时间、历史返回修复和本地时区自适应。

## 当前有效能力

- 时钟、昼夜图标、个人日界线、习惯睡眠时长、预计睡觉时间和可调睡觉提醒已在当前源码中实现。
- 每周计划、日期显示和逻辑日键跟随当前本地时区；应用运行中检测到时区变化时会立即重算。
- 紧凑菜单历史页提供独立返回入口，不依赖 macOS 窗口工具栏。
- 提醒设置有持久化隔离；构建、测试和发布脚本保留在仓库，视频 demo 是按需资料。

## 活跃风险与 Unknown

- 当前源码和尚未发布的 `main` 均不能写成公开 v1.0.0 能力；通知权限和时区实时切换仍需要真实 macOS 验收。
- 系统服务、提醒权限和当前安装版本属于动态状态，本页不授予系统操作权限。

## 精确下一步

合入 `main` 后验证运行中时区切换，再生成新的 universal release 包并决定后续版本号。

## 验证入口

`swift test`、`Scripts/build-release.sh`；涉及通知或安装时先读取系统权限和当前包的只读状态。
