//
//  Codable+Extensions.swift
//  NetworkLayer
//
//  Created by applebro on 09/09/24.
//

import Foundation

/// Shared, reusable JSON coders.
///
/// `JSONEncoder`/`JSONDecoder` are comparatively expensive to instantiate and are
/// safe to reuse across concurrent encode/decode calls, so hoisting them to shared
/// instances avoids a per-call allocation.
enum JSONCoders {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
}

/// Errors thrown while converting `Encodable` values into other representations.
enum EncodableConversionError: Error {
    case notADictionary
}

extension Encodable {
    /// Turns json into a Dictionary
    func asDictionary() throws -> [String: Any] {
        let data = try JSONCoders.encoder.encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw EncodableConversionError.notADictionary
        }
        return dictionary
    }

    /// Turn json into a string
    var asString: String {
        guard let jsonData = try? JSONCoders.encoder.encode(self) else {
            return ""
        }

        return String(data: jsonData, encoding: .utf8) ?? ""
    }

    var asData: Data? {
        try? JSONCoders.encoder.encode(self)
    }
}
