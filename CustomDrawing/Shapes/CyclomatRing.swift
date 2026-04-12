import SwiftUI

/// A shape that traces an epicycloid (spirograph-style) ring by rolling a small circle
/// around the inside of a larger circle, producing petal-like loops.
///
/// The shape is parameterized by:
/// - A **thickness ratio** that controls how far the smaller circle's radius extends
///   relative to the overall radius.
/// - A **loop count** that determines how many petals appear around the ring.
/// - **Starting angles** for both the large and small circles, allowing rotation of the
///   overall pattern and its phase.
/// - A **segments per loop** value that controls curve smoothness.
///
/// The resulting path is always inscribed within the largest centered square that fits
/// the provided rect.
///
/// *Inspired by Jesse Hemmingway's "Cyclomat" app!*
///
public struct CyclomatRing: Shape {

    /// The ratio of the epicycle (small circle) diameter to the overall radius.
    /// Clamped to `0.01...0.99`. Larger values produce wider petals that extend
    /// further toward the center; smaller values produce a shape closer to a plain circle.
    public let thicknessRatio: CGFloat

    /// The number of epicycle loops (petals) distributed around the ring.
    /// Clamped to `2...360`.
    public let loopCount: Int

    /// The starting angle (in radians) of the large circle's rotation.
    /// Defaults to `-.pi / 2` so the first petal points upward.
    public let angle0: CGFloat

    /// The starting angle (in radians) of the small circle's rotation.
    /// Adjusting this shifts the phase of the petal pattern relative to the ring.
    /// Defaults to `-.pi / 2`.
    public let angle1: CGFloat

    /// The number of line segments used to approximate each epicycle loop.
    /// Clamped to `3...360`. Higher values produce smoother curves at the cost of
    /// a more complex path.
    public let segmentsPerLoop: Int

    /// Creates a new `CyclomatRing` shape.
    /// - Parameters:
    ///   - thicknessRatio: The ratio of the epicycle diameter to the overall radius. Default is `0.25`.
    ///   - loopCount: The number of petals around the ring. Default is `16`.
    ///   - angle0: The starting angle of the large circle in radians. Default is `-.pi / 2`.
    ///   - angle1: The starting angle of the small circle in radians. Default is `-.pi / 2`.
    ///   - segmentsPerLoop: The number of line segments per petal. Default is `60`.
    public init(
        thicknessRatio: CGFloat = 0.25,
        loopCount: Int = 16,
        angle0: CGFloat = -.pi / 2.0,
        angle1: CGFloat = -.pi / 2.0,
        segmentsPerLoop: Int = 60
    ) {
        self.thicknessRatio = max(0.01, min(0.99, thicknessRatio))
        self.loopCount = max(2, min(360, loopCount))
        self.angle0 = angle0
        self.angle1 = angle1
        self.segmentsPerLoop = max(3, min(360, segmentsPerLoop))
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5

        // r0: radius of the large circle the epicycle travels along.
        // r1: radius of the small (epicycle) circle.
        let r0 = radius * (1 - thicknessRatio / 2)
        let r1 = radius * thicknessRatio / 2

        let steps = loopCount * segmentsPerLoop
        let da: CGFloat = (2 * .pi) / CGFloat(steps)
        let daEpicycle = da * CGFloat(loopCount)

        var p = Path()
        p.move(to: CGPoint(
            x: center.x + cos(angle0) * r0 + cos(angle1) * r1,
            y: center.y + sin(angle0) * r0 + sin(angle1) * r1
        ))
        for i in 1..<steps {
            let a0 = angle0 + CGFloat(i) * da
            let a1 = angle1 + CGFloat(i) * daEpicycle
            p.addLine(to: CGPoint(
                x: center.x + cos(a0) * r0 + cos(a1) * r1,
                y: center.y + sin(a0) * r0 + sin(a1) * r1
            ))
        }
        p.closeSubpath()
        return p
    }
}

#Preview {
    VStack {
        CyclomatRing(loopCount: 12)
            .stroke(style: StrokeStyle(lineWidth: 4.0))
            .foregroundStyle(Color.blue)
        CyclomatRing(thicknessRatio: 0.5, segmentsPerLoop: 7)
            .stroke(style: StrokeStyle(lineWidth: 6.0))
            .foregroundStyle(Color.green)
        CyclomatRing(thicknessRatio: 0.5, loopCount: 60)
            .stroke(style: StrokeStyle(lineWidth: 1.0))
            .foregroundStyle(Color.red)
    }
}
