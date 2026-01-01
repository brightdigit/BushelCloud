//
//  SyncEngine.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import BushelFoundation
public import BushelLogging
public import BushelUtilities
public import Foundation
import Logging
public import MistKit

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

/// Orchestrates the complete sync process from data sources to CloudKit
///
/// **Tutorial**: This demonstrates the typical flow for CloudKit data syncing:
/// 1. Fetch data from external sources
/// 2. Transform to CloudKit records
/// 3. Batch upload using MistKit
///
/// Use `--verbose` flag to see detailed MistKit API usage.
public struct SyncEngine: Sendable {
  let cloudKitService: BushelCloudKitService
  let pipeline: DataSourcePipeline

  // MARK: - Configuration

  public struct SyncOptions: Sendable {
    public var dryRun: Bool = false
    public var pipelineOptions: DataSourcePipeline.Options = .init()

    public init(dryRun: Bool = false, pipelineOptions: DataSourcePipeline.Options = .init()) {
      self.dryRun = dryRun
      self.pipelineOptions = pipelineOptions
    }
  }

  // MARK: - Initialization

  /// Initialize sync engine with CloudKit credentials
  ///
  /// **Flexible Authentication**: Supports both file-based and string-based PEM content:
  /// - `.pemString`: For CI/CD environments (GitHub Actions secrets)
  /// - `.pemFile`: For local development (file on disk)
  ///
  /// **Environment Separation**: Use separate keys for development and production:
  /// - Development: Safe for testing, free API calls, can clear data freely
  /// - Production: Real user data, requires careful key management
  ///
  /// - Parameters:
  ///   - containerIdentifier: CloudKit container ID
  ///   - keyID: Server-to-Server Key ID
  ///   - authMethod: Authentication method (`.pemString` or `.pemFile`)
  ///   - environment: CloudKit environment (.development or .production, defaults to .development)
  ///   - configuration: Fetch configuration for data sources
  /// - Throws: Error if authentication credentials are invalid or missing
  public init(
    containerIdentifier: String,
    keyID: String,
    authMethod: CloudKitAuthMethod,
    environment: Environment = .development,
    configuration: FetchConfiguration = FetchConfiguration.loadFromEnvironment()
  ) throws {
    // Initialize CloudKit service based on auth method
    let service: BushelCloudKitService
    switch authMethod {
    case .pemString(let pem):
      service = try BushelCloudKitService(
        containerIdentifier: containerIdentifier,
        keyID: keyID,
        pemString: pem,
        environment: environment
      )
    case .pemFile(let path):
      service = try BushelCloudKitService(
        containerIdentifier: containerIdentifier,
        keyID: keyID,
        privateKeyPath: path,
        environment: environment
      )
    }

    self.cloudKitService = service
    self.pipeline = DataSourcePipeline(
      configuration: configuration
    )
  }

  // MARK: - Sync Operations

  /// Execute full sync from all data sources to CloudKit
  public func sync(options: SyncOptions = SyncOptions()) async throws -> SyncResult {
    print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.info("Starting Bushel CloudKit Sync")
    print(String(repeating: "=", count: 60))
    Self.logger.info("Sync started")

    if options.dryRun {
      BushelUtilities.ConsoleOutput.info("DRY RUN MODE - No changes will be made to CloudKit")
      Self.logger.info("Sync running in dry-run mode")
    }

    Self.logger.debug(
      "Using MistKit Server-to-Server authentication for bulk record operations"
    )

    // Step 1: Fetch from all data sources
    print("\n📥 Step 1: Fetching data from external sources...")
    Self.logger.debug(
      "Initializing data source pipeline to fetch from ipsw.me, TheAppleWiki, MESU, and other sources"
    )

    let fetchResult = try await pipeline.fetch(options: options.pipelineOptions)

    Self.logger.debug(
      "Data fetch complete. Beginning deduplication and merge phase."
    )
    Self.logger.debug(
      "Multiple data sources may have overlapping data. The pipeline deduplicates by version+build number."
    )

    let stats = SyncResult(
      restoreImagesCount: fetchResult.restoreImages.count,
      xcodeVersionsCount: fetchResult.xcodeVersions.count,
      swiftVersionsCount: fetchResult.swiftVersions.count
    )

    let totalRecords =
      stats.restoreImagesCount + stats.xcodeVersionsCount + stats.swiftVersionsCount

    print("\n📊 Data Summary:")
    print("   RestoreImages: \(stats.restoreImagesCount)")
    print("   XcodeVersions: \(stats.xcodeVersionsCount)")
    print("   SwiftVersions: \(stats.swiftVersionsCount)")
    print("   ─────────────────────")
    print("   Total: \(totalRecords) records")

    Self.logger.debug(
      "Records ready for CloudKit upload: \(totalRecords) total"
    )

    // Step 2: Sync to CloudKit (unless dry run)
    if !options.dryRun {
      print("\n☁️  Step 2: Syncing to CloudKit...")
      Self.logger.debug(
        "Using MistKit to batch upload records to CloudKit public database"
      )
      Self.logger.debug(
        "MistKit handles authentication, batching (200 records/request), and error handling automatically"
      )

      // Sync in dependency order: SwiftVersion → RestoreImage → XcodeVersion
      // (Prevents broken CKReference relationships)
      try await cloudKitService.syncAllRecords(
        fetchResult.swiftVersions,  // First: no dependencies
        fetchResult.restoreImages,  // Second: no dependencies
        fetchResult.xcodeVersions  // Third: references first two
      )
    } else {
      print("\n⏭️  Step 2: Skipped (dry run)")
      print("   Would sync:")
      print("   • \(stats.restoreImagesCount) restore images")
      print("   • \(stats.xcodeVersionsCount) Xcode versions")
      print("   • \(stats.swiftVersionsCount) Swift versions")
      Self.logger.debug(
        "Dry run mode: No CloudKit operations performed"
      )
    }

    print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.success("Sync completed successfully!")
    print(String(repeating: "=", count: 60))
    Self.logger.info("Sync completed successfully")

    return stats
  }

  /// Delete all records from CloudKit
  public func clear() async throws {
    print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.info("Clearing all CloudKit data")
    print(String(repeating: "=", count: 60))
    Self.logger.info("Clearing all CloudKit records")

    try await cloudKitService.deleteAllRecords()

    print("\n" + String(repeating: "=", count: 60))
    BushelUtilities.ConsoleOutput.success("Clear completed successfully!")
    print(String(repeating: "=", count: 60))
    Self.logger.info("Clear completed successfully")
  }

  // MARK: - Result Types

  public struct SyncResult: Sendable {
    public let restoreImagesCount: Int
    public let xcodeVersionsCount: Int
    public let swiftVersionsCount: Int

    public init(restoreImagesCount: Int, xcodeVersionsCount: Int, swiftVersionsCount: Int) {
      self.restoreImagesCount = restoreImagesCount
      self.xcodeVersionsCount = xcodeVersionsCount
      self.swiftVersionsCount = swiftVersionsCount
    }
  }
}

// MARK: - Loggable Conformance
extension SyncEngine: Loggable {
  public static let loggingCategory: BushelLogging.Category = .application
}
