import SwiftData
import XCTest

@testable import AwakeTimeKit

@MainActor
final class AwakeTimeStoreTests: XCTestCase {
  func testUsesApplicationSpecificStoreAndPersistsRecords() throws {
    let supportDirectory = temporarySupportDirectory()
    defer { try? FileManager.default.removeItem(at: supportDirectory) }

    var container: ModelContainer? = try AwakeTimeStore.makeContainer(
      applicationSupportDirectory: supportDirectory,
      migrateLegacyStore: false
    )
    let wakeAt = Date(timeIntervalSince1970: 1_000_000)
    container?.mainContext.insert(
      WakeRecord(
        wakeAt: wakeAt,
        source: .quickStart,
        logicalDayKey: "2001-01-12"
      ))
    try container?.mainContext.save()
    container = nil

    let storeURL = supportDirectory
      .appendingPathComponent(AwakeTimeStore.directoryName)
      .appendingPathComponent(AwakeTimeStore.databaseName)
    XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
    XCTAssertFalse(
      FileManager.default.fileExists(
        atPath: supportDirectory.appendingPathComponent("default.store").path
      ))

    let reopened = try AwakeTimeStore.makeContainer(
      applicationSupportDirectory: supportDirectory,
      migrateLegacyStore: false
    )
    let records = try reopened.mainContext.fetch(FetchDescriptor<WakeRecord>())
    XCTAssertEqual(records.count, 1)
    XCTAssertEqual(records.first?.wakeAt, wakeAt)
  }

  func testMigratesRecordsFromCompatibleLegacyStore() throws {
    let supportDirectory = temporarySupportDirectory()
    defer { try? FileManager.default.removeItem(at: supportDirectory) }
    try FileManager.default.createDirectory(
      at: supportDirectory,
      withIntermediateDirectories: true
    )
    let legacyURL = supportDirectory.appendingPathComponent("default.store")
    let legacyConfiguration = ModelConfiguration("Legacy", url: legacyURL)
    var legacyContainer: ModelContainer? = try ModelContainer(
      for: WakeRecord.self,
      configurations: legacyConfiguration
    )
    let id = UUID()
    legacyContainer?.mainContext.insert(
      WakeRecord(
        id: id,
        wakeAt: Date(timeIntervalSince1970: 2_000_000),
        source: .manual,
        logicalDayKey: "2001-01-24"
      ))
    try legacyContainer?.mainContext.save()
    legacyContainer = nil

    let migrated = try AwakeTimeStore.makeContainer(
      applicationSupportDirectory: supportDirectory
    )
    let records = try migrated.mainContext.fetch(FetchDescriptor<WakeRecord>())
    XCTAssertEqual(records.map(\.id), [id])
  }

  func testIgnoresAnIncompatibleLegacyStore() throws {
    let supportDirectory = temporarySupportDirectory()
    defer { try? FileManager.default.removeItem(at: supportDirectory) }
    try FileManager.default.createDirectory(
      at: supportDirectory,
      withIntermediateDirectories: true
    )
    try Data("another application's database".utf8).write(
      to: supportDirectory.appendingPathComponent("default.store")
    )

    let container = try AwakeTimeStore.makeContainer(
      applicationSupportDirectory: supportDirectory
    )
    container.mainContext.insert(
      WakeRecord(
        wakeAt: Date(),
        source: .quickStart,
        logicalDayKey: "2026-07-30"
      ))
    XCTAssertNoThrow(try container.mainContext.save())
  }

  private func temporarySupportDirectory() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("AwakeTimeTests-\(UUID().uuidString)", isDirectory: true)
  }
}
