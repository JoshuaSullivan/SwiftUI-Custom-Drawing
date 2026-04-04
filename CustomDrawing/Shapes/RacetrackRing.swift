import SwiftUI

/// A ring shape that draws concentric racetrack-shaped loops, each consisting of an outer arc,
/// a semicircular end cap, an inner arc, and a closing end cap.
public struct RacetrackRing: Shape {
    /// The ratio of the ring's total thickness to its radius.
    public let thicknessRatio: CGFloat
    /// The number of concentric racetrack loops to draw within the ring.
    public let loopCount: Int
    /// The arc that defines the angular extent of the racetrack.
    public let arc: Arc

    /// Initializes a `RacetrackRing` shape.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's total thickness to its radius. Defaults to 0.2.
    ///     - loopCount: The number of concentric racetrack loops. Minimum is 1. Defaults to 2.
    ///     - arc: The arc defining the angular extent. If nil, a random arc is generated.
    public init(thicknessRatio: CGFloat = 0.2, loopCount: Int = 2, arc: Arc? = nil) {
        self.thicknessRatio = thicknessRatio
        self.loopCount = max(1, loopCount)
        if let arc {
            self.arc = arc
        } else {
            let startAngle = Angle(radians: .random(in: 0..<(2.0 * .pi)))
            let extent = Angle(radians: .random(in: (0.2 * .pi)..<(1.8 * .pi)))
            self.arc = Arc(start: startAngle, end: startAngle + extent)
        }
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let lineCount = loopCount * 2
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let rInner = radius * (1 - thicknessRatio)
        let rMid = (radius - rInner) / 2 + rInner
        let dr = (radius - rInner) / CGFloat(lineCount - 1)
        let a0 = arc.start
        let a1 = arc.end
        let cap0: CGPoint = CGPoint(x: center.x + cos(a0.radians) * rMid, y: center.y + sin(a0.radians) * rMid)
        let cap1: CGPoint = CGPoint(x: center.x + cos(a1.radians) * rMid, y: center.y + sin(a1.radians) * rMid)
        let _180 = Angle(degrees: 180)
        var p = Path()
        for i in 0..<loopCount {
            let r0 = radius - CGFloat(i) * dr
            let r1 = rInner + CGFloat(i) * dr
            let capRadius = (r0 - r1) / 2
            p.move(to: .init(x: center.x + cos(a0.radians) * r0, y: center.y + sin(a0.radians) * r0))
            p.addArc(center: center, radius: r0, startAngle: a0, endAngle: a1, clockwise: false)
            p.addArc(center: cap1, radius: capRadius, startAngle: a1, endAngle: a1 + _180, clockwise: false)
            p.addArc(center: center, radius: r1, startAngle: a1, endAngle: a0, clockwise: true)
            p.addArc(center: cap0, radius: capRadius, startAngle: a0 + _180, endAngle: a0, clockwise: false)
            p.closeSubpath()
        }
        return p
    }
}

#Preview {
    VStack(spacing: 20) {
        RacetrackRing(arc: Arc(start: .degrees(45), end: .degrees(315)))
            .stroke(style: .init(lineWidth: 2))
            .foregroundStyle(.blue)
        RacetrackRing(thicknessRatio: 0.3, loopCount: 1, arc: Arc(start: .degrees(270), end: .degrees(90)))
            .stroke(style: .init(lineWidth: 16))
            .foregroundStyle(.green)
        RacetrackRing(thicknessRatio: 0.5, loopCount: 5, arc: Arc(start: .degrees(135), end: .degrees(225)))
            .stroke(style: .init(lineWidth: 4))
            .foregroundStyle(.red)
    }
    .padding()
}
