import SwiftUI

/// A shape that draws a tech-style ring with customizable notches.
///
public struct TechRing: Shape {
    
    /// The percentage of the radius to inset the notches.
    public let insetRatio: CGFloat
    
    private let spans: [CGFloat]

    /// Initializes a `TechRing` with the specified parameters.
    /// - Parameters:
    ///    - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///    - spans: An array of `Span` objects defining the start and end angles of each notch.
    ///
    public init(insetRatio: CGFloat = 0.1, spans: [Span]) {
        self.insetRatio = insetRatio
        self.spans = spans.flatMap { [$0.start.radians, $0.end.radians] }
    }
    
    /// Initializes a `TechRing` with the specified parameters.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - rawSpans: An array of raw angle values (in radians) defining the start and end of each notch.
    ///
    public init(insetRatio: CGFloat = 0.1, rawSpans: [CGFloat]) {
        self.insetRatio = insetRatio
        self.spans = rawSpans
    }
    
    /// Initializes a `TechRing` with random notches.
    /// - Parameters:
    ///  - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///  - spanCountRange: The range of possible notch counts. Default is 2 to 5.
    ///
    public init(insetRatio: CGFloat = 0.1, spanCountRange: ClosedRange<Int> = 2...5) {
        self.insetRatio = insetRatio

        // Create spans
        var spans: [[CGFloat]] = []
        let aOffset: CGFloat = CGFloat.random(in: 0...(2 * .pi))
        let notchCount = Int.random(in: spanCountRange)
        let notchSpan = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchSpan * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.25...0.75)
            let notchWidth = notchSpan * ratio
            let space = notchSpan - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            spans.append([notchStart, notchStart + notchWidth])
        }
        self.spans = spans.flatMap { $0 }
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let dim = min(rect.width, rect.height)
        let dx = (rect.width - dim) / 2 + rect.origin.x
        let dy = (rect.height - dim) / 2 + rect.origin.y
        let drawRect = CGRect(x: dx, y: dy, width: dim, height: dim)
        let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
        let radius = dim * 0.5
        let inset = radius * insetRatio
        return drawRing(spans: spans, radius: radius, inset: inset, center: center)
    }
    
    private func drawRing(spans: [CGFloat], radius: CGFloat, inset: CGFloat, center: CGPoint) -> Path {
        guard spans.count >= 2 && spans.count % 2 == 0 else {
            return Path() // Invalid spans, return empty path
        }
        let r0 = radius
        let r1 = radius - inset
        let dr = abs(r0 - r1)
        let transitionAngle = acos((2 * r0 * r0 - dr * dr) / (2 * r0 * r0))
        var p = Path()
        p.move(to: CGPoint(x: r0 * cos(spans[0]) + center.x, y: r0 * sin(spans[0]) + center.y))
        for i in stride(from: 0, to: spans.count, by: 2) {
            let a0 = spans[i]
            let a3 = spans[i + 1]
            let a1 = a0 + transitionAngle
            let a2 = a3 - transitionAngle
            let x1 = cos(a1) * r1 + center.x
            let y1 = sin(a1) * r1 + center.y
            let x3 = cos(a3) * r0 + center.x
            let y3 = sin(a3) * r0 + center.y
            p.addLine(to: CGPoint(x: x1, y: y1))
            p.addArc(center: center, radius: r1, startAngle: .radians(a1), endAngle: .radians(a2), clockwise: false)
            p.addLine(to: CGPoint(x: x3, y: y3))
            if i + 2 < spans.count {
                let nextStart = spans[i + 2]
                p.addArc(center: center, radius: r0, startAngle: .radians(a3), endAngle: .radians(nextStart), clockwise: false)
            }
        }
        p.addArc(center: center, radius: r0, startAngle: .radians(spans[spans.count - 1]), endAngle: .radians(spans[0]), clockwise: false)
        return p
    }
}

/// A shape that draws a hollow tech-style ring with customizable notches on both the outer and inner edges.
///
public struct HollowTechRing: Shape {
    /// The percentage of the radius to inset the notches.
    public let insetRatio: CGFloat
    /// The ratio of the ring's thickness to its radius.
    public let thicknessRatio: CGFloat
    
    private let outerSpans: [CGFloat]
    private let innerSpans: [CGFloat]
    
    /// Initializes a `HollowTechRing` with random notches on both the outer and inner edges.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - outerSpanCountRange: The range of possible notch counts for the outer edge. Default is 2 to 5.
    ///   - innerSpanCountRange: The range of possible notch counts for the inner edge. Default is 1 to 4.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, outerSpanCountRange: ClosedRange<Int> = 2...5, innerSpanCountRange: ClosedRange<Int> = 1...4) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        
        var spans: [[CGFloat]] = []
        var aOffset: CGFloat = CGFloat.random(in: 0...(2 * .pi))
        var notchCount = Int.random(in: outerSpanCountRange)
        var notchSpan = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchSpan * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.2...0.8)
            let notchWidth = notchSpan * ratio
            let space = notchSpan - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            spans.append([notchStart, notchStart + notchWidth])
        }
        self.outerSpans = spans.flatMap { $0 }

        spans = []
        aOffset = CGFloat.random(in: 0...(2 * .pi))
        notchCount = Int.random(in: innerSpanCountRange)
        notchSpan = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchSpan * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.2...0.8)
            let notchWidth = notchSpan * ratio
            let space = notchSpan - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            spans.append([notchStart, notchStart + notchWidth])
        }
        self.innerSpans = spans.flatMap { $0 }
    }
    
    /// Initializes a `HollowTechRing` with the specified outer and inner notches.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - outerSpans: An array of `Span` objects defining the start and end angles of each outer notch.
    ///   - innerSpans: An array of `Span` objects defining the start and end angles of each inner notch.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, outerSpans: [Span], innerSpans: [Span]) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        self.outerSpans = outerSpans.flatMap { [$0.start.radians, $0.end.radians] }
        self.innerSpans = innerSpans.flatMap { [$0.start.radians, $0.end.radians] }
    }
    
    /// Initializes a `HollowTechRing` with the specified outer and inner notches.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - rawOuterSpans: An array of raw angle values (in radians) defining the start and end of each outer notch.
    ///   - rawInnerSpans: An array of raw angle values (in radians) defining the start and end of each inner notch.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, rawOuterSpans: [CGFloat], rawInnerSpans: [CGFloat]) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        self.outerSpans = rawOuterSpans
        self.innerSpans = rawInnerSpans
    }
        
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let radius = drawRect.width * 0.5
        let inset = radius * insetRatio
        let thickness = radius * thicknessRatio
        let rectInset = thickness - inset
        let innerRect = drawRect.insetBy(dx: rectInset, dy: rectInset)
        var p = Path()
        p.addPath(TechRing(insetRatio: insetRatio, rawSpans: outerSpans).path(in: drawRect))
        p.closeSubpath()
        p.addPath(TechRing(insetRatio: insetRatio, rawSpans: innerSpans).path(in: innerRect))
        p.closeSubpath()
        return p.normalized(eoFill: true)
    }
}

#Preview {
    VStack {
        TechRing()
            .foregroundStyle(.blue)
        HollowTechRing(thicknessRatio: 0.25)
            .foregroundStyle(.green)
        ZStack {
            TechRing()
                .foregroundStyle(.red)
            HollowTechRing()
                .fill(.orange)
                .padding(40)
            TechRing(insetRatio: 0.2, spanCountRange: 1...3)
                .stroke(.black, lineWidth: 2)
                .fill(.yellow)
                .padding(80)
                
        }
    }
}
