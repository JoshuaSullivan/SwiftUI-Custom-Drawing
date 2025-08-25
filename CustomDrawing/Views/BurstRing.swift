import SwiftUI

/// A view that draws a burst ring with randomly spaced and sized spokes.
public struct BurstRing: View {
    
    /// A point on the ring where a color spoke is drawn.
    public struct Spoke {
        /// The center angle of the spoke, in degrees.
        let angle: CGFloat
        /// The angular width of the spoke, in degrees.
        let width: CGFloat
    }
    
    /// The thickness of the ring. The ring is always inset from the view bounds.
    public let thickness: CGFloat
    /// The background color of the ring.
    public let backgroundColor: Color
    /// The foreground color of the ring's spokes.
    public let foregroundColor: Color
        
    @State
    private var spokes: [Spoke]
    
    public var body: some View {
        Canvas { context, size in
            let dim = min(size.width, size.height)
            let dx = (size.width - dim) / 2
            let dy = (size.height - dim) / 2
            let drawRect = CGRect(x: dx, y: dy, width: dim, height: dim)
            
            context.clip(to: createClippingPath(in: drawRect, thickness: thickness), style: FillStyle(eoFill: true))
            context.fill(Path(ellipseIn: drawRect), with: .color(backgroundColor))
            context.fill(createRays(from: spokes, in: drawRect), with: .color(foregroundColor))
        }
    }
    
    /// Creates a burst ring with the specified parameters.
    ///
    /// - Parameters:
    ///     - thickness: The thickness of the ring.
    ///     - backgroundColor: The background color of the ring.
    ///     - foregroundColor: The color of the spokes.
    ///     - widthRange: The range of widths for the spokes, in degrees. Defaults to 0.5 to 1.2 degrees.
    ///     - spacingRange: The range of spacing between the spokes, in degrees. Defaults to 0.5 to 4 degrees.
    ///
    public init(thickness: CGFloat, backgroundColor: Color, foregroundColor: Color, widthRange: ClosedRange<CGFloat> = 0.5...1.2, spacingRange: ClosedRange<CGFloat> = 0.5...4) {
        self.thickness = thickness
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        
        var spokes: [Spoke] = []
        let aOffset = CGFloat.random(in: 0...360)
        var a: CGFloat = 0
        while a < 360 {
            let w = CGFloat.random(in: widthRange)
            let s = CGFloat.random(in: spacingRange)
            spokes.append(.init(angle: a + aOffset, width: w))
            a += s + w
        }
        self.spokes = spokes
    }
    
    /// Creates a burst ring with pre-specified spokes.
    ///
    /// - Parameters:
    ///     - thickness: The thickness of the ring.
    ///     - backgroundColor: The background color of the ring.
    ///     - foregroundColor: The color of the spokes.
    ///     - spokes: An array of `Spoke` objects defining the angle and width of each spoke.
    ///
    public init(thickness: CGFloat, backgroundColor: Color, foregroundColor: Color, spokes: [Spoke]) {
        self.thickness = thickness
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.spokes = spokes
    }
        
    
    private func createRays(from spokes: [Spoke], in rect: CGRect) -> Path {
        let r = rect.width / 2
        return spokes.reduce(into: Path()) { p, spoke in
            p.addPath(createSlice(radius: r, arcAngle: spoke.width, centerAngle: spoke.angle, offset: rect.origin))
        }
    }
    
    private func createSlice(radius: CGFloat, arcAngle: CGFloat, centerAngle: CGFloat, offset: CGPoint = .zero) -> Path {
        let center = CGPoint(x: radius + offset.x, y: radius + offset.y)
        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius, startAngle: Angle(degrees: centerAngle - arcAngle / 2), endAngle: Angle(degrees: centerAngle + arcAngle / 2), clockwise: false)
        return p
    }
        
    private func createClippingPath(in rect: CGRect, thickness: CGFloat) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        p.addEllipse(in: rect.insetBy(dx: thickness, dy: thickness))
        return p
    }
}

#Preview {
    BurstRing(thickness: 40, backgroundColor: .blue, foregroundColor: .green)
        .padding()
}
