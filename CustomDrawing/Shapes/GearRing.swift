import SwiftUI

public struct GearRing: Shape {
    
    public var toothCount: Int
    public var toothDepthRatio: CGFloat
    public var spokeCount: Int
    public var spokeWidthRatio: CGFloat
    public var includeCenterHole: Bool
    
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
    
    public init(toothCount: Int = 24, toothDepthRatio: CGFloat = 0.8, spokeCount: Int = 6, spokeWidthRatio: CGFloat = 0.7, includeCenterHole: Bool = true) {
        self.toothCount = toothCount
        self.toothDepthRatio = toothDepthRatio
        self.spokeCount = spokeCount
        self.spokeWidthRatio = spokeWidthRatio
        self.includeCenterHole = includeCenterHole
    }
    
}

#Preview {
    VStack {
        GearRing()
            .stroke(lineWidth: 2)
            .foregroundStyle(.blue)
        
        GearRing(toothCount: 6, toothDepthRatio: 0.7, spokeCount: 12, spokeWidthRatio: 0.25, includeCenterHole: true)
            .foregroundStyle(.green)
        
        GearRing(toothCount: 48, toothDepthRatio: 0.9, spokeCount: 8, spokeWidthRatio: 0.8, includeCenterHole: false)
            .foregroundStyle(.red)
    }
}
