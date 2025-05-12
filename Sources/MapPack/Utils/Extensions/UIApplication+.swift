//
//  UIApplication+Extensions.swift
//  Core
//
//  Created by applebro on 13/09/24.
//

import Foundation
import SwiftUI

extension UIApplication {
    
    var safeArea: UIEdgeInsets {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.safeAreaInsets
    }
    
    var screenFrame: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.frame
    }
    
    var safeAreaFrame: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.safeAreaLayoutGuide.layoutFrame
    }
    
    var statusBarHeight: CGRect {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return .zero
        }
        
        return activeView.windowScene?.statusBarManager?.statusBarFrame ?? .zero
    }
    
    var hasDynamicIsland: Bool {
        safeArea.top > 51
    }
    
    func dismissKeyboard() {
        guard let activeView = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {
            return
        }
        

        activeView.endEditing(true)
    }
}
