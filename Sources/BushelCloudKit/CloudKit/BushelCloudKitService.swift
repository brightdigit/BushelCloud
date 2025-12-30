//
//  BushelCloudKitService.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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
public import Foundation
import Logging
public import MistKit

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

/// CloudKit service wrapper for Bushel demo operations
///
/// **Tutorial**: This demonstrates MistKit's Server-to-Server authentication pattern:
/// 1. Load ECDSA private key from .pem file
/// 2. Create ServerToServerAuthManager with key ID and PEM string
/// 3. Initialize CloudKitService with the auth manager
/// 4. Use service.modifyRecords() and service.queryRecords() for operations
///
/// This pattern allows command-line tools and servers to access CloudKit without user authentication.
public struct BushelCloudKitService: Sendable, RecordManaging, CloudKitRecordCollection {
  public typealias RecordTypeSetType = RecordTypeSet

  private let service: CloudKitService

  // MARK: - CloudKitRecordCollection

  /// All CloudKit record types managed by this service (using variadic generics)
  public static let recordTypes = RecordTypeSet(
    RestoreImageRecord.self,
    XcodeVersionRecord.self,
    SwiftVersionRecord.self,
    DataSourceMetadata.self
  )

  // MARK: - Initialization

  /// Initialize CloudKit service with Server-to-Server authentication
  ///
  /// **MistKit Pattern**: Server-to-Server authentication requires:
  /// 1. Key ID from CloudKit Dashboard → API Access → Server-to-Server Keys
  /// 2. Private key .pem file downloaded when creating the key
  /// 3. Container identifier (begins with "iCloud.")
  ///
  /// - Parameters:
  ///   - containerIdentifier: CloudKit container ID (e.g., "iCloud.com.company.App")
  ///   - keyID: Server-to-Server Key ID from CloudKit Dashboard
  ///   - privateKeyPath: Path to the private key .pem file
  ///   - environment: CloudKit environment (.development or .production, defaults to .development)
  /// - Throws: Error if the private key file cannot be read or is invalid
  public init(
    containerIdentifier: String,
    keyID: String,
    privateKeyPath: String,
    environment: Environment = .development
  ) throws {
    // Read PEM file from disk
    guard FileManager.default.fileExists(atPath: privateKeyPath) else {
      throw BushelCloudKitError.privateKeyFileNotFound(path: privateKeyPath)
    }

    let pemString: String
    do {
      pemString = try String(contentsOfFile: privateKeyPath, encoding: .utf8)
    } catch {
      throw BushelCloudKitError.privateKeyFileReadFailed(path: privateKeyPath, error: error)
    }

    // Create Server-to-Server authentication manager
    let tokenManager = try ServerToServerAuthManager(
      keyID: keyID,
      pemString: pemString
    )

    self.service = try CloudKitService(
      containerIdentifier: containerIdentifier,
      tokenManager: tokenManager,
      environment: environment,
      database: .public
    )
  }

  /// Initialize CloudKit service with Server-to-Server authentication using PEM string
  ///
  /// **CI/CD Pattern**: This initializer accepts PEM content directly from environment variables,
  /// eliminating the need for temporary file creation in GitHub Actions or other CI/CD environments.
  ///
  /// - Parameters:
  ///   - containerIdentifier: CloudKit container ID (e.g., "iCloud.com.company.App")
  ///   - keyID: Server-to-Server Key ID from CloudKit Dashboard
  ///   - pemString: PEM file content as string (including headers/footers)
  ///   - environment: CloudKit environment (.development or .production, defaults to .development)
  /// - Throws: Error if PEM string is invalid or authentication fails
  public init(
    containerIdentifier: String,
    keyID: String,
    pemString: String,
    environment: Environment = .development
  ) throws {
    // Create Server-to-Server authentication manager directly from PEM string
    let tokenManager = try ServerToServerAuthManager(
      keyID: keyID,
      pemString: pemString
    )

    self.service = try CloudKitService(
      containerIdentifier: containerIdentifier,
      tokenManager: tokenManager,
      environment: environment,
      database: .public
    )
  }

  // MARK: - RecordManaging Protocol Requirements

  /// Query all records of a given type
  public func queryRecords(recordType: String) async throws -> [RecordInfo] {
    try await service.queryRecords(recordType: recordType, limit: 200)
  }

  /// Execute operations in batches (CloudKit limits to 200 operations per request)
  ///
  /// **MistKit Pattern**: CloudKit has a 200 operations/request limit.
  /// This method chunks operations and calls service.modifyRecords() for each batch.
  public func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
  ) async throws {
    let batchSize = 200
    let batches = operations.chunked(into: batchSize)

    print("Syncing \(operations.count) \(recordType) record(s) in \(batches.count) batch(es)...")
    Self.logger.debug(
      "CloudKit batch limit: 200 operations/request. Using \(batches.count) batch(es) for \(operations.count) records."
    )

    var totalSucceeded = 0
    var totalFailed = 0

    for (index, batch) in batches.enumerated() {
      print("  Batch \(index + 1)/\(batches.count): \(batch.count) records...")
      Self.logger.debug(
        "Calling MistKit service.modifyRecords() with \(batch.count) RecordOperation objects"
      )

      let results = try await service.modifyRecords(batch)

      Self.logger.debug(
        "Received \(results.count) RecordInfo responses from CloudKit"
      )

      // Filter out error responses using isError property
      let successfulRecords = results.filter { !$0.isError }
      let failedCount = results.count - successfulRecords.count

      totalSucceeded += successfulRecords.count
      totalFailed += failedCount

      if failedCount > 0 {
        print("   ⚠️  \(failedCount) operations failed (see verbose logs for details)")
        print("   ✓ \(successfulRecords.count) records confirmed")

        // Log error details in verbose mode
        let errorRecords = results.filter { $0.isError }
        for errorRecord in errorRecords {
          Self.logger.debug(
            "Error: recordName=\(errorRecord.recordName), reason=\(errorRecord.recordType)"
          )
        }
      } else {
        Self.logger.info(
          "CloudKit confirmed \(successfulRecords.count) records"
        )
      }
    }

    print("\n📊 \(recordType) Sync Summary:")
    print("   Attempted: \(operations.count) operations")
    print("   Succeeded: \(totalSucceeded) records")

    if totalFailed > 0 {
      print("   ❌ Failed: \(totalFailed) operations")
      Self.logger.debug(
        "Use --verbose flag to see CloudKit error details (serverErrorCode, reason, etc.)"
      )
    }
  }
}

// MARK: - Loggable Conformance
extension BushelCloudKitService: Loggable {
  public static let loggingCategory: BushelLogging.Category = .data
}
