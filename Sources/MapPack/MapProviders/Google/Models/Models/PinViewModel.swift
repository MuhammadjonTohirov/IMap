//
//  PinViewModel.swift
//  IldamMap
//
//  Created by applebro on 09/09/24.
//

import Foundation
import SwiftUI
import Combine

public enum PinState: Hashable, Equatable, Identifiable {
    public var id: String {
        switch self {
        case .loading:
            return "loading"
        case .waiting:
            return "waiting"
        case .initial:
            return "initial"
        case .pinning:
            return "pinning"
        case .searching:
            return "searching"
        }
    }
    
    case loading
    case pinning
    case waiting(time: String, unit: String)
    case initial
    case searching
}


public class PinViewModel: ObservableObject {
    @Published public var state: PinState = .initial
    
    public init() {
        
    }
    
    open func set(state: PinState) {
        debugPrint("Set pin state \(state.id)")
        if state == .initial {
            print(#file, #function, #line)
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            self.state = state
        }
    }
}
