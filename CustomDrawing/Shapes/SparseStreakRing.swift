import SwiftUI

/// A shape that draws a ring with sparse streaks, where each streak
/// is defined by a start and end angle.
///
public struct SparseStreakRing: Shape {
        
    /// The ratio of the ring's thickness to its radius.
    public let thicknessRatio: CGFloat
    
    /// The precalculated streaks for each layer of the ring.
    private let streaks: [[Span]]
    
    /// Initializes a `SparseStreakRing` with the specified parameters.
    /// - Parameters:
    ///     - thicknessRatio: The ratio of the ring's thickness to its radius. Defaults to 0.25.
    ///     - layerCount: The number of concentric layers in the ring. Defaults to 6.
    ///     - streaksPerLayer: The range of possible streak counts per layer. Defaults to 1...6.
    ///     
    init(thicknessRatio: CGFloat = 0.25, layerCount: Int = 6, streaksPerLayer: ClosedRange<Int> = 1...6) {
        self.thicknessRatio = thicknessRatio
        
        streaks = (0..<layerCount).map { layer in
            let streakCount = Int.random(in: streaksPerLayer)
            let aOffset = CGFloat.random(in: 0..<(2 * .pi))
            return (0..<streakCount).map { i in
                let angleSpan = (2 * CGFloat.pi) / CGFloat(streakCount)
                let a0 = angleSpan * CGFloat(i) + aOffset
                let a1 = a0 + angleSpan
                let start = a0 + CGFloat.random(in: 0..<(angleSpan * 0.49))
                let end = a1 - CGFloat.random(in: 0..<(angleSpan * 0.49))
                return Span(start: .radians(start), end: .radians(end))
            }
        }
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = rect.center
        let radius = drawRect.width * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let dr = (radius - r0) / CGFloat(streaks.count)
        var p = Path()
        for (layerIndex, layerStreaks) in streaks.enumerated() {
            let r = r0 + dr * CGFloat(layerIndex)
            for streak in layerStreaks {
                p.move(to: CGPoint(x: center.x + r * cos(CGFloat(streak.start.radians)), y: center.y + r * sin(CGFloat(streak.start.radians))))
                p.addArc(center: center, radius: r, startAngle: streak.start, endAngle: streak.end, clockwise: false)
            }
        }
        return p
    }
}

#Preview {
    VStack {
        SparseStreakRing()
            .stroke(lineWidth: 2)
            .foregroundStyle(.blue)
        
        SparseStreakRing(thicknessRatio: 0.2, layerCount: 4, streaksPerLayer: 2...6)
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .foregroundStyle(.green)
        
        SparseStreakRing(thicknessRatio: 0.5, layerCount: 3, streaksPerLayer: 1...1)
            .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
            .foregroundStyle(.red)
    }
    .padding()
}
