//
//  UIApplication+Extensions.swift
//  Core
//
//  Created by applebro on 13/09/24.
//

import Foundation
import SwiftUI

extension UIApplication {
    
    public var safeArea: UIEdgeInsets {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.safeAreaInsets
    }
    
    public var screenFrame: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.frame
    }
    
    public var safeAreaFrame: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.safeAreaLayoutGuide.layoutFrame
    }
    
    public var statusBarHeight: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
    
    public var hasDynamicIsland: Bool {
        safeArea.top > 51
    }
    
    public func dismissKeyboard() {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return
        }
        

        activeView.endEditing(true)
    }
}
