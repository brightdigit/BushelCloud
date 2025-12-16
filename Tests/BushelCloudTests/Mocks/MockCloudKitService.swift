//
//  MockCloudKitService.swift
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

import Foundation
import MistKit

@testable import BushelCloudKit

// MARK: - Mock CloudKit Errors

enum MockCloudKitError: Error, Sendable {
  case authenticationFailed
  case accessDenied
  case quotaExceeded
  case validatingReferenceError
  case conflict
  case networkError
  case unknownError(String)
}

// MARK: - Mock CloudKit Service

/// Mock CloudKit service for testing without real CloudKit calls
actor MockCloudKitService: RecordManaging {
  // MARK: - Storage

  private var storedRecords: [String: [RecordInfo]] = [:]
  private var operationHistory: [[RecordOperation]] = []

  // MARK: - Configuration

  var shouldFailQuery: Bool = false
  var shouldFailModify: Bool = false
  var queryError: (any Error)?
  var modifyError: (any Error)?
  var simulatePartialFailure: Bool = false

  // MARK: - Inspection Methods

  func getStoredRecords(ofType recordType: String) -> [RecordInfo] {
    storedRecords[recordType] ?? []
  }

  func getOperationHistory() -> [[RecordOperation]] {
    operationHistory
  }

  func clearStorage() {
    storedRecords.removeAll()
    operationHistory.removeAll()
  }

  // MARK: - RecordManaging Protocol

  func queryRecords(recordType: String) async throws -> [RecordInfo] {
    if shouldFailQuery {
      throw queryError ?? MockCloudKitError.networkError
    }
    return storedRecords[recordType] ?? []
  }

  func executeBatchOperations(
    _ operations: [RecordOperation],
    recordType: String
  ) async throws {
    operationHistory.append(operations)

    if shouldFailModify {
      throw modifyError ?? MockCloudKitError.networkError
    }

    // Process operations
    for operation in operations {
      switch operation.operationType {
      case .create, .forceReplace:
        let recordInfo = createRecordInfo(from: operation)
        var records = storedRecords[recordType] ?? []

        // For forceReplace, remove existing record with same name
        if operation.operationType == .forceReplace {
          records.removeAll { $0.recordName == operation.recordName }
        }

        records.append(recordInfo)
        storedRecords[recordType] = records

      case .delete:
        guard let recordName = operation.recordName else { continue }
        storedRecords[recordType]?.removeAll { $0.recordName == recordName }

      case .update:
        guard let recordName = operation.recordName else { continue }
        if let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName })
        {
          let updatedRecordInfo = createRecordInfo(from: operation)
          storedRecords[recordType]?[index] = updatedRecordInfo
        }

      case .forceUpdate:
        guard let recordName = operation.recordName else { continue }
        let updatedRecordInfo = createRecordInfo(from: operation)
        if let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName })
        {
          storedRecords[recordType]?[index] = updatedRecordInfo
        } else {
          var records = storedRecords[recordType] ?? []
          records.append(updatedRecordInfo)
          storedRecords[recordType] = records
        }

      case .replace:
        guard let recordName = operation.recordName else { continue }
        if let index = storedRecords[recordType]?.firstIndex(where: { $0.recordName == recordName })
        {
          let updatedRecordInfo = createRecordInfo(from: operation)
          storedRecords[recordType]?[index] = updatedRecordInfo
        }

      case .forceDelete:
        guard let recordName = operation.recordName else { continue }
        storedRecords[recordType]?.removeAll { $0.recordName == recordName }
      }
    }
  }

  // MARK: - Helper Methods

  private func createRecordInfo(from operation: RecordOperation) -> RecordInfo {
    RecordInfo(
      recordName: operation.recordName ?? UUID().uuidString,
      recordType: operation.recordType,
      recordChangeTag: UUID().uuidString,
      fields: operation.fields
    )
  }
}
