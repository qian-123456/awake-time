import Foundation
import SwiftData

public enum AwakeTimeStore {
  public static let directoryName = "AwakeTime"
  public static let databaseName = "AwakeTime.store"

  @MainActor
  public static func makeContainer(
    applicationSupportDirectory: URL? = nil,
    migrateLegacyStore: Bool = true
  ) throws -> ModelContainer {
    let fileManager = FileManager.default
    let supportDirectory = try applicationSupportDirectory
      ?? fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true
      )
    let storeDirectory = supportDirectory.appendingPathComponent(directoryName, isDirectory: true)
    try fileManager.createDirectory(at: storeDirectory, withIntermediateDirectories: true)

    let storeURL = storeDirectory.appendingPathComponent(databaseName)
    let isNewStore = !fileManager.fileExists(atPath: storeURL.path)
    let legacyRecords = isNewStore && migrateLegacyStore
      ? loadLegacyRecords(from: supportDirectory.appendingPathComponent("default.store"))
      : []

    let configuration = ModelConfiguration("AwakeTime", url: storeURL)
    let container = try ModelContainer(for: WakeRecord.self, configurations: configuration)
    if !legacyRecords.isEmpty {
      try importRecords(legacyRecords, into: container.mainContext)
    }
    return container
  }

  @MainActor
  private static func loadLegacyRecords(from legacyURL: URL) -> [WakeRecordSnapshot] {
    let fileManager = FileManager.default
    guard containsWakeRecordSchema(at: legacyURL) else { return [] }

    let temporaryDirectory = fileManager.temporaryDirectory
      .appendingPathComponent("AwakeTime-Legacy-\(UUID().uuidString)", isDirectory: true)
    let temporaryStoreURL = temporaryDirectory.appendingPathComponent("default.store")
    do {
      try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
      defer { try? fileManager.removeItem(at: temporaryDirectory) }

      for suffix in ["", "-wal", "-shm"] {
        let source = URL(fileURLWithPath: legacyURL.path + suffix)
        guard fileManager.fileExists(atPath: source.path) else { continue }
        let destination = URL(fileURLWithPath: temporaryStoreURL.path + suffix)
        try fileManager.copyItem(at: source, to: destination)
      }

      let configuration = ModelConfiguration(
        "AwakeTimeLegacy", url: temporaryStoreURL, allowsSave: false)
      let container = try ModelContainer(for: WakeRecord.self, configurations: configuration)
      let records = try container.mainContext.fetch(FetchDescriptor<WakeRecord>())
      return records.map(WakeRecordSnapshot.init)
    } catch {
      return []
    }
  }

  private static func containsWakeRecordSchema(at storeURL: URL) -> Bool {
    let signature = Data("ZWAKERECORD".utf8)
    for suffix in ["", "-wal"] {
      let url = URL(fileURLWithPath: storeURL.path + suffix)
      guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { continue }
      if data.range(of: signature) != nil {
        return true
      }
    }
    return false
  }

  @MainActor
  private static func importRecords(
    _ snapshots: [WakeRecordSnapshot],
    into context: ModelContext
  ) throws {
    for snapshot in snapshots {
      context.insert(snapshot.makeRecord())
    }
    do {
      try context.save()
    } catch {
      context.rollback()
      throw error
    }
  }
}

private struct WakeRecordSnapshot {
  let id: UUID
  let wakeAt: Date
  let createdAt: Date
  let source: WakeSource
  let confidence: Double?
  let wasCorrected: Bool
  let logicalDayKey: String
  let sleepDuration: TimeInterval?

  init(_ record: WakeRecord) {
    id = record.id
    wakeAt = record.wakeAt
    createdAt = record.createdAt
    source = record.source
    confidence = record.confidence
    wasCorrected = record.wasCorrected
    logicalDayKey = record.logicalDayKey
    sleepDuration = record.sleepDuration
  }

  func makeRecord() -> WakeRecord {
    WakeRecord(
      id: id,
      wakeAt: wakeAt,
      createdAt: createdAt,
      source: source,
      confidence: confidence,
      wasCorrected: wasCorrected,
      logicalDayKey: logicalDayKey,
      sleepDuration: sleepDuration
    )
  }
}
