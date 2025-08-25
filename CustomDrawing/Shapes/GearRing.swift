import SwiftUI

/// Draws a shape that looks like a gear or cog.
public struct GearRing: Shape {
    
    /// The number of teeth on the gear.
    ///
    /// Default value is `24`.
    public var toothCount: Int
    
    /// The ratio of the tooth depth to the radius of the ring.
    ///
    /// Default value is `0.8`.
    public var toothDepthRatio: CGFloat
    
    /// The number of inner spokes to draw.
    ///
    /// Default value is `6`.
    public var spokeCount: Int
    
    /// The ratio of spoke to empty space between spokes.
    ///
    /// Default value is `0.7`.
    public var spokeWidthRatio: CGFloat
    
    /// Whether or not to include the center hole.
    ///
    /// Default is `true`.
    public var includeCenterHole: Bool
    
    /// Creates a gear shape with the specified parameters.
    ///
    /// - Parameters:
    ///     - toothCount: The number of teeth on the gear. Minimum is 2. Default is 24.
    ///     - toothDepthRatio: The ratio of the tooth depth to the radius of the ring. Default is 0.8.
    ///     - spokeCount: The number of inner spokes to draw. Minimum is 0. Default is 6.
    ///     - spokeWidthRatio: The ratio of spoke to empty space between spokes. Default is 0.7.
    ///     - includeCenterHole: Whether or not to include the center hole. Default is true.
    ///
    public init(toothCount: Int = 24, toothDepthRatio: CGFloat = 0.8, spokeCount: Int = 6, spokeWidthRatio: CGFloat = 0.7, includeCenterHole: Bool = true) {
        self.toothCount = max(2, toothCount)
        self.toothDepthRatio = toothDepthRatio
        self.spokeCount = max(0, spokeCount)
        self.spokeWidthRatio = spokeWidthRatio
        self.includeCenterHole = includeCenterHole
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let rOuter = drawRect.width * 0.5
        let rInner = rOuter * toothDepthRatio
        let toothAngle = (CGFloat.pi * 2) / CGFloat(toothCount)
        let segmentAngle = toothAngle / 4
        var p = Path()
        p.move(to: CGPoint(x: rInner + center.x, y: center.y))
        for i in 0..<toothCount {
            let a = toothAngle * CGFloat(i)
            for j in (1...4) {
                let a0 = a + segmentAngle * CGFloat(j)
                let r0 = (j / 2) % 2 == 0 ? rInner : rOuter
                p.addLine(to: CGPoint(x: r0 * cos(a0) + center.x, y: r0 * sin(a0) + center.y))
            }
        }
        if spokeCount >= 2 {
            let holeWidth = (CGFloat.pi * 2) / CGFloat(spokeCount) * spokeWidthRatio
            let sOuter = rOuter * (toothDepthRatio - 0.1)
            let sInner = sOuter * 0.35
            for i in 0..<spokeCount {
                let a0 = (CGFloat.pi * 2 / CGFloat(spokeCount)) * CGFloat(i)
                let a1 = a0 + holeWidth
                let a2 = a1 - holeWidth * 0.25 * spokeWidthRatio
                let a3 = a0 + holeWidth * 0.25 * spokeWidthRatio
                let start = CGPoint(x: cos(a0) * sOuter + center.x, y: sin(a0) * sOuter + center.y)
                p.move(to: start)
                p.addArc(center: center, radius: sOuter, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                p.addLine(to: CGPoint(x: cos(a2) * sInner + center.x, y: sin(a2) * sInner + center.y))
                p.addArc(center: center, radius: sInner, startAngle: .radians(a2), endAngle: .radians(a3), clockwise: true)
                p.addLine(to: start)
            }
            if includeCenterHole {
                let holeRadius = sInner * 0.4
                p.move(to: CGPoint(x: center.x + holeRadius, y: center.y))
                p.addArc(center: center, radius: holeRadius, startAngle: .radians(0), endAngle: .radians(CGFloat.pi * 2), clockwise: false)
            }
        } else if includeCenterHole {
            p.addArc(center: center, radius: rOuter * 0.1, startAngle: .radians(0), endAngle: .radians(CGFloat.pi * 2), clockwise: false)
        }
        return p.normalized(eoFill: true)
    }
}

#Preview {
    VStack {
        GearRing()
            .stroke(lineWidth: 2)
            .foregroundStyle(.blue)
        
        GearRing(toothCount: 6, toothDepthRatio: 0.7, spokeCount: 0)
            .foregroundStyle(.green)
        
        GearRing(toothCount: 48, toothDepthRatio: 0.9, spokeCount: 8, spokeWidthRatio: 0.8, includeCenterHole: false)
            .foregroundStyle(.red)
    }
}
