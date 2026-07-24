---
verified_at: 2026-07-24T10:46:00+08:00
verified_against:
  - README.md
  - Package.swift
  - Sources/AwakeTimeApp/StatusBarController.swift
  - Tests/AwakeTimeKitTests
review_after: 2026-08-07
---

# Awake Time 当前项目状态

## 当前阶段

`第一版可用，已准备公开发布`

## 当前结论

Awake Time 是一个 SwiftUI + AppKit 的 macOS 14+ 菜单栏应用。它把用户记录的醒来时刻视为个人一天的
`00:00`，按真实经过时长累计，并继续显示 `24:00`、`25:00` 等不封顶时间。数据只使用 SwiftData 和
系统偏好保存在本机。

状态栏使用 macOS 原生 `sun.max.fill` 模板图标和等宽数字，显示为“太阳图标 + HH:mm”；尚未开始时为
“太阳图标 + --:--”。

## 已验证能力

- 手动设定、 自适应解锁、点击开始、每周预设四种模式；切换模式不会自动把当前计时归零；
- 手动修正对当天具有最高优先级；历史记录可编辑和删除；删除当前记录后回到上一条有效记录；
- 计时跨自然日、时区和夏令时变化时按绝对经过时长计算；每分钟边界刷新；
- 自适应模式记录睡眠、唤醒和会话恢复事件，学习期至少五条可信记录，通知支持确认、询问和撤销；
- SwiftData 本地历史、UserDefaults 偏好、系统通知和 `SMAppService` 登录启动；
- 简体中文和英文界面；
- `swift test`：11 项测试通过；正式构建和代码签名验证通过。

## 当前边界

- 应用不能替换 macOS 系统时钟，只能增加自己的菜单栏项目；
- 自适应模式只能根据 Mac 事件推断，不能识别人的真实睡眠状态；
- 应用未运行时无法可靠捕获睡眠、唤醒和解锁顺序；
- 项目不捆绑 Ice，也不复制 Ice 的代码。Ice 作为独立的菜单栏布局工具使用。

## 下一步

1. 在真实 Mac 上继续验证睡眠/唤醒、登录启动、通知拒绝和不同菜单栏空间；
2. 收集公开用户反馈后再决定是否增加“一键打开 Ice”或菜单栏诊断入口；
3. 不在未明确需求前引入屏幕录制权限、Accessibility 权限或 macOS 私有窗口 API。

## 相关页面

- [[awake-time/wiki/index|Awake Time Wiki 索引]]
- [[awake-time/wiki/architecture|架构与权限边界]]
- [[awake-time/wiki/workflows/ice-menu-bar|与 Ice 配合整理菜单栏]]
- [[awake-time/wiki/log|演化日志]]
