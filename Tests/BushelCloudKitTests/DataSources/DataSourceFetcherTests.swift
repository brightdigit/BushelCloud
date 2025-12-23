//
//  DataSourceFetcherTests.swift
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
import Testing

@testable import BushelFoundation

// MARK: - Mock IPSW Fetcher Tests

@Suite("Mock IPSW Fetcher Tests")
struct MockIPSWFetcherTests {
  @Test("Successful fetch returns records")
  func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.sonoma14_2_1, TestFixtures.sequoia15_0_beta]
    let fetcher = MockIPSWFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 2)
    #expect(result[0].buildNumber == "23C71")
    #expect(result[1].buildNumber == "24A5264n")
  }

  @Test("Empty fetch returns empty array")
  func testEmptyFetch() async throws {
    let fetcher = MockIPSWFetcher(recordsToReturn: [])

    let result = try await fetcher.fetch()

    #expect(result.isEmpty)
  }

  @Test("Network error throws expected error")
  func testNetworkError() async {
    let expectedError = MockFetcherError.networkError("Connection timeout")
    let fetcher = MockIPSWFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch let error as MockFetcherError {
      if case .networkError(let message) = error {
        #expect(message == "Connection timeout")
      } else {
        Issue.record("Wrong error type thrown")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Mock AppleDB Fetcher Tests

@Suite("Mock AppleDB Fetcher Tests")
struct MockAppleDBFetcherTests {
  @Test("Successful fetch returns records")
  func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.sonoma14_2_1_appledb]
    let fetcher = MockAppleDBFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 1)
    #expect(result[0].source == "appledb.dev")
  }

  @Test("Server error throws expected error")
  func testServerError() async {
    let expectedError = MockFetcherError.serverError(code: 500)
    let fetcher = MockAppleDBFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch let error as MockFetcherError {
      if case .serverError(let code) = error {
        #expect(code == 500)
      } else {
        Issue.record("Wrong error type thrown")
      }
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Mock MESU Fetcher Tests

@Suite("Mock MESU Fetcher Tests")
struct MockMESUFetcherTests {
  @Test("Successful fetch returns single record")
  func testSuccessfulFetch() async throws {
    let expectedRecord = TestFixtures.sonoma14_2_1_mesu
    let fetcher = MockMESUFetcher(recordToReturn: expectedRecord)

    let result = try await fetcher.fetch()

    #expect(result != nil)
    #expect(result?.source == "mesu.apple.com")
    #expect(result?.buildNumber == "23C71")
  }

  @Test("Empty fetch returns nil")
  func testEmptyFetch() async throws {
    let fetcher = MockMESUFetcher(recordToReturn: nil)

    let result = try await fetcher.fetch()

    #expect(result == nil)
  }

  @Test("Invalid response error")
  func testInvalidResponse() async {
    let expectedError = MockFetcherError.invalidResponse
    let fetcher = MockMESUFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch is MockFetcherError {
      // Success - error was thrown as expected
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Mock Xcode Releases Fetcher Tests

@Suite("Mock Xcode Releases Fetcher Tests")
struct MockXcodeReleasesFetcherTests {
  @Test("Successful fetch returns records")
  func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.xcode15_1, TestFixtures.xcode16_0_beta]
    let fetcher = MockXcodeReleasesFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 2)
    #expect(result[0].version == "15.1")
    #expect(result[1].version == "16.0 Beta 1")
  }

  @Test("Authentication error")
  func testAuthenticationError() async {
    let expectedError = MockFetcherError.authenticationFailed
    let fetcher = MockXcodeReleasesFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch is MockFetcherError {
      // Success - error was thrown as expected
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}

// MARK: - Mock Swift Version Fetcher Tests

@Suite("Mock Swift Version Fetcher Tests")
struct MockSwiftVersionFetcherTests {
  @Test("Successful fetch returns records")
  func testSuccessfulFetch() async throws {
    let expectedRecords = [TestFixtures.swift5_9_2, TestFixtures.swift6_0_snapshot]
    let fetcher = MockSwiftVersionFetcher(recordsToReturn: expectedRecords)

    let result = try await fetcher.fetch()

    #expect(result.count == 2)
    #expect(result[0].version == "5.9.2")
    #expect(result[1].version == "6.0")
  }

  @Test("Timeout error")
  func testTimeoutError() async {
    let expectedError = MockFetcherError.timeout
    let fetcher = MockSwiftVersionFetcher(errorToThrow: expectedError)

    do {
      _ = try await fetcher.fetch()
      Issue.record("Expected error to be thrown")
    } catch is MockFetcherError {
      // Success - error was thrown as expected
    } catch {
      Issue.record("Unexpected error type: \(error)")
    }
  }
}
