//
//  File.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 12/05/25.
//

import Foundation
import os

struct Logging {
    static func l(tag: String = "MapPack", _ message: @autoclosure @escaping () -> String) {
        #if DEBUG
        Logger(subsystem: "MapPack", category: tag)
            .debug("\(message(), privacy: .public)")
        #endif
    }
}
