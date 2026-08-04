---
verified_at: 2026-08-04T12:34:00+08:00
verified_commit: 3695490
verified_against:
  - git:3695490
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

提供以醒来时刻为个人 `00:00` 的本地 macOS 菜单栏时钟。公开 v1.0.0 已有发布包；当前分支 `codex/add-bedtime-reminders` 包含尚未进入 release 的睡眠提醒功能。

## 当前有效能力

- 时钟、昼夜图标、个人日界线、习惯睡眠时长和可调睡觉提醒已在当前源码中实现。
- 提醒设置有持久化隔离；构建、测试和发布脚本保留在仓库，视频 demo 是按需资料。

## 活跃风险与 Unknown

- feature branch 尚未等同于公开 release；通知权限、不同睡眠时长和升级后的宿主行为需要真实 macOS 验收。
- 系统服务、提醒权限和当前安装版本属于动态状态，本页不授予系统操作权限。

## 精确下一步

在不改变当前分支范围的前提下运行完整 `swift test` 和 release 构建，验证提醒持久化/昼夜切换，再决定是否创建正式 release。

## 验证入口

`swift test`、`Scripts/build-release.sh`；涉及通知或安装时先读取系统权限和当前包的只读状态。
