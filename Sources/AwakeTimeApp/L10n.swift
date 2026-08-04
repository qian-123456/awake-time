import AwakeTimeKit
import Foundation

enum L10n {
  static func text(_ key: String, _ language: AppLanguage) -> String {
    let table = language.resolved == .simplifiedChinese ? zh : en
    return table[key] ?? en[key] ?? key
  }

  static func format(_ key: String, _ language: AppLanguage, _ arguments: CVarArg...) -> String {
    String(format: text(key, language), arguments: arguments)
  }

  static func mode(_ mode: ClockMode, _ language: AppLanguage) -> String {
    text("mode.\(mode.rawValue)", language)
  }

  static func source(_ source: WakeSource, _ language: AppLanguage) -> String {
    text("source.\(source.rawValue)", language)
  }

  static func weekday(_ weekday: Weekday, _ language: AppLanguage) -> String {
    text("weekday.\(weekday.rawValue)", language)
  }

  static func duration(_ interval: TimeInterval, _ language: AppLanguage) -> String {
    let totalMinutes = Int(interval) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 && minutes > 0 {
      return format("duration.hoursMinutes", language, hours, minutes)
    }
    if hours > 0 {
      return format("duration.hours", language, hours)
    }
    return format("duration.minutes", language, minutes)
  }

  private static let zh: [String: String] = [
    "app.name": "Awake Time",
    "status.notStarted": "尚未开始",
    "clock.awakeSince": "醒来时间 %@",
    "clock.estimatedBedtime": "预计睡觉时间 %@",
    "clock.continues": "时间会持续累加，直到开始新一天",
    "action.startDay": "开始新一天",
    "action.setWake": "设定醒来时间",
    "action.apply": "应用",
    "action.cancel": "取消",
    "action.confirm": "是，开始新一天",
    "action.notNow": "不是这次",
    "action.undo": "撤销",
    "action.settings": "设置…",
    "action.quit": "退出 Awake Time",
    "action.delete": "删除",
    "action.done": "完成",
    "action.back": "返回",
    "section.mode": "计时模式",
    "section.recent": "最近记录",
    "section.current": "当前",
    "section.general": "通用",
    "section.schedule": "每周计划",
    "section.history": "历史",
    "section.about": "关于",
    "mode.manual": "手动设定",
    "mode.adaptiveUnlock": "自适应解锁",
    "mode.clickToStart": "点击开始",
    "mode.weeklySchedule": "每周预设",
    "source.manual": "手动设定",
    "source.quickStart": "点击开始",
    "source.adaptiveConfirmed": "确认的解锁",
    "source.adaptiveAutomatic": "自适应判断",
    "source.weeklySchedule": "每周计划",
    "adaptive.question": "这是新的一天吗？",
    "adaptive.detail": "检测到 Mac 在睡眠后恢复。确认后，解锁时刻会成为 00:00。",
    "adaptive.autoTitle": "已开始新的一天",
    "adaptive.autoBody": "Awake Time 根据你的个人作息，将本次解锁设为 00:00。",
    "adaptive.confirmTitle": "这是新的一天吗？",
    "adaptive.confirmBody": "确认后，本次解锁时刻将成为 Awake Time 的 00:00。",
    "settings.language": "语言",
    "settings.systemLanguage": "跟随系统",
    "settings.chinese": "简体中文",
    "settings.english": "English",
    "settings.sleepDuration": "习惯睡眠时长",
    "settings.sleepDurationValue": "%.1f 小时",
    "settings.sleepDurationHelp": "醒来后经过可用时间的一半，菜单栏图标会切换为月亮。",
    "settings.nightStartsAt": "%@ 切换为夜晚",
    "settings.sleepReminder": "睡觉提醒",
    "settings.sleepReminderLeadTime": "提前 %@",
    "settings.sleepReminderAt": "在醒来计时 %@ 时提醒",
    "settings.sleepReminderHelp": "根据醒来时间和习惯睡眠时长安排系统通知。",
    "sleepReminder.title": "该睡觉了",
    "sleepReminder.body.future": "距离计划入睡时间还有 %@。",
    "sleepReminder.body.now": "已到计划入睡时间。",
    "duration.hoursMinutes": "%d 小时 %d 分钟",
    "duration.hours": "%d 小时",
    "duration.minutes": "%d 分钟",
    "settings.login": "登录后自动运行",
    "settings.loginHelp": "自适应模式只有在应用运行时才能可靠捕获睡眠和解锁。",
    "settings.notification": "通知",
    "settings.notificationHelp": "用于睡觉提醒、醒来确认和自动归零后的撤销操作。",
    "settings.enableNotifications": "允许通知",
    "settings.openNotificationSettings": "打开系统通知设置",
    "settings.scheduleHelp": "到点自动开始；如果应用晚启动，会按最近一次计划时间补算。",
    "settings.noSchedule": "尚未启用任何日期",
    "history.empty": "还没有醒来记录",
    "history.edit": "编辑记录",
    "history.corrected": "已修正",
    "history.confidence": "置信度 %d%%",
    "history.deleteConfirm": "删除这条醒来记录？",
    "history.deleteDetail": "当前时间将回退到上一条有效记录。",
    "onboarding.title": "让醒来成为 00:00",
    "onboarding.body": "Awake Time 在菜单栏显示从你醒来后经过的时间。所有记录只保存在这台 Mac。",
    "onboarding.login": "登录后自动运行",
    "onboarding.loginBody": "开启后才能持续捕获 Mac 的睡眠、唤醒和首次解锁。你之后可在设置中关闭。",
    "onboarding.continue": "开始使用",
    "error.future": "醒来时间不能晚于现在。",
    "error.save": "记录无法保存，请重试。",
    "error.login": "无法更改登录启动设置：%@",
    "about.description": "从醒来开始计算属于你的一天。",
    "about.privacy": "本地运行，不上传任何数据。",
    "weekday.1": "周日",
    "weekday.2": "周一",
    "weekday.3": "周二",
    "weekday.4": "周三",
    "weekday.5": "周四",
    "weekday.6": "周五",
    "weekday.7": "周六",
  ]

  private static let en: [String: String] = [
    "app.name": "Awake Time",
    "status.notStarted": "Not started",
    "clock.awakeSince": "Awake since %@",
    "clock.estimatedBedtime": "Estimated bedtime %@",
    "clock.continues": "Time keeps counting until you start a new day",
    "action.startDay": "Start New Day",
    "action.setWake": "Set Wake Time",
    "action.apply": "Apply",
    "action.cancel": "Cancel",
    "action.confirm": "Yes, Start New Day",
    "action.notNow": "Not This Time",
    "action.undo": "Undo",
    "action.settings": "Settings…",
    "action.quit": "Quit Awake Time",
    "action.delete": "Delete",
    "action.done": "Done",
    "action.back": "Back",
    "section.mode": "Clock Mode",
    "section.recent": "Recent Records",
    "section.current": "Current",
    "section.general": "General",
    "section.schedule": "Weekly Schedule",
    "section.history": "History",
    "section.about": "About",
    "mode.manual": "Set Manually",
    "mode.adaptiveUnlock": "Adaptive Unlock",
    "mode.clickToStart": "Click to Start",
    "mode.weeklySchedule": "Weekly Schedule",
    "source.manual": "Manual",
    "source.quickStart": "Click to Start",
    "source.adaptiveConfirmed": "Confirmed Unlock",
    "source.adaptiveAutomatic": "Adaptive",
    "source.weeklySchedule": "Weekly Schedule",
    "adaptive.question": "Is this a new day?",
    "adaptive.detail":
      "Your Mac became active after sleeping. Confirm to make the unlock time 00:00.",
    "adaptive.autoTitle": "A new day has started",
    "adaptive.autoBody": "Awake Time used your personal pattern and set this unlock as 00:00.",
    "adaptive.confirmTitle": "Is this a new day?",
    "adaptive.confirmBody": "Confirm to make this unlock the 00:00 of your Awake Time day.",
    "settings.language": "Language",
    "settings.systemLanguage": "System Language",
    "settings.chinese": "简体中文",
    "settings.english": "English",
    "settings.sleepDuration": "Usual Sleep Duration",
    "settings.sleepDurationValue": "%.1f hours",
    "settings.sleepDurationHelp": "The menu bar switches to a moon after half of your available time has passed.",
    "settings.nightStartsAt": "Night at %@",
    "settings.sleepReminder": "Bedtime Reminder",
    "settings.sleepReminderLeadTime": "%@ early",
    "settings.sleepReminderAt": "Remind at awake time %@",
    "settings.sleepReminderHelp": "Schedules a system notification from your wake time and usual sleep duration.",
    "sleepReminder.title": "Time for bed",
    "sleepReminder.body.future": "Your planned bedtime is in %@.",
    "sleepReminder.body.now": "It is your planned bedtime.",
    "duration.hoursMinutes": "%d hr %d min",
    "duration.hours": "%d hr",
    "duration.minutes": "%d min",
    "settings.login": "Launch at Login",
    "settings.loginHelp":
      "Adaptive mode can reliably observe sleep and unlock only while the app is running.",
    "settings.notification": "Notifications",
    "settings.notificationHelp": "Used for bedtime reminders, wake confirmation, and undoing automatic resets.",
    "settings.enableNotifications": "Allow Notifications",
    "settings.openNotificationSettings": "Open Notification Settings",
    "settings.scheduleHelp":
      "Starts automatically. If the app opens late, it catches up from the latest scheduled time.",
    "settings.noSchedule": "No days are enabled",
    "history.empty": "No wake records yet",
    "history.edit": "Edit Record",
    "history.corrected": "Corrected",
    "history.confidence": "Confidence %d%%",
    "history.deleteConfirm": "Delete this wake record?",
    "history.deleteDetail": "The clock will fall back to the previous valid record.",
    "onboarding.title": "Make waking up 00:00",
    "onboarding.body":
      "Awake Time shows the time since you woke up in the menu bar. Every record stays on this Mac.",
    "onboarding.login": "Launch at Login",
    "onboarding.loginBody":
      "This lets Awake Time observe Mac sleep, wake, and first unlock. You can turn it off later.",
    "onboarding.continue": "Get Started",
    "error.future": "Wake time cannot be in the future.",
    "error.save": "The record could not be saved. Try again.",
    "error.login": "Could not change launch-at-login: %@",
    "about.description": "Count your day from the moment you wake.",
    "about.privacy": "Runs locally and uploads no data.",
    "weekday.1": "Sunday",
    "weekday.2": "Monday",
    "weekday.3": "Tuesday",
    "weekday.4": "Wednesday",
    "weekday.5": "Thursday",
    "weekday.6": "Friday",
    "weekday.7": "Saturday",
  ]
}
