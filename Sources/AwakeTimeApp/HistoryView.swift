import AwakeTimeKit
import SwiftUI

struct HistoryView: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let isCompact: Bool
  @State private var editingRecord: WakeRecord?
  @State private var deletingRecord: WakeRecord?

  init(isCompact: Bool = false) {
    self.isCompact = isCompact
  }

  var body: some View {
    VStack(spacing: 0) {
      if isCompact {
        HStack(spacing: 10) {
          Button {
            dismiss()
          } label: {
            Label(L10n.text("action.back", appState.language), systemImage: "chevron.left")
          }
          .buttonStyle(.plain)

          Spacer()

          Text(L10n.text("section.history", appState.language))
            .font(.headline)

          Spacer()

          Color.clear
            .frame(width: 54, height: 1)
        }
        .padding(.horizontal, 14)
        .frame(height: 42)

        Divider()
      }

      Group {
        if appState.records.isEmpty {
          ContentUnavailableView(
            L10n.text("history.empty", appState.language),
            systemImage: "clock.badge.questionmark"
          )
        } else {
          List(appState.records, id: \.id) { record in
            HistoryRow(record: record)
              .contentShape(Rectangle())
              .onTapGesture { editingRecord = record }
              .contextMenu {
                Button(L10n.text("history.edit", appState.language)) {
                  editingRecord = record
                }
                Divider()
                Button(L10n.text("action.delete", appState.language), role: .destructive) {
                  deletingRecord = record
                }
              }
          }
          .listStyle(.inset)
        }
      }
    }
    .navigationTitle(isCompact ? "" : L10n.text("section.history", appState.language))
    .frame(minWidth: isCompact ? 340 : 500, minHeight: isCompact ? 360 : 380)
    .sheet(item: $editingRecord) { record in
      RecordEditor(record: record)
    }
    .alert(
      L10n.text("history.deleteConfirm", appState.language),
      isPresented: Binding(
        get: { deletingRecord != nil },
        set: { if !$0 { deletingRecord = nil } }
      )
    ) {
      Button(L10n.text("action.cancel", appState.language), role: .cancel) {
        deletingRecord = nil
      }
      Button(L10n.text("action.delete", appState.language), role: .destructive) {
        if let deletingRecord { appState.deleteRecord(deletingRecord) }
        deletingRecord = nil
      }
    } message: {
      Text(L10n.text("history.deleteDetail", appState.language))
    }
  }
}

private struct HistoryRow: View {
  @EnvironmentObject private var appState: AppState
  let record: WakeRecord

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: sourceIcon)
        .foregroundStyle(sourceColor)
        .frame(width: 22)
      VStack(alignment: .leading, spacing: 3) {
        Text(ViewSupport.dateTime(record.wakeAt, language: appState.language))
          .font(.body.weight(.medium))
        HStack(spacing: 6) {
          Text(L10n.source(record.source, appState.language))
          if record.wasCorrected {
            Text("· \(L10n.text("history.corrected", appState.language))")
          }
          if let confidence = record.confidence, record.source == .adaptiveAutomatic {
            Text("· \(L10n.format("history.confidence", appState.language, Int(confidence * 100)))")
          }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      Spacer()
    }
    .padding(.vertical, 4)
  }

  private var sourceIcon: String {
    switch record.source {
    case .manual: "calendar.badge.clock"
    case .quickStart: "play.circle.fill"
    case .adaptiveConfirmed: "checkmark.circle.fill"
    case .adaptiveAutomatic: "sparkles"
    case .weeklySchedule: "calendar"
    }
  }

  private var sourceColor: Color {
    record.source == .adaptiveAutomatic ? .orange : .secondary
  }
}

private struct RecordEditor: View {
  @EnvironmentObject private var appState: AppState
  @Environment(\.dismiss) private var dismiss
  let record: WakeRecord
  @State private var wakeAt: Date

  init(record: WakeRecord) {
    self.record = record
    _wakeAt = State(initialValue: record.wakeAt)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text(L10n.text("history.edit", appState.language))
        .font(.title3.weight(.semibold))
      DatePicker(
        L10n.text("action.setWake", appState.language),
        selection: $wakeAt,
        in: ...Date(),
        displayedComponents: [.date, .hourAndMinute]
      )
      HStack {
        Spacer()
        Button(L10n.text("action.cancel", appState.language)) { dismiss() }
        Button(L10n.text("action.apply", appState.language)) {
          if appState.updateRecord(record, wakeAt: wakeAt) { dismiss() }
        }
        .buttonStyle(.borderedProminent)
      }
    }
    .padding(20)
    .frame(width: 390)
  }
}
