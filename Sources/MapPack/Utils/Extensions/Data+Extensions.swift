//
//  Data+Extensions.swift
//  NetworkLayer
//
//  Created by applebro on 09/09/24.
//

import Foundation

extension Data {
    func asJson() throws -> Any {
        let json = try JSONSerialization.jsonObject(with: self, options: .allowFragments)
        
        return json
    }
    
    func asJsonString() throws -> String? {
        let jsonData = try? JSONSerialization.data(withJSONObject: asJson(), options: [.prettyPrinted, .sortedKeys])
        return String.init(data: self, encoding: .utf8)
    }
}

extension NSMutableData {
    func append(_ string: String) {
        if let data = string.data(using: String.Encoding.utf8) {
            append(data)
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8, allowLossyConversion: true) {
            append(data)
        }
    }
    
    func asObject<T: Decodable>(type: T.Type) -> T? {
        try? JSONDecoder().decode(T.self, from: self)
    }
}
