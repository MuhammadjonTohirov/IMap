//
//  Codable+Extensions.swift
//  NetworkLayer
//
//  Created by applebro on 09/09/24.
//

import Foundation

extension Encodable {
    /// Turns json into a Dictionary
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
    
    /// Turn json into a string
    var asString: String {
        guard let jsonData = try? JSONEncoder().encode(self) else {
            return ""
        }
        
        return String(data: jsonData, encoding: .utf8) ?? ""
    }
    
    var asData: Data? {
        try? JSONEncoder().encode(self)
    }
}
