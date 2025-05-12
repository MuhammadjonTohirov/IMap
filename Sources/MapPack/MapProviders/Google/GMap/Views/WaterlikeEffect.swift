//
//  WaterlikeEffect.swift
//  IMap
//
//  Created by applebro on 24/09/24.
//

import Foundation
import SwiftUI

struct RippleEffectModifier: ViewModifier {
    @State private var ripple1 = false
    @State private var ripple2 = false
    @State private var ripple3 = false
    
    var color: Color
    var circleSize: CGFloat
    var rippleSize: CGFloat
    var lineWidth: CGFloat
    var duration: Double
    var isActive: Bool
    
    func body(content: Content) -> some View {
        ZStack {
            if isActive {
                // First ripple
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: lineWidth)
                    .scaleEffect(ripple1 ? rippleSize : 0.1)
                    .opacity(ripple1 ? 0.0 : 1.0)
                    .frame(width: circleSize, height: circleSize)
                    .onAppear {
                        startRipple1Animation()
                    }
                
                // Second ripple (delayed)
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: lineWidth)
                    .scaleEffect(ripple2 ? rippleSize : 0.1)
                    .opacity(ripple2 ? 0.0 : 1.0)
                    .frame(width: circleSize, height: circleSize)
                    .onAppear {
                        startRipple2Animation()
                    }
                
                // Third ripple (delayed further)
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: lineWidth)
                    .scaleEffect(ripple3 ? rippleSize : 0.1)
                    .opacity(ripple3 ? 0.0 : 1.0)
                    .frame(width: circleSize, height: circleSize)
                    .onAppear {
                        startRipple3Animation()
                    }
            }
            
            // The content (any view) in the center
            content
        }
        .onChange(of: isActive) { newValue in
            if !newValue {
                // Reset ripples when deactivated
                ripple1 = false
                ripple2 = false
                ripple3 = false
            } else {
                // Restart animation when activated
                startRipple1Animation()
                startRipple2Animation()
                startRipple3Animation()
            }
        }
    }
    
    // Helper functions for animation
    private func startRipple1Animation() {
        withAnimation(Animation.easeOut(duration: duration).repeatForever(autoreverses: false)) {
            ripple1 = true
        }
    }
    
    private func startRipple2Animation() {
        withAnimation(Animation.easeOut(duration: duration).repeatForever(autoreverses: false).delay(duration / 3)) {
            ripple2 = true
        }
    }
    
    private func startRipple3Animation() {
        withAnimation(Animation.easeOut(duration: duration).repeatForever(autoreverses: false).delay(2 * duration / 3)) {
            ripple3 = true
        }
    }
}

extension View {
    func rippleEffect(
        isActive: Bool,
        color: Color = .blue,
        circleSize: CGFloat = 30,
        rippleSize: CGFloat = 1.5,
        lineWidth: CGFloat = 3,
        duration: Double = 1.5
    ) -> some View {
        self.modifier(RippleEffectModifier(color: color, circleSize: circleSize, rippleSize: rippleSize, lineWidth: lineWidth, duration: duration, isActive: isActive))
    }
}

struct RippleEffectExample: View {
    @State private var isRippleActive = false
    
    var body: some View {
        VStack(spacing: 50) {
            // Toggle button to activate/deactivate ripple effect
            Toggle("Toggle Ripple Effect", isOn: $isRippleActive)
                .padding()
            
            // Applying ripple effect to a circle
            Circle()
                .fill(Color.blue)
                .frame(width: 30, height: 30)
                .rippleEffect(isActive: isRippleActive, color: .blue, circleSize: 30, rippleSize: 2.0, lineWidth: 3, duration: 1.5)
            
            // Applying ripple effect to a custom image
            Image(systemName: "star.fill")
                .resizable()
                .frame(width: 50, height: 50)
                .foregroundColor(.yellow)
                .rippleEffect(isActive: isRippleActive, color: .yellow, circleSize: 50, rippleSize: 2.0, lineWidth: 2, duration: 1.8)
        }
        .padding()
    }
}

#Preview {
    RippleEffectExample()
}
