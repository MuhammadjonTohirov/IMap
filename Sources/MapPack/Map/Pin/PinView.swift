//
//  PinView.swift
//  IldamMap
//
//  Created by applebro on 09/09/24.
//

import Foundation
import SwiftUI

public struct PinView: View {
    @ObservedObject var vm: PinViewModel// = .init()
    @State private var isPinAnimating: Bool = false
    @State private var isScaleAnimating: Bool = false
    
    private var shift: CGFloat {
        if vm.state == .pinning {
            return isPinAnimating ? 12 : 6
        }
        
        return 0
    }
    
    private var offsetY: CGFloat {
        if vm.state == .searching {
            return 0
        }
        
        return -35 - shift
    }
    
    public init(vm: PinViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        innerBody
            .ignoresSafeArea(.keyboard, edges: .all)
            .onChange(of: vm.state) { newValue in
                isScaleAnimating = newValue == .steady
            }
    }
    
    var innerBody: some View {
        ZStack {
            VStack(spacing: 0) {
                Circle()
                    .frame(width: 50)
                    .foregroundStyle(Color.iPrimary)
                    .overlay {
                        pinCircleOverlay
                    }
                
                Rectangle()
                    .frame(width: 2, height: 20)
                    .visibility(vm.state != .searching)
            }
            .background {
                Rectangle()
                    .foregroundStyle(Color.black.opacity(0))
            }
            .onChange(of: vm.state, perform: { newState in
                switch newState {
                case .pinning:
                    withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                        isPinAnimating = true
                    }
                default:
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPinAnimating = false
                    }
                }
            })
            .offset(y: offsetY)
            
            Circle()
                .frame(width: 8, height: 8)
                .visibility(vm.state != .searching)
        }
    }
    
    private var pinCircleOverlay: some View {
        ZStack {
            // Pinning overlay (white circle)
            pinningOverlay
                .opacity(vm.state == .initial || vm.state == .loading || vm.state == .searching ? 1 : 0)
            
            // Loading overlay (spinner)
            loadingOverlay
                .opacity(vm.state == .pinning ? 1 : 0)
            
            // Waiting overlay (timer)
            if case .waiting(let time, let unit) = vm.state {
                waitingOverlay(time: time, unit: unit)
                    .opacity(1)
            }
            else if case .steady = vm.state {
                Circle()
                    .frame(width: 28, height: 28)
                    .opacity(isScaleAnimating ? 0.5 : 1)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever(autoreverses: true),
                        value: isScaleAnimating
                    )
                    .foregroundStyle(Color.pinOverlayCircle)
            }
            else {
                Circle()
                    .frame(width: 28, height: 28)
                    .foregroundStyle(Color.pinOverlayCircle)
                    .opacity(0)
            }
        }
    }
    
    private var loadingOverlay: some View {
        Circle()
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.clear)
            .overlay {
                LoadingCircleDoubleRunner(size: 24)
            }
    }
    
    private var pinningOverlay: some View {
        Circle()
            .frame(width: 28, height: 28)
            .foregroundStyle(Color.pinOverlayCircle)
    }
    
    private func waitingOverlay(time: String, unit: String) -> some View {
        VStack {
            Text(time)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.pinLabel)
            
            Text(unit.uppercased())
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.pinLabel)
        }
        .frame(height: 48)
    }
}
