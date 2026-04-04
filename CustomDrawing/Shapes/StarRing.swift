import SwiftUI

public struct StarRing: Shape {
    
    public let points: Int
    public let innerRadiusRatio: CGFloat
    
    public init(points: Int = 60, innerRadiusRatio: CGFloat = 0.2) {
        self.points = max(2, min(180, points))
        self.innerRadiusRatio = max(0.1, min(0.99, innerRadiusRatio))
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width / 2
        let rInner = radius * innerRadiusRatio
        let dA: CGFloat = .pi / CGFloat(points)
        
        var p = Path()
        p.move(to: CGPoint(x: radius + center.x, y: 0 + center.y))
        for i in 0..<points {
            let a0 = dA * CGFloat(i) * 2
            let a1 = a0 + dA
            let p0 = CGPoint(x: cos(a1) * rInner + center.x, y: sin(a1) * rInner + center.y)
            let a2 = a0 + 2 * dA
            let p1 = CGPoint(x: cos(a2) * radius + center.x, y: sin(a2) * radius + center.y)
            p.addLine(to: p0)
            p.addLine(to: p1)
        }
        return p
    }
}

#Preview {
    VStack {
        StarRing()
            .fill(Color.blue)
        StarRing(points: 30, innerRadiusRatio: 0.5)
            .fill(Color.green)
        StarRing(points: 16, innerRadiusRatio: 0.9)
            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
            .foregroundStyle(Color.red)
        
    }
}
