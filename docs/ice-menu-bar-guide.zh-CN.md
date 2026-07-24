# Awake Time 与 Ice：菜单栏空间整理教程

本教程针对一种很容易误判的情况：Awake Time 正在运行，但菜单栏太拥挤，图标被折叠或没有出现在肉眼容易看到的位置。

Ice 的官方仓库：<https://github.com/jordanbaird/Ice>

## 1. 先确认 Awake Time 本身已安装

1. 打开“访达”。
2. 左侧点击“应用程序”。
3. 确认存在 `Awake Time.app`。
4. 双击它。若出现控制窗口，说明应用已启动；关闭窗口不会退出菜单栏后台进程。
5. 菜单栏项目默认显示太阳图标和时间，例如 `☀ 01:49`。

如果你是从源码构建，先在项目目录执行：

```bash
./Scripts/build-app.sh
ditto "build/Awake Time.app" "/Applications/Awake Time.app"
open "/Applications/Awake Time.app"
```

## 2. 安装并固定 Ice

1. 从 [Ice 官方 GitHub Releases](https://github.com/jordanbaird/Ice/releases) 下载最新版。
2. 将 `Ice.app` 拖入“应用程序”。不要长期从下载目录或 App Translocation 临时路径运行。
3. 双击“应用程序”里的 Ice。

Ice 运行后，菜单栏会出现 Ice 自己的图标。它可以继续后台运行；隐藏其他项目不等于退出那些应用。

## 3. 处理 Ice 的权限提示

Ice 的 `Menu Bar Layout` 需要读取菜单栏布局。按下面步骤操作：

1. 打开 Ice 设置。
2. 进入 `Advanced`（高级）。
3. 找到屏幕录制权限项，点击 `Grant Permission`（授予权限）。
4. 系统设置会进入“隐私与安全性”。打开“屏幕与系统音频录制”。
5. 在列表中开启 Ice。
6. 按系统提示退出并重新打开 Ice。

这是给 Ice 的系统隐私权限，不是 Awake Time 的权限。若你不想给 Ice 屏幕录制权限，可以继续使用 Ice 的基础折叠能力，但 `Menu Bar Layout` 可能无法列出所有项目。

## 4. 把 Awake Time 放到可见区

1. 点击菜单栏中的 Ice 图标。
2. 打开 `Menu Bar Layout`。
3. 找到 `Awake Time`，或找到它当前显示的时间（例如 `01:49`）。
4. 把它拖到 `Visible` 区域。
5. 如需把不常用项目收起来，把其他项目拖到 `Hidden`；需要始终隐藏的项目拖到 `Always Hidden`。
6. 关闭设置，再观察菜单栏是否出现太阳图标和时间。

不要把 `Command` 拖动当作唯一方法：只有项目已经可见、且 Ice 已经能识别它时，Command 拖动才有意义。第一次找不到 Awake Time 时，应优先用 `Menu Bar Layout`。

## 5. 如果 Awake Time 完全不在列表中

按顺序排查，不要退出一堆无关应用：

1. 在“活动监视器”或终端确认 Awake Time 正在运行：

   ```bash
   pgrep -fl AwakeTime
   ```

2. 重新启动 Awake Time：

   ```bash
   open "/Applications/Awake Time.app"
   ```

3. 重新打开 Ice 的 `Menu Bar Layout`。
4. 确认 Ice 已经位于“应用程序”，而不是下载目录的临时转移路径。
5. 确认 Ice 的“屏幕与系统音频录制”权限仍然开启。
6. 仍然找不到时，先把 Ice 退出再从“应用程序”重新打开；不要删除 Awake Time 的本地数据。

## 6. 菜单栏仍然太挤怎么办

- 把长文字型项目移到 `Hidden`，只保留太阳图标和时间在 `Visible`。
- 把不需要经常点击的项目移到 `Always Hidden`。
- 保留系统时间或控制中心时，给 Awake Time 预留一个连续可见位置。
- 不要通过退出应用解决“只想隐藏图标”的问题；退出应用会同时停止它的后台工作。
- 如果你使用刘海屏或多个显示器，每个菜单栏的有效空间可能不同，需分别观察当前显示器。

## 7. 如何判断是哪一层出了问题

| 现象 | 结论 | 处理 |
| --- | --- | --- |
| 控制窗口能打开，Ice 列表没有项目 | Awake Time 在运行，Ice 尚未识别 | 检查 Ice 位置和权限，重开布局页 |
| Ice 列表有项目，但 Awake Time 在 Hidden | 布局设置导致不可见 | 移到 `Visible` |
| 菜单栏只有时间，没有太阳图标 | 使用了旧版 Awake Time | 从源码重新构建并替换“应用程序”里的版本 |
| 双击后窗口出现但菜单栏不见 | 状态栏空间/布局问题，不是计时逻辑问题 | 用本教程排查 Ice |
| 应用完全没有进程 | 应用没有启动或被退出 | 从“应用程序”重新打开，不要先改系统时区 |

## 8. 为什么 Awake Time 不直接集成 Ice

Awake Time 可以可靠控制自己的 `NSStatusItem`，但 macOS 没有公开 API 让普通应用任意隐藏其他应用的菜单栏项目。Ice 还涉及屏幕录制、全局事件和窗口层能力。

因此推荐保持分工：

- Awake Time：醒时、累计计时、历史和自适应判断；
- Ice：菜单栏项目的可见区、折叠区和布局。

两者并行运行即可，不需要共享数据，也不需要 Awake Time 获得 Ice 的隐私权限。

## 相关链接

- [Awake Time 项目 README](../README.md)
- [Ice 官方仓库](https://github.com/jordanbaird/Ice)
- [Ice Releases](https://github.com/jordanbaird/Ice/releases)
