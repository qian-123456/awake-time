import AppKit
import AwakeTimeKit
import SwiftUI
import UserNotifications

struct SettingsRootView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    TabView {
      GeneralSettingsView()
        .tabItem {
          Label(L10n.text("section.general", appState.language), systemImage: "gearshape")
        }
      ScheduleSettingsView()
        .tabItem {
          Label(L10n.text("section.schedule", appState.language), systemImage: "calendar")
        }
      HistoryView()
        .tabItem {
          Label(
            L10n.text("section.history", appState.language),
            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
          )
        }
      AboutView()
        .tabItem {
          Label(L10n.text("section.about", appState.language), systemImage: "info.circle")
        }
    }
    .padding(14)
    .frame(width: 600, height: 500)
    .alert(
      L10n.text("app.name", appState.language),
      isPresented: Binding(
        get: { appState.lastError != nil },
        set: { if !$0 { appState.clearError() } }
      )
    ) {
      Button("OK") { appState.clearError() }
    } message: {
      Text(appState.lastError ?? "")
    }
  }
}

private struct GeneralSettingsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Form {
      Section(L10n.text("section.mode", appState.language)) {
        Picker(
          "",
          selection: Binding(
            get: { appState.preferences.mode },
            set: { appState.setMode($0) }
          )
        ) {
          ForEach(ClockMode.allCases) { mode in
            Text(L10n.mode(mode, appState.language)).tag(mode)
          }
        }
        .labelsHidden()
        .pickerStyle(.radioGroup)
      }

      Section(L10n.text("settings.language", appState.language)) {
        Picker(
          "",
          selection: Binding(
            get: { appState.preferences.language },
            set: { appState.setLanguage($0) }
          )
        ) {
          Text(L10n.text("settings.systemLanguage", appState.language)).tag(AppLanguage.system)
          Text(L10n.text("settings.chinese", appState.language)).tag(AppLanguage.simplifiedChinese)
          Text(L10n.text("settings.english", appState.language)).tag(AppLanguage.english)
        }
        .labelsHidden()
        .pickerStyle(.segmented)
      }

      Section(L10n.text("settings.sleepDuration", appState.language)) {
        HStack {
          Stepper(
            value: Binding(
              get: { appState.preferences.preferredSleepDuration },
              set: { appState.setPreferredSleepDuration($0) }
            ),
            in: PreferencesStore.sleepDurationRange,
            step: 30 * 60
          ) {
            Text(sleepDurationText)
          }
          Spacer()
          Text(L10n.format("settings.nightStartsAt", appState.language, nightStartText))
            .foregroundStyle(.secondary)
        }
        Text(L10n.text("settings.sleepDurationHelp", appState.language))
          .font(.caption)
          .foregroundStyle(.secondary)

        Toggle(
          L10n.text("settings.sleepReminder", appState.language),
          isOn: Binding(
            get: { appState.preferences.sleepReminderEnabled },
            set: { appState.setSleepReminderEnabled($0) }
          )
        )

        if appState.preferences.sleepReminderEnabled {
          HStack {
            Stepper(
              value: Binding(
                get: { appState.preferences.sleepReminderLeadTime },
                set: { appState.setSleepReminderLeadTime($0) }
              ),
              in: PreferencesStore.sleepReminderLeadTimeRange,
              step: 15 * 60
            ) {
              Text(
                L10n.format(
                  "settings.sleepReminderLeadTime",
                  appState.language,
                  L10n.duration(appState.preferences.sleepReminderLeadTime, appState.language)
                )
              )
            }
            Spacer()
            Text(
              L10n.format(
                "settings.sleepReminderAt",
                appState.language,
                sleepReminderTimeText
              )
            )
            .foregroundStyle(.secondary)
          }
          Text(L10n.text("settings.sleepReminderHelp", appState.language))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Section {
        Toggle(
          L10n.text("settings.login", appState.language),
          isOn: Binding(
            get: { appState.launchAtLogin },
            set: { appState.setLaunchAtLogin($0) }
          )
        )
        Text(L10n.text("settings.loginHelp", appState.language))
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Section(L10n.text("settings.notification", appState.language)) {
        HStack {
          Text(notificationDescription)
          Spacer()
          if appState.notificationStatus == .notDetermined {
            Button(L10n.text("settings.enableNotifications", appState.language)) {
              appState.requestNotificationAuthorization()
            }
          } else if appState.notificationStatus == .denied {
            Button(L10n.text("settings.openNotificationSettings", appState.language)) {
              appState.openNotificationSettings()
            }
          }
        }
        Text(L10n.text("settings.notificationHelp", appState.language))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .formStyle(.grouped)
  }

  private var notificationDescription: String {
    switch appState.notificationStatus {
    case .authorized, .provisional, .ephemeral:
      return appState.language.resolved == .simplifiedChinese ? "已允许" : "Allowed"
    case .denied:
      return appState.language.resolved == .simplifiedChinese ? "已关闭" : "Off"
    case .notDetermined:
      return appState.language.resolved == .simplifiedChinese ? "尚未设置" : "Not Set"
    @unknown default:
      return "—"
    }
  }

  private var sleepDurationText: String {
    let hours = appState.preferences.preferredSleepDuration / 3_600
    return L10n.format("settings.sleepDurationValue", appState.language, hours)
  }

  private var nightStartText: String {
    let duration = AwakeClockEngine.nightStartsAfter(
      sleepDuration: appState.preferences.preferredSleepDuration
    )
    let hours = Int(duration) / 3_600
    let minutes = Int(duration) % 3_600 / 60
    return String(format: "%d:%02d", hours, minutes)
  }

  private var sleepReminderTimeText: String {
    let duration = AwakeClockEngine.sleepReminderStartsAfter(
      sleepDuration: appState.preferences.preferredSleepDuration,
      leadTime: appState.preferences.sleepReminderLeadTime
    )
    let hours = Int(duration) / 3_600
    let minutes = Int(duration) % 3_600 / 60
    return String(format: "%02d:%02d", hours, minutes)
  }
}

private struct ScheduleSettingsView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Form {
      Section {
        Text(L10n.text("settings.scheduleHelp", appState.language))
          .font(.callout)
          .foregroundStyle(.secondary)
      }

      Section(L10n.text("section.schedule", appState.language)) {
        ForEach(orderedWeekdays) { weekday in
          ScheduleRow(
            setting: appState.preferences.weeklySchedule[weekday],
            language: appState.language,
            onChange: appState.updateSchedule
          )
        }
      }
    }
    .formStyle(.grouped)
  }

  private var orderedWeekdays: [Weekday] {
    [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
  }
}

private struct ScheduleRow: View {
  let setting: DailySchedule
  let language: AppLanguage
  let onChange: (DailySchedule) -> Void

  var body: some View {
    HStack {
      Toggle(
        L10n.weekday(setting.weekday, language),
        isOn: Binding(
          get: { setting.isEnabled },
          set: { enabled in
            var copy = setting
            copy.isEnabled = enabled
            onChange(copy)
          }
        )
      )
      Spacer()
      DatePicker(
        "",
        selection: Binding(
          get: { dateForSetting },
          set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            var copy = setting
            copy.hour = components.hour ?? setting.hour
            copy.minute = components.minute ?? setting.minute
            onChange(copy)
          }
        ),
        displayedComponents: .hourAndMinute
      )
      .labelsHidden()
      .disabled(!setting.isEnabled)
    }
  }

  private var dateForSetting: Date {
    var components = DateComponents()
    components.year = 2001
    components.month = 1
    components.day = 1
    components.hour = setting.hour
    components.minute = setting.minute
    return Calendar.current.date(from: components) ?? Date()
  }
}

private struct AboutView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    VStack(spacing: 12) {
      Image(systemName: "sun.horizon.fill")
        .font(.system(size: 52))
        .foregroundStyle(.orange)
      Text(L10n.text("app.name", appState.language))
        .font(.title2.weight(.semibold))
      Text(L10n.text("about.description", appState.language))
        .foregroundStyle(.secondary)
      Label(L10n.text("about.privacy", appState.language), systemImage: "lock.fill")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
