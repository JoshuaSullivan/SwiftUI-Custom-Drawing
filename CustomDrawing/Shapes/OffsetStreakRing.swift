import SwiftUI

/// A ring composed of multiple offset arcs (streaks) that create a dynamic, swirling effect.
public struct OffsetStreakRing: Shape {
    /// The ratio of the ring's thickness to its radius.
    public let thicknessRatio: CGFloat
    /// The number of streaks in the ring.
    public let streakCount: Int
    /// The angular arc of each streak in radians.
    public let streakArc: CGFloat
    /// The angular offset between consecutive streaks in radians.
    public let streakOffset: CGFloat
    /// Whether the streaks are drawn in a clockwise direction.
    public let clockwise: Bool
    
    /// Initializes an `OffsetStreakRing` with the specified parameters.
    /// - Parameters:
    ///    - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.25.
    ///    - streakCount: The number of streaks in the ring. Minimum is 1. Defaults to 8.
    ///    - streakArc: The angular arc of each streak in radians. Defaults to π.
    ///    - streakOffset: The angular offset between consecutive streaks in radians. Defaults to π * 0.2.
    ///    - clockwise: Whether the streaks are drawn in a clockwise direction. Defaults to true.
    ///    
    public init(thicknessRatio: CGFloat = 0.25, streakCount: Int = 8, streakArc: CGFloat = .pi, streakOffset: CGFloat = .pi * 0.2, clockwise: Bool = true) {
        self.thicknessRatio = thicknessRatio
        self.streakCount = max(1, streakCount)
        self.streakArc = streakArc
        self.streakOffset = streakOffset
        self.clockwise = clockwise
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let dr = (radius - r0) / CGFloat(streakCount)
        var p = Path()
        for i in 0..<streakCount {
            let r = r0 + dr * CGFloat(i)
            let a0 = streakOffset * CGFloat(i + 1) * (clockwise ? 1 : -1)
            let a1 = a0 + streakArc
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
        
        OffsetStreakRing(streakArc: .pi * 0.3333, clockwise: false)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.green)
        
        OffsetStreakRing(thicknessRatio: 0.6, streakCount: 12, streakArc: .pi * 1.8, streakOffset: .pi * 0.05)
            .stroke(style: StrokeStyle(lineWidth: 2))
            .foregroundStyle(.red)
        
    }
    .padding()
}
