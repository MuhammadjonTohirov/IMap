//
//  String+Extensions.swift
//  NetworkLayer
//
//  Created by applebro on 09/09/24.
//

import Foundation

extension String {
    var nilIfEmpty: String? {
        return self.isEmpty ? nil : self
    }
}
