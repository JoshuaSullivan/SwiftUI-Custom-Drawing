import SwiftUI

/// A shape that draws a tech-style ring with customizable notches.
///
public struct TechRing: Shape {
    
    /// The percentage of the radius to inset the notches.
    public let insetRatio: CGFloat
    
    private let arcs: [CGFloat]

    /// Initializes a `TechRing` with the specified parameters.
    /// - Parameters:
    ///    - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///    - arcs: An array of `Arc` objects defining the start and end angles of each notch.
    ///
    public init(insetRatio: CGFloat = 0.1, arcs: [Arc]) {
        self.insetRatio = insetRatio
        self.arcs = arcs.flatMap { [$0.start.radians, $0.end.radians] }
    }
    
    /// Initializes a `TechRing` with the specified parameters.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - rawArcs: An array of raw angle values (in radians) defining the start and end of each notch.
    ///
    public init(insetRatio: CGFloat = 0.1, rawArcs: [CGFloat]) {
        self.insetRatio = insetRatio
        self.arcs = rawArcs
    }
    
    /// Initializes a `TechRing` with random notches.
    /// - Parameters:
    ///  - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///  - arcCountRange: The range of possible notch counts. Default is 2 to 5.
    ///
    public init(insetRatio: CGFloat = 0.1, arcCountRange: ClosedRange<Int> = 2...5) {
        self.insetRatio = insetRatio

        // Create arcs
        var arcs: [[CGFloat]] = []
        let aOffset: CGFloat = CGFloat.random(in: 0...(2 * .pi))
        let notchCount = Int.random(in: arcCountRange)
        let notchArc = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchArc * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.25...0.75)
            let notchWidth = notchArc * ratio
            let space = notchArc - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            arcs.append([notchStart, notchStart + notchWidth])
        }
        self.arcs = arcs.flatMap { $0 }
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let dim = min(rect.width, rect.height)
        let dx = (rect.width - dim) / 2 + rect.origin.x
        let dy = (rect.height - dim) / 2 + rect.origin.y
        let drawRect = CGRect(x: dx, y: dy, width: dim, height: dim)
        let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
        let radius = dim * 0.5
        let inset = radius * insetRatio
        return drawRing(arcs: arcs, radius: radius, inset: inset, center: center)
    }
    
    private func drawRing(arcs: [CGFloat], radius: CGFloat, inset: CGFloat, center: CGPoint) -> Path {
        guard arcs.count >= 2 && arcs.count % 2 == 0 else {
            return Path() // Invalid arcs, return empty path
        }
        let r0 = radius
        let r1 = radius - inset
        let dr = abs(r0 - r1)
        let transitionAngle = acos((2 * r0 * r0 - dr * dr) / (2 * r0 * r0))
        var p = Path()
        p.move(to: CGPoint(x: r0 * cos(arcs[0]) + center.x, y: r0 * sin(arcs[0]) + center.y))
        for i in stride(from: 0, to: arcs.count, by: 2) {
            let a0 = arcs[i]
            let a3 = arcs[i + 1]
            let a1 = a0 + transitionAngle
            let a2 = a3 - transitionAngle
            let x1 = cos(a1) * r1 + center.x
            let y1 = sin(a1) * r1 + center.y
            let x3 = cos(a3) * r0 + center.x
            let y3 = sin(a3) * r0 + center.y
            p.addLine(to: CGPoint(x: x1, y: y1))
            p.addArc(center: center, radius: r1, startAngle: .radians(a1), endAngle: .radians(a2), clockwise: false)
            p.addLine(to: CGPoint(x: x3, y: y3))
            if i + 2 < arcs.count {
                let nextStart = arcs[i + 2]
                p.addArc(center: center, radius: r0, startAngle: .radians(a3), endAngle: .radians(nextStart), clockwise: false)
            }
        }
        p.addArc(center: center, radius: r0, startAngle: .radians(arcs[arcs.count - 1]), endAngle: .radians(arcs[0]), clockwise: false)
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
    
    private let outerArcs: [CGFloat]
    private let innerArcs: [CGFloat]
    
    /// Initializes a `HollowTechRing` with random notches on both the outer and inner edges.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - outerArcCountRange: The range of possible notch counts for the outer edge. Default is 2 to 5.
    ///   - innerArcCountRange: The range of possible notch counts for the inner edge. Default is 1 to 4.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, outerArcCountRange: ClosedRange<Int> = 2...5, innerArcCountRange: ClosedRange<Int> = 1...4) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        
        var arcs: [[CGFloat]] = []
        var aOffset: CGFloat = CGFloat.random(in: 0...(2 * .pi))
        var notchCount = Int.random(in: outerArcCountRange)
        var notchArc = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchArc * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.2...0.8)
            let notchWidth = notchArc * ratio
            let space = notchArc - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            arcs.append([notchStart, notchStart + notchWidth])
        }
        self.outerArcs = arcs.flatMap { $0 }

        arcs = []
        aOffset = CGFloat.random(in: 0...(2 * .pi))
        notchCount = Int.random(in: innerArcCountRange)
        notchArc = (2 * .pi) / CGFloat(notchCount)
        for i in 0..<notchCount {
            let startAngle = notchArc * CGFloat(i) + aOffset
            let ratio = CGFloat.random(in: 0.2...0.8)
            let notchWidth = notchArc * ratio
            let space = notchArc - notchWidth
            let notchStart = CGFloat.random(in: 0.2...0.8) * space + startAngle
            arcs.append([notchStart, notchStart + notchWidth])
        }
        self.innerArcs = arcs.flatMap { $0 }
    }
    
    /// Initializes a `HollowTechRing` with the specified outer and inner notches.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - outerArcs: An array of `Arc` objects defining the start and end angles of each outer notch.
    ///   - innerArcs: An array of `Arc` objects defining the start and end angles of each inner notch.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, outerArcs: [Arc], innerArcs: [Arc]) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        self.outerArcs = outerArcs.flatMap { [$0.start.radians, $0.end.radians] }
        self.innerArcs = innerArcs.flatMap { [$0.start.radians, $0.end.radians] }
    }
    
    /// Initializes a `HollowTechRing` with the specified outer and inner notches.
    /// - Parameters:
    ///   - insetRatio: The ratio of the notch inset to the radius. Default is 0.1.
    ///   - thicknessRatio: The ratio of the ring's thickness to its radius. Default is 0.25.
    ///   - rawOuterArcs: An array of raw angle values (in radians) defining the start and end of each outer notch.
    ///   - rawInnerArcs: An array of raw angle values (in radians) defining the start and end of each inner notch.
    ///
    public init(insetRatio: CGFloat = 0.1, thicknessRatio: CGFloat = 0.25, rawOuterArcs: [CGFloat], rawInnerArcs: [CGFloat]) {
        self.insetRatio = insetRatio
        self.thicknessRatio = thicknessRatio
        self.outerArcs = rawOuterArcs
        self.innerArcs = rawInnerArcs
    }
        
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let radius = drawRect.width * 0.5
        let inset = radius * insetRatio
        let thickness = radius * thicknessRatio
        let rectInset = thickness - inset
        let innerRect = drawRect.insetBy(dx: rectInset, dy: rectInset)
        var p = Path()
        p.addPath(TechRing(insetRatio: insetRatio, rawArcs: outerArcs).path(in: drawRect))
        p.closeSubpath()
        p.addPath(TechRing(insetRatio: insetRatio, rawArcs: innerArcs).path(in: innerRect))
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
            TechRing(insetRatio: 0.2, arcCountRange: 1...3)
                .stroke(.black, lineWidth: 2)
                .fill(.yellow)
                .padding(80)
                
        }
    }
}
