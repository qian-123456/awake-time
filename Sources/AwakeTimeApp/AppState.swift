import AppKit
import AwakeTimeKit
import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class AppState: ObservableObject {
  private enum Key {
    static let pendingObservation = "pendingWakeObservation"
  }

  let preferences: PreferencesStore
  private let modelContext: ModelContext
  private let defaults: UserDefaults

  @Published private(set) var records: [WakeRecord] = []
  @Published private(set) var now = Date()
  @Published var pendingWakeConfirmation: SleepObservation?
  @Published var lastError: String?
  @Published private(set) var notificationStatus: UNAuthorizationStatus = .notDetermined
  @Published private(set) var launchAtLogin = LoginItemManager.isEnabled

  private var boundaryTimer: Timer?
  private var minuteTimer: Timer?

  private lazy var systemMonitor = SystemEventMonitor(defaults: defaults) {
    [weak self] observation in
    Task { @MainActor in
      self?.handle(observation: observation)
    }
  }

  private lazy var notifications: NotificationCoordinator = {
    let coordinator = NotificationCoordinator()
    coordinator.onConfirm = { [weak self] in
      Task { @MainActor in self?.confirmPendingWake() }
    }
    coordinator.onDismiss = { [weak self] in
      Task { @MainActor in self?.dismissPendingWake() }
    }
    coordinator.onUndo = { [weak self] id in
      Task { @MainActor in self?.undoAutomaticReset(recordID: id) }
    }
    return coordinator
  }()

  init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
    self.modelContext = modelContext
    self.defaults = defaults
    self.preferences = PreferencesStore(defaults: defaults)
    reloadRecords()
    restorePendingObservation()
    scheduleMinuteBoundary()
    systemMonitor.start()
    updateNotificationActionTitles()
    refreshNotificationStatus()
    evaluateWeeklySchedule()
  }

  deinit {
    boundaryTimer?.invalidate()
    minuteTimer?.invalidate()
  }

  var language: AppLanguage { preferences.language }
  var currentRecord: WakeRecord? { records.first }
  var displayText: String { AwakeClockEngine.formatted(from: currentRecord?.wakeAt, to: now) }

  func setMode(_ mode: ClockMode) {
    preferences.mode = mode
    if mode == .adaptiveUnlock {
      requestNotificationAuthorization()
    }
    if mode == .weeklySchedule {
      evaluateWeeklySchedule()
    }
  }

  func setLanguage(_ language: AppLanguage) {
    preferences.language = language
    updateNotificationActionTitles()
    objectWillChange.send()
  }

  func completeOnboarding(launchAtLogin: Bool) {
    setLaunchAtLogin(launchAtLogin)
    preferences.onboardingComplete = true
  }

  func setLaunchAtLogin(_ enabled: Bool) {
    do {
      try LoginItemManager.setEnabled(enabled)
      launchAtLogin = LoginItemManager.isEnabled
    } catch {
      launchAtLogin = LoginItemManager.isEnabled
      lastError = L10n.format("error.login", language, error.localizedDescription)
    }
  }

  func requestNotificationAuthorization() {
    notifications.requestAuthorization()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      self?.refreshNotificationStatus()
    }
  }

  func openNotificationSettings() {
    guard
      let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension")
    else { return }
    NSWorkspace.shared.open(url)
  }

  func clearError() {
    lastError = nil
  }

  @discardableResult
  func startNewDay(at date: Date = Date(), source: WakeSource = .quickStart) -> Bool {
    setWake(
      at: date,
      source: source,
      confidence: source == .adaptiveAutomatic ? 1 : nil,
      corrected: source == .manual || source == .quickStart,
      sleepDuration: nil
    ) != nil
  }

  @discardableResult
  func setManualWake(at date: Date) -> Bool {
    guard date <= Date() else {
      lastError = L10n.text("error.future", language)
      return false
    }
    return setWake(at: date, source: .manual, confidence: nil, corrected: true, sleepDuration: nil)
      != nil
  }

  func updateRecord(_ record: WakeRecord, wakeAt: Date) -> Bool {
    guard wakeAt <= Date() else {
      lastError = L10n.text("error.future", language)
      return false
    }
    record.wakeAt = wakeAt
    record.logicalDayKey = DayKey.make(for: wakeAt)
    record.wasCorrected = true
    record.source = .manual
    do {
      try modelContext.save()
      reloadRecords()
      return true
    } catch {
      modelContext.rollback()
      reloadRecords()
      lastError = L10n.text("error.save", language)
      return false
    }
  }

  func deleteRecord(_ record: WakeRecord) {
    modelContext.delete(record)
    do {
      try modelContext.save()
      reloadRecords()
    } catch {
      modelContext.rollback()
      reloadRecords()
      lastError = L10n.text("error.save", language)
    }
  }

  func updateSchedule(_ setting: DailySchedule) {
    var schedule = preferences.weeklySchedule
    schedule[setting.weekday] = setting
    preferences.weeklySchedule = schedule
    if preferences.mode == .weeklySchedule {
      evaluateWeeklySchedule()
    }
  }

  func confirmPendingWake() {
    guard let observation = pendingWakeConfirmation else { return }
    _ = setWake(
      at: observation.unlockAt,
      source: .adaptiveConfirmed,
      confidence: 1,
      corrected: true,
      sleepDuration: observation.sleepDuration
    )
    clearPendingObservation()
  }

  func dismissPendingWake() {
    clearPendingObservation()
  }

  func undoAutomaticReset(recordID: UUID?) {
    let candidate: WakeRecord?
    if let recordID {
      candidate = records.first(where: { $0.id == recordID })
    } else {
      candidate = records.first(where: { $0.source == .adaptiveAutomatic })
    }
    guard let candidate else { return }
    deleteRecord(candidate)
  }

  private func handle(observation: SleepObservation) {
    guard preferences.mode == .adaptiveUnlock else { return }
    if let currentRecord, observation.sleepAt <= currentRecord.wakeAt {
      return
    }

    let history = records.map {
      WakeSample(
        wakeAt: $0.wakeAt,
        sleepDuration: $0.sleepDuration,
        source: $0.source,
        wasCorrected: $0.wasCorrected
      )
    }
    switch WakeInferenceEngine.evaluate(observation: observation, history: history) {
    case .automatic(let confidence):
      guard
        let record = setWake(
          at: observation.unlockAt,
          source: .adaptiveAutomatic,
          confidence: confidence,
          corrected: false,
          sleepDuration: observation.sleepDuration
        )
      else { return }
      notifications.sendAutomaticReset(
        title: L10n.text("adaptive.autoTitle", language),
        body: L10n.text("adaptive.autoBody", language),
        recordID: record.id
      )
    case .ask:
      pendingWakeConfirmation = observation
      persistPendingObservation(observation)
      notifications.sendConfirmation(
        title: L10n.text("adaptive.confirmTitle", language),
        body: L10n.text("adaptive.confirmBody", language)
      )
    }
  }

  @discardableResult
  private func setWake(
    at date: Date,
    source: WakeSource,
    confidence: Double?,
    corrected: Bool,
    sleepDuration: TimeInterval?
  ) -> WakeRecord? {
    let dayKey = DayKey.make(for: date)

    // A manual action corrects the existing logical day instead of creating competing starts.
    if source == .manual || source == .quickStart,
      let existing = records.first(where: { $0.logicalDayKey == dayKey })
    {
      existing.wakeAt = date
      existing.createdAt = Date()
      existing.source = source
      existing.confidence = confidence
      existing.wasCorrected = corrected
      existing.sleepDuration = sleepDuration
      do {
        try modelContext.save()
        reloadRecords()
        return existing
      } catch {
        modelContext.rollback()
        reloadRecords()
        lastError = L10n.text("error.save", language)
        return nil
      }
    }

    let record = WakeRecord(
      wakeAt: date,
      source: source,
      confidence: confidence,
      wasCorrected: corrected,
      logicalDayKey: dayKey,
      sleepDuration: sleepDuration
    )
    modelContext.insert(record)
    do {
      try modelContext.save()
      reloadRecords()
      return record
    } catch {
      modelContext.rollback()
      reloadRecords()
      lastError = L10n.text("error.save", language)
      return nil
    }
  }

  private func evaluateWeeklySchedule() {
    guard preferences.mode == .weeklySchedule else { return }
    guard
      let occurrence = ScheduleEngine.mostRecentOccurrence(
        before: now,
        schedule: preferences.weeklySchedule
      )
    else { return }
    guard !records.contains(where: { $0.logicalDayKey == occurrence.logicalDayKey }) else { return }
    _ = setWake(
      at: occurrence.date,
      source: .weeklySchedule,
      confidence: 1,
      corrected: false,
      sleepDuration: nil
    )
  }

  private func reloadRecords() {
    var descriptor = FetchDescriptor<WakeRecord>(
      sortBy: [SortDescriptor(\WakeRecord.createdAt, order: .reverse)]
    )
    descriptor.fetchLimit = 500
    records = (try? modelContext.fetch(descriptor)) ?? []
    now = Date()
  }

  private func refreshNotificationStatus() {
    notifications.authorizationStatus { [weak self] status in
      DispatchQueue.main.async {
        self?.notificationStatus = status
      }
    }
  }

  private func updateNotificationActionTitles() {
    notifications.updateActionTitles(
      confirm: L10n.text("action.startDay", language),
      dismiss: L10n.text("action.notNow", language),
      undo: L10n.text("action.undo", language)
    )
  }

  private func scheduleMinuteBoundary() {
    let current = Date()
    let remainder = current.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60)
    let delay = max(0.05, 60 - remainder)
    boundaryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
      Task { @MainActor in
        self?.tick()
        self?.minuteTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) {
          [weak self] _ in
          Task { @MainActor in self?.tick() }
        }
      }
    }
  }

  private func tick() {
    now = Date()
    evaluateWeeklySchedule()
  }

  private func persistPendingObservation(_ observation: SleepObservation) {
    if let data = try? JSONEncoder().encode(observation) {
      defaults.set(data, forKey: Key.pendingObservation)
    }
  }

  private func restorePendingObservation() {
    guard
      let data = defaults.data(forKey: Key.pendingObservation),
      let observation = try? JSONDecoder().decode(SleepObservation.self, from: data)
    else { return }
    pendingWakeConfirmation = observation
  }

  private func clearPendingObservation() {
    pendingWakeConfirmation = nil
    defaults.removeObject(forKey: Key.pendingObservation)
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
      "wake-confirm"
    ])
    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [
      "wake-confirm"
    ])
  }
}
