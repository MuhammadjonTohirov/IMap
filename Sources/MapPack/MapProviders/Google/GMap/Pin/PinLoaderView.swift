//
//  PinLoaderView.swift
//  IMap
//
//  Created by Muhammadjon Tohirov on 28/03/25.
//

import Foundation
import SwiftUI

struct LoadingCircleDoubleRunner: View {
    @State private var isRotating = false
    var size: CGFloat = 32
    
    var body: some View {
        Image("icon_half_round")
            .resizable()
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isRotating ? 360 : 0))
            .animation(
                .easeInOut(duration: 1)
                .repeatForever(autoreverses: false),
                value: isRotating
            )
            .onAppear {
                isRotating = true
            }
    }
}

#Preview(body: {
    ZStack {
        Circle()
            .foregroundStyle(.red)
        LoadingCircleDoubleRunner()
    }
})

