//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 12/05/25.
//

import Foundation

struct Logging {
    static func l(tag: String = "MapPack", _ message: @autoclosure @escaping () -> String) {
        #if DEBUG
        print("[\(tag)] \(message())")
        #endif
    }
}
