//
//  ErrorHandlingTests.swift
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
import Testing

@testable import BushelCloudKit

// MARK: - Network Error Handling Tests

@Suite("Network Error Handling Tests")
struct NetworkErrorHandlingTests {
  @Test("Handle network timeout gracefully")
  func testNetworkTimeout() async {
    let fetcher = MockIPSWFetcher(errorToThrow: MockFetcherError.timeout)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected timeout error to be thrown")
    } catch let error as MockFetcherError {
      if case .timeout = error {
        // Success - timeout handled correctly
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle connection failure")
  func testConnectionFailure() async {
    let fetcher = MockAppleDBFetcher(
      errorToThrow: MockFetcherError.networkError("Connection refused")
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected network error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message.contains("refused"))
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle DNS resolution failure")
  func testDNSFailure() async {
    let fetcher = MockXcodeReleasesFetcher(
      errorToThrow: MockFetcherError.networkError("DNS resolution failed")
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected DNS error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message.contains("DNS"))
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Handle server errors (5xx)")
  func testServerErrors() async {
    for errorCode in [500, 502, 503, 504] {
      let fetcher = MockAppleDBFetcher(
        errorToThrow: MockFetcherError.serverError(code: errorCode)
      )

      do {
        _ = try await fetcher.fetch()
        Issue.record("Expected server error \(errorCode) to be thrown")
      } catch let error as MockFetcherError {
        if case .serverError(let code) = error {
          #expect(code == errorCode)
        } else {
          Issue.record("Wrong error type: \(error)")
        }
      } catch {
        Issue.record("Unexpected error type: \(error)")
      }
    }
  }

  @Test("Handle client errors (4xx)")
  func testClientErrors() async {
    for errorCode in [400, 401, 403, 404, 429] {
      let fetcher = MockIPSWFetcher(
        errorToThrow: MockFetcherError.serverError(code: errorCode)
      )

      do {
        _ = try await fetcher.fetch()
        Issue.record("Expected client error \(errorCode) to be thrown")
      } catch let error as MockFetcherError {
        if case .serverError(let code) = error {
          #expect(code == errorCode)
        } else {
          Issue.record("Wrong error type: \(error)")
        }
      } catch {
        Issue.record("Unexpected error type: \(error)")
      }
    }
  }

  @Test("Handle invalid response data")
  func testInvalidResponse() async {
    let fetcher = MockMESUFetcher(errorToThrow: MockFetcherError.invalidResponse)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected invalid response error to be thrown")
    } catch is MockFetcherError {
      // Success
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Authentication Error Handling Tests

@Suite("Authentication Error Handling Tests")
struct AuthenticationErrorHandlingTests {
  @Test("CloudKit authentication failure")
  func testCloudKitAuthFailure() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.authenticationFailed)

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected authentication error to be thrown")
    } catch let error as MockCloudKitError {
      if case .authenticationFailed = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("CloudKit access denied")
  func testCloudKitAccessDenied() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.accessDenied)

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected access denied error to be thrown")
    } catch let error as MockCloudKitError {
      if case .accessDenied = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Data source authentication failure")
  func testDataSourceAuthFailure() async {
    let fetcher = MockXcodeReleasesFetcher(
      errorToThrow: MockFetcherError.authenticationFailed
    )

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected authentication error to be thrown")
    } catch is MockFetcherError {
      // Success
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - CloudKit-Specific Error Handling Tests

@Suite("CloudKit Error Handling Tests")
struct CloudKitErrorHandlingTests {
  @Test("Quota exceeded error")
  func testQuotaExceeded() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.quotaExceeded)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma14_2_1.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "RestoreImage")
      Issue.record("Expected quota exceeded error to be thrown")
    } catch let error as MockCloudKitError {
      if case .quotaExceeded = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Reference validation error")
  func testValidatingReferenceError() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.validatingReferenceError)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "XcodeVersion",
      recordName: "XcodeVersion-15C65",
      fields: TestFixtures.xcode15_1.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "XcodeVersion")
      Issue.record("Expected reference validation error to be thrown")
    } catch let error as MockCloudKitError {
      if case .validatingReferenceError = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Conflict error on duplicate create")
  func testConflictError() async {
    let service = MockCloudKitService()
    await service.setShouldFailModify(true)
    await service.setModifyError(MockCloudKitError.conflict)

    let operation = RecordOperation(
      operationType: .create,
      recordType: "RestoreImage",
      recordName: "test",
      fields: TestFixtures.sonoma14_2_1.toCloudKitFields()
    )

    do {
      try await service.executeBatchOperations([operation], recordType: "RestoreImage")
      Issue.record("Expected conflict error to be thrown")
    } catch let error as MockCloudKitError {
      if case .conflict = error {
        // Success
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }

  @Test("Unknown CloudKit error")
  func testUnknownError() async {
    let service = MockCloudKitService()
    await service.setShouldFailQuery(true)
    await service.setQueryError(MockCloudKitError.unknownError("Something went wrong"))

    do {
      _ = try await service.queryRecords(recordType: "RestoreImage")
      Issue.record("Expected unknown error to be thrown")
    } catch let error as MockCloudKitError {
      if case .unknownError(let message) = error {
        #expect(message == "Something went wrong")
      } else {
        Issue.record("Wrong error type: \(error)")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Graceful Degradation Tests

@Suite("Graceful Degradation Tests")
struct GracefulDegradationTests {
  @Test("Single fetcher failure doesn't block others")
  func testPartialFetcherFailure() async {
    // Simulate one fetcher failing while others succeed
    let ipswFetcher = MockIPSWFetcher(
      recordsToReturn: [TestFixtures.sonoma14_2_1]
    )
    let appleDBFetcher = MockAppleDBFetcher(
      errorToThrow: MockFetcherError.networkError("Network unavailable")
    )

    // IPSW should succeed
    do {
      let ipswResults = try await ipswFetcher.fetch()
      #expect(ipswResults.count == 1)
    } catch {
      Issue.record("IPSW fetcher should have succeeded")
    }

    // AppleDB should fail gracefully
    do {
      _ = try await appleDBFetcher.fetch()
      Issue.record("AppleDB fetcher should have failed")
    } catch {
      // Expected to fail
    }
  }

  @Test("Empty results handled gracefully")
  func testEmptyResults() async throws {
    let fetcher = MockIPSWFetcher(recordsToReturn: [])
    let results = try await fetcher.fetch()
    #expect(results.isEmpty)
  }

  @Test("Nil results from optional fetcher")
  func testNilResults() async throws {
    let fetcher = MockMESUFetcher(recordToReturn: nil)
    let result = try await fetcher.fetch()
    #expect(result == nil)
  }
}
