# Contributing to Awake Time

感谢参与。Awake Time 是一个本地优先的 macOS 工具，贡献应尽量保持计时可信、权限最小和数据本地化。

## 开始之前

1. 阅读 [README](README.md) 和 [当前状态](PROJECT_STATE.md)。
2. 确认 macOS 14+、Swift 工具链和 Xcode 可用。
3. 不要提交 `build/`、`.build/`、个人数据、通知样本或任何凭证。

## 修改流程

1. 为一个清晰的变更创建分支。
2. 先写或更新单元测试，再修改实现。
3. 运行：

   ```bash
   swift test
   ./Scripts/build-app.sh
   ```

   该命令会覆盖 `/Applications/Awake Time.app` 并启动新版本。仅生成本地构建包时，使用
   `AWAKE_TIME_SKIP_INSTALL=1 ./Scripts/build-app.sh`。

4. 检查 `git diff --check`，确认没有绝对本机路径、私人邮箱或秘密。
5. Pull request 说明行为变化、权限影响、测试结果和未解决风险。

## 设计边界

- 计时必须使用绝对经过时长，不能用本地日期差替代。
- 手动修正不能被自动模式或每周计划覆盖。
- 新增系统权限必须解释用途，并提供关闭或降级路径。
- 不要把 Ice 代码复制到本仓库；需要菜单栏整理时引用 Ice 官方项目。
