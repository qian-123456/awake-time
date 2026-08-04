# Awake Time 项目规则

- 当前实现、测试、发布产物和 `PROJECT_STATE.md` 是外部仓库真相源；Coding Wiki 只保留导航指针。
- 默认读取 Coding Wiki 根规则、本文件和 `PROJECT_STATE.md`；架构、教程、视频和历史按任务查询。
- 保持本地 macOS 菜单栏时钟边界；涉及通知、LaunchAgent、系统权限或安装时先做只读探针。
- 公开 v1.0.0 与 feature branch 必须分开描述，不能把未发布代码写成 release 能力。
- 改动后运行 `swift test` 或项目已有测试入口；普通实现历史由 Git 承担，重大 decision、incident、migration、correction 或 release 才建立独立记录。
