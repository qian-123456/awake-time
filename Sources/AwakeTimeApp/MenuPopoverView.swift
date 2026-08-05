import AppKit
import AwakeTimeKit
import SwiftUI

struct MenuPopoverView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    Group {
      if appState.preferences.onboardingComplete {
        NavigationStack {
          MenuRootView()
        }
      } else {
        OnboardingView()
      }
    }
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

private struct MenuRootView: View {
  @EnvironmentObject private var appState: AppState
  @State private var showManualEditor = false

  private var language: AppLanguage { appState.language }

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 5) {
        Text(appState.displayText)
          .font(.system(size: 42, weight: .medium, design: .rounded))
          .monospacedDigit()
          .contentTransition(.numericText())
        if let wakeAt = appState.currentRecord?.wakeAt {
          Text(
            L10n.format(
              "clock.awakeSince",
              language,
              ViewSupport.dateTime(wakeAt, language: language)
            )
          )
          .font(.caption)
          .foregroundStyle(.secondary)
          if let bedtime = appState.estimatedBedtime {
            Text(
              L10n.format(
                "clock.estimatedBedtime",
                language,
                ViewSupport.dateTime(bedtime, language: language)
              )
            )
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        } else {
          Text(L10n.text("status.notStarted", language))
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 18)
      .padding(.bottom, 14)

      Divider()

      if appState.pendingWakeConfirmation != nil {
        WakeConfirmationView()
        Divider()
      }

      VStack(spacing: 10) {
        Button {
          appState.startNewDay()
        } label: {
          Label(L10n.text("action.startDay", language), systemImage: "sunrise.fill")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)

        Button {
          showManualEditor = true
        } label: {
          Label(L10n.text("action.setWake", language), systemImage: "calendar.badge.clock")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)

        HStack {
          Label(L10n.text("section.mode", language), systemImage: "slider.horizontal.3")
          Spacer()
          Picker(
            "",
            selection: Binding(
              get: { appState.preferences.mode },
              set: { appState.setMode($0) }
            )
          ) {
            ForEach(ClockMode.allCases) { mode in
              Text(L10n.mode(mode, language)).tag(mode)
            }
          }
          .labelsHidden()
          .frame(maxWidth: 165)
        }
      }
      .padding(14)

      Divider()

      VStack(spacing: 0) {
        NavigationLink {
          HistoryView(isCompact: true)
        } label: {
          MenuNavigationRow(
            title: L10n.text("section.history", language),
            systemImage: "clock.arrow.trianglehead.counterclockwise.rotate.90"
          )
        }
        .buttonStyle(.plain)

        SettingsLink {
          MenuNavigationRow(
            title: L10n.text("action.settings", language),
            systemImage: "gearshape"
          )
        }
        .buttonStyle(.plain)

        Button {
          NSApplication.shared.terminate(nil)
        } label: {
          MenuNavigationRow(
            title: L10n.text("action.quit", language),
            systemImage: "power",
            showsChevron: false
          )
        }
        .buttonStyle(.plain)
      }
      .padding(.vertical, 6)
    }
    .frame(width: 340)
    .sheet(isPresented: $showManualEditor) {
      ManualWakeEditor()
    }
  }
}

private struct WakeConfirmationView: View {
  @EnvironmentObject private var appState: AppState

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Label(L10n.text("adaptive.question", appState.language), systemImage: "moon.zzz.fill")
        .font(.headline)
      Text(L10n.text("adaptive.detail", appState.language))
        .font(.caption)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 4) {
        Button(L10n.text("action.notNow", appState.language)) {
          appState.dismissPendingWake()
        }
        Spacer()
        Button(L10n.text("action.confirm", appState.language)) {
          appState.confirmPendingWake()
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(14)
    .background(.orange.opacity(0.08))
  }
}

private struct MenuNavigationRow: View {
  let title: String
  let systemImage: String
  var showsChevron = true

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: systemImage)
        .frame(width: 18)
        .foregroundStyle(.secondary)
      Text(title)
      Spacer()
      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.tertiary)
      }
    }
    .contentShape(Rectangle())
    .padding(.horizontal, 14)
    .frame(height: 34)
  }
}

private struct ManualWakeEditor: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  @State private var wakeDay: Date
  @State private var wakeHour: Int
  @State private var wakeMinute: Int

  init() {
    let date = WakeTimeGranularity.floorToStep(Date())
    let components = Calendar.autoupdatingCurrent.dateComponents(
      [.hour, .minute],
      from: date
    )
    _wakeDay = State(initialValue: date)
    _wakeHour = State(initialValue: components.hour ?? 0)
    _wakeMinute = State(initialValue: components.minute ?? 0)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text(L10n.text("action.setWake", appState.language))
        .font(.headline)

      VStack(spacing: 4) {
        Text(String(format: "%02d:%02d", wakeHour, wakeMinute))
          .font(.system(size: 30, weight: .semibold, design: .rounded))
          .monospacedDigit()
        Text(ViewSupport.date(wakeAt, language: appState.language))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 1)

      Divider()
        .padding(.vertical, -2)

      HStack(spacing: 8) {
        Label(L10n.text("settings.time", appState.language), systemImage: "clock")
        TimeUnitControl(
          values: Array(0..<24),
          value: $wakeHour,
          onIncrement: { adjustHour(by: 1) },
          onDecrement: { adjustHour(by: -1) }
        )
        Text(":")
          .font(.system(size: 14, weight: .medium, design: .rounded))
        TimeUnitControl(
          values: minuteChoices,
          value: $wakeMinute,
          onIncrement: { adjustMinute(by: 1) },
          onDecrement: { adjustMinute(by: -1) }
        )
      }

      HStack(spacing: 6) {
        Label(L10n.text("settings.date", appState.language), systemImage: "calendar")
        Spacer()
        DatePicker(
          "",
          selection: $wakeDay,
          in: ...Date(),
          displayedComponents: .date
        )
        .labelsHidden()
        .datePickerStyle(.field)
      }
      HStack {
        Spacer()
        Button(L10n.text("action.cancel", appState.language)) { dismiss() }
        Button(L10n.text("action.apply", appState.language)) {
          if appState.setManualWake(at: wakeAt) { dismiss() }
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(16)
    .frame(width: 360)
  }

  private var minuteChoices: [Int] {
    let regularChoices = Array(
      stride(from: 0, to: 60, by: WakeTimeGranularity.minuteStep)
    )
    return Array(Set(regularChoices + [wakeMinute])).sorted()
  }

  private func adjustHour(by amount: Int) {
    wakeHour = (wakeHour + amount + 24) % 24
  }

  private func adjustMinute(by amount: Int) {
    let adjusted = WakeTimeGranularity.addingMinutes(
      amount,
      toHour: wakeHour,
      minute: wakeMinute
    )
    wakeHour = adjusted.hour
    wakeMinute = adjusted.minute
  }

  private var wakeAt: Date {
    let calendar = Calendar.autoupdatingCurrent
    var components = calendar.dateComponents([.year, .month, .day], from: wakeDay)
    components.hour = wakeHour
    components.minute = wakeMinute
    components.second = 0
    components.nanosecond = 0
    return calendar.date(from: components) ?? wakeDay
  }
}

private struct TimeUnitControl: View {
  let values: [Int]
  @Binding var value: Int
  let onIncrement: () -> Void
  let onDecrement: () -> Void

  var body: some View {
    HStack(spacing: 4) {
      Picker("", selection: $value) {
        ForEach(values, id: \.self) { value in
          Text(String(format: "%02d", value)).tag(value)
        }
      }
      .labelsHidden()
      .pickerStyle(.menu)
      .controlSize(.small)
      .frame(width: 46, height: 24)

      VStack(spacing: 0) {
        Button(action: onIncrement) {
          Image(systemName: "chevron.up")
            .font(.system(size: 8, weight: .semibold))
            .frame(width: 26, height: 12)
        }
        .buttonStyle(.plain)
        .help("Increase")

        Divider()
          .frame(width: 16)

        Button(action: onDecrement) {
          Image(systemName: "chevron.down")
            .font(.system(size: 8, weight: .semibold))
            .frame(width: 26, height: 12)
        }
        .buttonStyle(.plain)
        .help("Decrease")
      }
      .frame(width: 26, height: 24)
      .background(
        Color.primary.opacity(0.10),
        in: RoundedRectangle(cornerRadius: 5)
      )
    }
    .frame(height: 24)
  }
}
