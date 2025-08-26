import SwiftUI

/// A ring shape that resembles a broadcast or signal icon, with concentric arcs.
public struct BroadcastRing: Shape {
    /// The ratio of the ring's thickness to its radius.
    public let thicknessRatio: CGFloat
    /// The number of concentric layers in the ring.
    public let layerCount: Int
    /// A span defines a segment of the ring using start and end angles.
    public let spans: [Span]
    
    /// Initializes a `BroadcastRing` with random spans.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.8.
    ///     - layerCount: The number of concentric layers in the ring. Minimum is 1. Defaults to 6.
    ///     - rayCountRange: The range of possible ray counts (spans) in the ring. Defaults to 2...6.
    ///     - spanWidthRatioRange: The range of possible width ratios for each span. Defaults to 0.1...0.9.
    ///     - uniformSpacing: If true, spans are evenly spaced around the ring; if false, spans are randomly placed. Defaults to true.
    ///
    public init(thicknessRatio: CGFloat = 0.8, layerCount: Int = 6, rayCountRange: ClosedRange<Int> = 2...6, spanWidthRatioRange: ClosedRange<CGFloat> = 0.1...0.9, uniformSpacing: Bool = true) {
        self.thicknessRatio = thicknessRatio
        self.layerCount = max(1, layerCount)
        
        let rayCount = Int.random(in: rayCountRange)
        let anglePerRay = (2 * .pi) / CGFloat(rayCount)
        let offset = CGFloat.random(in: 0..<(2 * .pi))
        var spans: [Span] = []
        if uniformSpacing {
            for i in 0..<rayCount {
                let startAngle = anglePerRay * CGFloat(i) + offset
                let spanWidth = (CGFloat.random(in: spanWidthRatioRange) / 2) * anglePerRay
                let span = Span(start: .radians(startAngle - spanWidth), end: .radians(startAngle + spanWidth))
                spans.append(span)
            }
        } else {
            for i in 0..<rayCount {
                let startAngle = anglePerRay * CGFloat(i) + offset
                let spanWidth = (CGFloat.random(in: spanWidthRatioRange)) * anglePerRay
                let space = anglePerRay - spanWidth
                let spanStart = CGFloat.random(in: 0...space) + startAngle
                let span = Span(start: .radians(spanStart), end: .radians(spanStart + spanWidth))
                spans.append(span)
            }
        }
        self.spans = spans
    }
    
    /// Initializes a `BroadcastRing` with the specified spans.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.8.
    ///     - layerCount: The number of concentric layers in the ring. Minimum is 1. Defaults to 6.
    ///     - spans: An array of `Span` objects defining the start and end angles of each segment.
    ///
    public init(thicknessRatio: CGFloat = 0.8, layerCount: Int = 6, spans: [Span]) {
        self.thicknessRatio = thicknessRatio
        self.layerCount = max(1, layerCount)
        self.spans = spans
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let dr = (radius - r0) / CGFloat(layerCount + 1)
        var p = Path()
        for span in spans {
            for layer in 0..<layerCount {
                let r = r0 + dr * CGFloat(layer)
                p.move(to: CGPoint(x: center.x + r * cos(CGFloat(span.start.radians)), y: center.y + r * sin(CGFloat(span.start.radians))))
                p.addArc(center: center, radius: r, startAngle: span.start, endAngle: span.end, clockwise: false)
            }
        }
        return p
    }
}

#Preview {
    BroadcastRing()
        .stroke(lineWidth: 2)
        .foregroundStyle(.blue)
    BroadcastRing(thicknessRatio: 0.5, layerCount: 12, rayCountRange: 8...8, spanWidthRatioRange: 0.2...0.5, uniformSpacing: false)
        .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
        .foregroundStyle(.green)
}
