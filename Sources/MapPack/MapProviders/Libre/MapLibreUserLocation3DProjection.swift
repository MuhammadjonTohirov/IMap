import CoreGraphics
import simd

struct MapLibreUserLocation3DProjection {
    static let sceneLocationAnchor = SIMD3<Float>.zero

    static func cameraPosition(
        pitch: CGFloat,
        distance: Float
    ) -> SIMD3<Float> {
        let radians = Float(clampedPitch(pitch) * .pi / 180)
        return SIMD3<Float>(
            0,
            distance * cos(radians),
            distance * sin(radians)
        )
    }

    static func shadowVerticalScale(pitch: CGFloat) -> CGFloat {
        let radians = clampedPitch(pitch) * .pi / 180
        return max(0.25, cos(radians))
    }

    static func screenLocationAnchor(in bounds: CGRect) -> CGPoint {
        CGPoint(x: bounds.midX, y: bounds.midY)
    }

    private static func clampedPitch(_ pitch: CGFloat) -> CGFloat {
        min(max(pitch, 0), 85)
    }
}
