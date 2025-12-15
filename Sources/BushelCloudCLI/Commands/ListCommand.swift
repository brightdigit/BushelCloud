//
//  ListCommand.swift
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

import ArgumentParser
import BushelCloudData
import BushelCloudKit
import Foundation
import MistKit

struct ListCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "list",
    abstract: "List CloudKit records",
    discussion: """
      Displays all records stored in CloudKit across different record types.

      By default, lists all record types. Use flags to show specific types only.
      """
  )

  // MARK: - Required Options

  @Option(name: .shortAndLong, help: "CloudKit container identifier")
  var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

  @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
  var keyID: String = ""

  @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
  var keyFile: String = ""

  // MARK: - Filter Options

  @Flag(name: .long, help: "List only restore images")
  var restoreImages: Bool = false

  @Flag(name: .long, help: "List only Xcode versions")
  var xcodeVersions: Bool = false

  @Flag(name: .long, help: "List only Swift versions")
  var swiftVersions: Bool = false

  // MARK: - Execution

  mutating func run() async throws {
    // Get Server-to-Server credentials from environment if not provided
    let resolvedKeyID =
      keyID.isEmpty ? ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] ?? "" : keyID

    let resolvedKeyFile =
      keyFile.isEmpty
      ? ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"] ?? "" : keyFile

    guard !resolvedKeyID.isEmpty, !resolvedKeyFile.isEmpty else {
      print("❌ Error: CloudKit Server-to-Server Key credentials are required")
      print("")
      print("   Provide via command-line flags:")
      print("     --key-id YOUR_KEY_ID --key-file ./private-key.pem")
      print("")
      print("   Or set environment variables:")
      print("     export CLOUDKIT_KEY_ID=\"YOUR_KEY_ID\"")
      print("     export CLOUDKIT_PRIVATE_KEY_PATH=\"./private-key.pem\"")
      print("")
      throw ExitCode.failure
    }

    // Create CloudKit service
    let cloudKitService = try BushelCloudKitService(
      containerIdentifier: containerIdentifier,
      keyID: resolvedKeyID,
      privateKeyPath: resolvedKeyFile
    )

    // Determine what to list based on flags
    let listAll = !restoreImages && !xcodeVersions && !swiftVersions

    if listAll {
      try await cloudKitService.listAllRecords()
    } else {
      if restoreImages {
        try await cloudKitService.list(RestoreImageRecord.self)
      }
      if xcodeVersions {
        try await cloudKitService.list(XcodeVersionRecord.self)
      }
      if swiftVersions {
        try await cloudKitService.list(SwiftVersionRecord.self)
      }
    }
  }
}
