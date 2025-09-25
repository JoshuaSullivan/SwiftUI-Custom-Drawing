import SwiftUI

/// A ring shape that resembles a broadcast or signal icon, with concentric arcs.
public struct BroadcastRing: Shape {
    /// The ratio of the ring's thickness to its radius.
    public let thicknessRatio: CGFloat
    /// The number of concentric layers in the ring.
    public let layerCount: Int
    /// A arc defines a segment of the ring using start and end angles.
    public let arcs: [Arc]
    
    /// Initializes a `BroadcastRing` with random arcs.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.8.
    ///     - layerCount: The number of concentric layers in the ring. Minimum is 1. Defaults to 6.
    ///     - rayCountRange: The range of possible ray counts (arcs) in the ring. Defaults to 2...6.
    ///     - arcWidthRatioRange: The range of possible width ratios for each arc. Defaults to 0.1...0.9.
    ///     - uniformSpacing: If true, arcs are evenly spaced around the ring; if false, arcs are randomly placed. Defaults to true.
    ///
    public init(thicknessRatio: CGFloat = 0.8, layerCount: Int = 6, rayCountRange: ClosedRange<Int> = 2...6, arcWidthRatioRange: ClosedRange<CGFloat> = 0.1...0.9, uniformSpacing: Bool = true) {
        self.thicknessRatio = thicknessRatio
        self.layerCount = max(1, layerCount)
        
        let rayCount = Int.random(in: rayCountRange)
        let anglePerRay = (2 * .pi) / CGFloat(rayCount)
        let offset = CGFloat.random(in: 0..<(2 * .pi))
        var arcs: [Arc] = []
        if uniformSpacing {
            for i in 0..<rayCount {
                let startAngle = anglePerRay * CGFloat(i) + offset
                let arcWidth = (CGFloat.random(in: arcWidthRatioRange) / 2) * anglePerRay
                let arc = Arc(start: .radians(startAngle - arcWidth), end: .radians(startAngle + arcWidth))
                arcs.append(arc)
            }
        } else {
            for i in 0..<rayCount {
                let startAngle = anglePerRay * CGFloat(i) + offset
                let arcWidth = (CGFloat.random(in: arcWidthRatioRange)) * anglePerRay
                let space = anglePerRay - arcWidth
                let arcStart = CGFloat.random(in: 0...space) + startAngle
                let arc = Arc(start: .radians(arcStart), end: .radians(arcStart + arcWidth))
                arcs.append(arc)
            }
        }
        self.arcs = arcs
    }
    
    /// Initializes a `BroadcastRing` with the specified arcs.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.8.
    ///     - layerCount: The number of concentric layers in the ring. Minimum is 1. Defaults to 6.
    ///     - arcs: An array of `Arc` objects defining the start and end angles of each segment.
    ///
    public init(thicknessRatio: CGFloat = 0.8, layerCount: Int = 6, arcs: [Arc]) {
        self.thicknessRatio = thicknessRatio
        self.layerCount = max(1, layerCount)
        self.arcs = arcs
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let dr = (radius - r0) / CGFloat(layerCount + 1)
        var p = Path()
        for arc in arcs {
            for layer in 0..<layerCount {
                let r = r0 + dr * CGFloat(layer)
                p.move(to: CGPoint(x: center.x + r * cos(CGFloat(arc.start.radians)), y: center.y + r * sin(CGFloat(arc.start.radians))))
                p.addArc(center: center, radius: r, startAngle: arc.start, endAngle: arc.end, clockwise: false)
            }
        }
        return p
    }
}

#Preview {
    BroadcastRing()
        .stroke(lineWidth: 2)
        .foregroundStyle(.blue)
    BroadcastRing(thicknessRatio: 0.5, layerCount: 12, rayCountRange: 8...8, arcWidthRatioRange: 0.2...0.5, uniformSpacing: false)
        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .foregroundStyle(.green)
}
