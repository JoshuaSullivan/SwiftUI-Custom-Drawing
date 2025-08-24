import SwiftUI

public struct OffsetStreakRing: Shape {
    public let thicknessRatio: CGFloat
    public let streakCount: Int
    public let streakSpan: CGFloat
    public let streakOffset: CGFloat
    public let clockwise: Bool
    
    public init(thicknessRatio: CGFloat = 0.25, streakCount: Int = 8, streakSpan: CGFloat = .pi, streakOffset: CGFloat = .pi * 0.2, clockwise: Bool = true) {
        self.thicknessRatio = thicknessRatio
        self.streakCount = streakCount
        self.streakSpan = streakSpan
        self.streakOffset = streakOffset
        self.clockwise = clockwise
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let dim = min(rect.width, rect.height)
        let dx = (rect.width - dim) / 2 + rect.origin.x
        let dy = (rect.height - dim) / 2 + rect.origin.y
        let drawRect = CGRect(x: dx, y: dy, width: dim, height: dim)
        let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
        let radius = dim * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let dr = (radius - r0) / CGFloat(streakCount)
        var p = Path()
        for i in 0..<streakCount {
            let r = r0 + dr * CGFloat(i)
            let a0 = streakOffset * CGFloat(i + 1) * (clockwise ? 1 : -1)
            let a1 = a0 + streakSpan
            p.move(to: CGPoint(x: center.x + r * cos(a0), y: center.y + r * sin(a0)))
            p.addArc(center: center, radius: r, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
        }
        return p
    }
}

#Preview {
    VStack {
        OffsetStreakRing()
            .stroke(style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.blue)
        
        OffsetStreakRing(streakSpan: .pi * 0.3333, clockwise: false)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.green)
        
        OffsetStreakRing(thicknessRatio: 0.6, streakCount: 12, streakSpan: .pi * 1.8, streakOffset: .pi * 0.05)
            .stroke(style: StrokeStyle(lineWidth: 2))
            .foregroundStyle(.red)
        
    }
    .padding()
}
