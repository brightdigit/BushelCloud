//
//  MockDataSourceFetchers.swift
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

@testable import BushelCloudData
@testable import BushelCloudKit

// MARK: - Mock Errors

enum MockFetcherError: Error, Sendable {
  case networkError(String)
  case authenticationFailed
  case invalidResponse
  case timeout
  case serverError(code: Int)
}

// MARK: - Mock IPSW Fetcher

/// Mock fetcher for IPSW data source
struct MockIPSWFetcher: DataSourceFetcher, Sendable {
  typealias Record = [RestoreImageRecord]

  let recordsToReturn: [RestoreImageRecord]
  let errorToThrow: (any Error)?

  init(recordsToReturn: [RestoreImageRecord] = [], errorToThrow: (any Error)? = nil) {
    self.recordsToReturn = recordsToReturn
    self.errorToThrow = errorToThrow
  }

  func fetch() async throws -> [RestoreImageRecord] {
    if let error = errorToThrow {
      throw error
    }
    return recordsToReturn
  }
}

// MARK: - Mock AppleDB Fetcher

/// Mock fetcher for AppleDB data source
struct MockAppleDBFetcher: DataSourceFetcher, Sendable {
  typealias Record = [RestoreImageRecord]

  let recordsToReturn: [RestoreImageRecord]
  let errorToThrow: (any Error)?

  init(recordsToReturn: [RestoreImageRecord] = [], errorToThrow: (any Error)? = nil) {
    self.recordsToReturn = recordsToReturn
    self.errorToThrow = errorToThrow
  }

  func fetch() async throws -> [RestoreImageRecord] {
    if let error = errorToThrow {
      throw error
    }
    return recordsToReturn
  }
}

// MARK: - Mock MESU Fetcher

/// Mock fetcher for MESU data source
struct MockMESUFetcher: DataSourceFetcher, Sendable {
  typealias Record = RestoreImageRecord?

  let recordToReturn: RestoreImageRecord?
  let errorToThrow: (any Error)?

  init(recordToReturn: RestoreImageRecord? = nil, errorToThrow: (any Error)? = nil) {
    self.recordToReturn = recordToReturn
    self.errorToThrow = errorToThrow
  }

  func fetch() async throws -> RestoreImageRecord? {
    if let error = errorToThrow {
      throw error
    }
    return recordToReturn
  }
}

// MARK: - Mock Xcode Releases Fetcher

/// Mock fetcher for Xcode Releases data source
struct MockXcodeReleasesFetcher: DataSourceFetcher, Sendable {
  typealias Record = [XcodeVersionRecord]

  let recordsToReturn: [XcodeVersionRecord]
  let errorToThrow: (any Error)?

  init(recordsToReturn: [XcodeVersionRecord] = [], errorToThrow: (any Error)? = nil) {
    self.recordsToReturn = recordsToReturn
    self.errorToThrow = errorToThrow
  }

  func fetch() async throws -> [XcodeVersionRecord] {
    if let error = errorToThrow {
      throw error
    }
    return recordsToReturn
  }
}

// MARK: - Mock Swift Version Fetcher

/// Mock fetcher for Swift version data source
struct MockSwiftVersionFetcher: DataSourceFetcher, Sendable {
  typealias Record = [SwiftVersionRecord]

  let recordsToReturn: [SwiftVersionRecord]
  let errorToThrow: (any Error)?

  init(recordsToReturn: [SwiftVersionRecord] = [], errorToThrow: (any Error)? = nil) {
    self.recordsToReturn = recordsToReturn
    self.errorToThrow = errorToThrow
  }

  func fetch() async throws -> [SwiftVersionRecord] {
    if let error = errorToThrow {
      throw error
    }
    return recordsToReturn
  }
}
