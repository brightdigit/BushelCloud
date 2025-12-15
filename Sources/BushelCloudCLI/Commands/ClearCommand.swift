//
//  ClearCommand.swift
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

struct ClearCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "clear",
    abstract: "Delete all records from CloudKit",
    discussion: """
      Deletes all RestoreImage, XcodeVersion, and SwiftVersion records from
      the CloudKit public database.

      ⚠️  WARNING: This operation cannot be undone!
      """
  )

  // MARK: - Required Options

  @Option(name: .shortAndLong, help: "CloudKit container identifier")
  var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

  @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
  var keyID: String = ""

  @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
  var keyFile: String = ""

  // MARK: - Options

  @Flag(name: .shortAndLong, help: "Skip confirmation prompt")
  var yes: Bool = false

  @Flag(
    name: .shortAndLong,
    help:
      "Enable verbose logging to see detailed CloudKit operations and learn MistKit usage patterns")
  var verbose: Bool = false

  // MARK: - Execution

  mutating func run() async throws {
    // Enable verbose console output if requested
    ConsoleOutput.isVerbose = verbose

    // Get Server-to-Server credentials from environment if not provided
    let resolvedKeyID =
      keyID.isEmpty ? ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] ?? "" : keyID

    let resolvedKeyFile =
      keyFile.isEmpty
      ? ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"] ?? "" : keyFile

    guard !resolvedKeyID.isEmpty && !resolvedKeyFile.isEmpty else {
      print("❌ Error: CloudKit Server-to-Server Key credentials are required")
      print("")
      print("   Provide via command-line flags:")
      print("     --key-id YOUR_KEY_ID --key-file ./private-key.pem")
      print("")
      print("   Or set environment variables:")
      print("     export CLOUDKIT_KEY_ID=\"YOUR_KEY_ID\"")
      print("     export CLOUDKIT_PRIVATE_KEY_PATH=\"./private-key.pem\"")
      print("")
      print("   Get your Server-to-Server Key from:")
      print("   https://icloud.developer.apple.com/dashboard/")
      print("   Navigate to: API Access → Server-to-Server Keys")
      print("")
      print("   Important:")
      print("   • Download and save the private key .pem file securely")
      print("   • Never commit .pem files to version control!")
      print("")
      throw ExitCode.failure
    }

    // Confirm deletion unless --yes flag is provided
    if !yes {
      print("\n⚠️  WARNING: This will delete ALL records from CloudKit!")
      print("   Container: \(containerIdentifier)")
      print("   Database: public (development)")
      print("")
      print("   This operation cannot be undone.")
      print("")
      print("   Type 'yes' to confirm: ", terminator: "")

      guard let response = readLine(), response.lowercased() == "yes" else {
        print("\n❌ Operation cancelled")
        throw ExitCode.failure
      }
    }

    // Create sync engine
    let syncEngine = try SyncEngine(
      containerIdentifier: containerIdentifier,
      keyID: resolvedKeyID,
      privateKeyPath: resolvedKeyFile
    )

    // Execute clear
    do {
      try await syncEngine.clear()
      print("\n✅ All records have been deleted from CloudKit")
    } catch {
      printError(error)
      throw ExitCode.failure
    }
  }

  // MARK: - Private Helpers

  private func printError(_ error: Error) {
    print("\n❌ Clear failed: \(error.localizedDescription)")
    print("\n💡 Troubleshooting:")
    print("   • Verify your API token is valid")
    print("   • Check your internet connection")
    print("   • Ensure the CloudKit container exists")
  }
}
