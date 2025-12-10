//
//  BushelCloudCLI.swift
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
import BushelCloudKit

@main
internal struct BushelCloudCLI: AsyncParsableCommand {
  internal static let configuration = CommandConfiguration(
    commandName: "bushel-cloud",
    abstract: "CloudKit version history tool for Bushel virtualization",
    discussion: """
      A command-line tool demonstrating MistKit's CloudKit Web Services capabilities.

      Manages macOS restore images, Xcode versions, and Swift compiler versions
      in CloudKit for use with Bushel's virtualization workflow.
      """,
    version: "1.0.0",
    subcommands: [
      SyncCommand.self,
      StatusCommand.self,
      ListCommand.self,
      ExportCommand.self,
      ClearCommand.self,
    ],
    defaultSubcommand: SyncCommand.self
  )
}
