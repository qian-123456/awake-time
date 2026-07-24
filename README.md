# Awake Time

Awake Time 是一个原生 macOS 菜单栏时钟：用户记录的醒来时刻就是个人一天的 `00:00`。
它按真实经过时长累计，不按地球自转规定的自然日归零，所以可以显示 `24:00`、`25:00` 以及更长时间。

> 本项目只面向本地 Mac。它不会修改 macOS 系统时钟，也不会把数据上传到云端。

## 你会得到什么

- 菜单栏显示原生太阳图标和醒时，例如 `☀ 04:37`；尚未开始时显示 `☀ --:--`。
- 四种计时模式：手动设定、自适应解锁、点击开始、每周预设。
- 手动修正、历史编辑/删除、删除当前记录后回退到上一条有效记录。
- 睡眠、唤醒、会话恢复和首次解锁的本地观察；自适应模式会先询问，积累至少 5 条可信记录后才可能自动判断。
- 通知确认、低置信度询问，以及高置信度自动归零后的撤销操作。
- 简体中文/英文界面、通知设置和登录启动开关。

## 系统要求

- macOS 14 或更高版本
- Apple Silicon 或 Intel Mac

## 直接下载安装（不需要 Xcode）

1. 打开 [Releases 页面](https://github.com/qian-123456/awake-time/releases/latest)。
2. 在 `Assets` 中下载 `Awake-Time-1.0.0-universal.zip`。不要下载 GitHub 自动生成的 `Source code (zip)`，那是源码，不是可直接打开的应用。
3. 双击 ZIP 解压，得到 `Awake Time.app`。
4. 把 `Awake Time.app` 拖入“应用程序”。
5. 第一次打开时，按住 Control 点击应用并选择“打开”。如果系统仍然拦截，进入“系统设置”→“隐私与安全性”，找到 Awake Time 的提示并点击“仍要打开”。
6. 完成首次引导。之后直接点击菜单栏里的太阳图标和时间。

### 看到“Apple 无法验证 Awake Time”怎么办

当前下载包使用本地临时签名，没有 Apple Developer ID 公证，因此普通用户第一次安装时可能看到：

> Apple 无法验证“Awake Time”是否包含可能危害 Mac 安全或泄漏隐私的恶意软件。

这表示 Apple 无法验证开发者身份和公证记录，不表示 macOS 已经在应用中检测到恶意软件。请使用 macOS 提供的单应用放行方式，不要关闭全局安全检查：

1. 先把 `Awake Time.app` 拖入“应用程序”。
2. 尝试打开一次，在警告窗口中点击“好”。
3. 打开“系统设置”→“隐私与安全性”。
4. 向下找到“已阻止使用 Awake Time”提示，点击“仍要打开”。
5. 使用 Touch ID 或 Mac 登录密码确认。
6. 在随后出现的窗口中再次点击“打开”。

如果没有看到“仍要打开”，请先从“应用程序”再次尝试打开 Awake Time，然后立即返回“隐私与安全性”页面。通常每个新下载版本只需确认一次，不需要终端或 Xcode。

要从根本上消除这个提示，发布者必须加入 Apple Developer Program，使用 `Developer ID Application` 证书签名并提交 Apple 公证。DMG、ZIP、Homebrew、公开源代码或 SHA-256 校验都不能替代 Apple 公证。完成公证前，本 Release 更适合作为公开测试版本。

Awake Time 不会联网，醒来历史和设置只保存在本机。源代码完全公开，Release 同时提供 SHA-256 校验文件用于确认下载内容没有发生变化。

## 开发者从源码构建

源码构建需要 Xcode 16 或与 macOS 14 匹配的 Swift 工具链。

1. 安装 Xcode，并在“终端”确认工具链可用：

   ```bash
   swift --version
   ```

2. 克隆仓库并进入目录：

   ```bash
   git clone https://github.com/qian-123456/awake-time.git
   cd awake-time
   ```

3. 运行测试：

   ```bash
   swift test
   ```

4. 构建可双击的应用包：

   ```bash
   ./Scripts/build-app.sh
   ```

5. 把生成的 `build/Awake Time.app` 拖到“应用程序”，然后双击打开。也可以执行：

   ```bash
   open "build/Awake Time.app"
   ```

6. 首次打开时完成引导。需要可靠捕获睡眠/唤醒/解锁事件时，建议把应用放在“应用程序”中，并开启“登录时启动”。

## 第一次使用

1. 打开 Awake Time；控制窗口会显示当前累计时间，菜单栏项目同时开始运行。
2. 没有记录时，点击“开始新一天”，当前时刻成为 `00:00`；也可以点击“设定醒来时间”选择过去的具体时间。
3. 在“计时模式”中选择一种模式。切换模式不会立即改变当前计时。
4. 若选择“自适应解锁”，首次候选事件会要求确认，并建议开启通知；至少积累 5 条已确认/手动记录后，系统才会尝试个性化判断。
5. 若选择“每周预设”，在“设置…”中分别启用周一至周日的时间。应用晚启动时会按最近一次已生效的预设补算，重复逻辑日期不会重复创建记录。

## 菜单栏空间不足：与 Ice 配合

Awake Time 只能管理自己的菜单栏项目；隐藏其他应用的图标不是 macOS 公开 API 能完成的事情。推荐把 Ice 作为独立工具，按照完整教程操作：

**[与 Ice 配合整理菜单栏（逐步教程）](docs/ice-menu-bar-guide.zh-CN.md)**

Ice 项目主页和下载入口：<https://github.com/jordanbaird/Ice>

关键原则：不要为了隐藏菜单栏图标而退出应用；使用 Ice 的 `Menu Bar Layout` 将项目放入 `Visible`、`Hidden` 或 `Always Hidden`。如果 Awake Time 从未出现，先不要尝试按住 Command 拖动，直接使用布局页面搜索和移动。

## 常见问题

### 双击后没有看到菜单栏项目

确认应用位于“应用程序”，再重新打开。Awake Time 是隐藏 Dock 图标的菜单栏应用，控制窗口和菜单栏项目是两个不同入口。若菜单栏空间不足，使用 [Ice 教程](docs/ice-menu-bar-guide.zh-CN.md) 将它移到 `Visible`。

### 为什么时间超过 24 小时不归零

这是设计目标：计时从醒来记录开始，直到下一条有效醒来记录产生。`AwakeClockEngine` 使用 `Date` 的绝对时间差，不使用本地日历差值。

### 自适应模式为什么还会询问

前 5 条可信样本是学习期；之后还要同时比较同类星期的醒来时间、偏差范围和睡眠时长。低置信度事件继续询问，避免把短暂解锁误判成新的一天。

### Ice 是否已经集成到 Awake Time

没有。两者分工更安全：Awake Time 负责个人醒时，Ice 负责菜单栏布局。项目没有复制 Ice 的 GPL-3.0 代码，也不要求 Awake Time 获取屏幕录制权限。

## 开发结构

```text
Sources/AwakeTimeKit/       纯计时、日程和自适应推断逻辑
Sources/AwakeTimeApp/       SwiftUI 界面、AppKit 状态栏、通知、登录启动
Tests/AwakeTimeKitTests/    计时、日程和推断单元测试
Resources/                  应用包 Info.plist
Scripts/build-app.sh        构建、打包和本地签名
docs/                       面向用户的操作教程
```

## 隐私与权限

- 历史和设置仅保存在本机；没有账户、云同步、Apple Health、iPhone 或 Apple Watch 接入。
- 自适应模式只监听系统提供的 Mac 睡眠、唤醒和会话恢复通知。
- 通知权限和登录启动均可在设置中关闭。
- 项目本身不需要屏幕录制权限。只有使用 Ice 的菜单栏布局识别功能时，才由用户单独决定是否授予 Ice 该权限。

## 许可证

本项目采用 [MIT License](LICENSE)。Ice 是独立的 GPL-3.0 开源项目，详见其[官方仓库](https://github.com/jordanbaird/Ice)；本项目不捆绑或复制 Ice 代码。
