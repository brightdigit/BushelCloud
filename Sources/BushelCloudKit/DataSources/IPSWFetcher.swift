//
//  IPSWFetcher.swift
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

import BushelFoundation
import Foundation
import IPSWDownloads
import OpenAPIURLSession
import OSVer

/// Fetcher for macOS restore images using the IPSWDownloads package
struct IPSWFetcher: DataSourceFetcher, Sendable {
  typealias Record = [RestoreImageRecord]
  /// Fetch all VirtualMac2,1 restore images from ipsw.me
  func fetch() async throws -> [RestoreImageRecord] {
    // Fetch Last-Modified header to know when ipsw.me data was updated
    let ipswURL = URL(string: "https://api.ipsw.me/v4/device/VirtualMac2,1?type=ipsw")!
    let lastModified = await HTTPHeaderHelpers.fetchLastModified(from: ipswURL)

    // Create IPSWDownloads client with URLSession transport
    let client = IPSWDownloads(
      transport: URLSessionTransport()
    )

    // Fetch device firmware data for VirtualMac2,1 (macOS virtual machines)
    let device = try await client.device(
      withIdentifier: "VirtualMac2,1",
      type: .ipsw
    )

    return device.firmwares.map { firmware in
      RestoreImageRecord(
        version: firmware.version.description,  // OSVer -> String
        buildNumber: firmware.buildid,
        releaseDate: firmware.releasedate,
        downloadURL: firmware.url.absoluteString,
        fileSize: firmware.filesize,
        sha256Hash: "",  // Not provided by ipsw.me; backfilled from AppleDB during merge
        sha1Hash: firmware.sha1sum?.hexString ?? "",
        isSigned: firmware.signed,
        isPrerelease: false,  // ipsw.me doesn't include beta releases
        source: "ipsw.me",
        notes: nil,
        sourceUpdatedAt: lastModified  // When ipsw.me last updated their database
      )
    }
  }
}

// MARK: - Data Extension

extension Data {
  /// Convert Data to hexadecimal string
  fileprivate var hexString: String {
    map { String(format: "%02x", $0) }.joined()
  }
}
