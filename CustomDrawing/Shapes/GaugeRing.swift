import SwiftUI

/// A ring composed of evenly spaced ticks, resembling a gauge or clock face.
public struct GaugeRing: Shape {
    
    /// The number of ticks in the ring.
    public let tickCount: Int
    /// The ratio of the tick thickness to the radius of the ring.
    public let thicknessRatio: CGFloat
    
    /// Initializes a `GaugeRing` with the specified parameters.
    /// - Parameters:
    ///     - tickCount: The number of ticks in the ring. Minimum is 1. Defaults to 60.
    ///     - thicknessRatio: The ratio of the tick thickness to the radius of the ring. Defaults to 0.1.
    ///
    public init(tickCount: Int = 60, thicknessRatio: CGFloat = 0.1) {
        self.tickCount = max(1, tickCount)
        self.thicknessRatio = thicknessRatio
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let radius = drawRect.width * 0.5
        let cx = drawRect.center.x
        let cy = drawRect.center.y
        let rInner = radius * (1 - thicknessRatio)
        var p = Path()
        let da: CGFloat = 2 * .pi / CGFloat(tickCount)
        for i in 0..<tickCount {
            let a = CGFloat(i) * da
            let x0 = cx + cos(a) * rInner
            let y0 = cy + sin(a) * rInner
            let x1 = cx + cos(a) * radius
            let y1 = cy + sin(a) * radius
            p.move(to: CGPoint(x: x0, y: y0))
            p.addLine(to: CGPoint(x: x1, y: y1))
        }
        return p
    }
}

#Preview {
    VStack {
        GaugeRing()
            .stroke(style: .init(lineWidth: 2))
            .foregroundStyle(.blue)
        
        GaugeRing(tickCount: 120, thicknessRatio: 0.05)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(.green)
        ZStack {
            GaugeRing(tickCount: 64)
                .stroke()
                .foregroundStyle(.yellow)
            
            GaugeRing(tickCount: 16, thicknessRatio: 0.2)
                .stroke(style: StrokeStyle(lineWidth: 2))
                .foregroundStyle(.red)
        }
    }
}
