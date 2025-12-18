//
//  FieldValue+URL.swift
//  BushelCloud
//
//  Created by Claude Code
//

public import Foundation
public import MistKit

extension FieldValue {
  /// Create a string FieldValue from a URL
  ///
  /// This convenience initializer converts a URL to its absolute string representation
  /// for storage in CloudKit. CloudKit stores URLs as STRING fields, so this provides
  /// automatic conversion.
  ///
  /// ## Usage
  /// ```swift
  /// let url = URL(string: "https://example.com/file.dmg")!
  /// let fieldValue = FieldValue(url: url)
  /// // Equivalent to: FieldValue.string("https://example.com/file.dmg")
  /// ```
  ///
  /// - Parameter url: The URL to convert to a FieldValue
  public init(url: URL) {
    self = .string(url.absoluteString)
  }

  /// Extract a URL from a FieldValue
  ///
  /// This convenience property attempts to convert a string FieldValue back to a URL.
  /// Returns `nil` if the FieldValue is not a string type or if the string cannot be
  /// parsed as a valid URL.
  ///
  /// ## Usage
  /// ```swift
  /// let fieldValue: FieldValue = .string("https://example.com/file.dmg")
  /// if let url = fieldValue.urlValue {
  ///   print(url.absoluteString) // "https://example.com/file.dmg"
  /// }
  /// ```
  ///
  /// - Returns: The URL if this is a string FieldValue with a valid URL format, otherwise `nil`
  public var urlValue: URL? {
    if case .string(let value) = self {
      return URL(string: value)
    }
    return nil
  }
}
