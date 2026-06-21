import SwiftUI

/// A `Shape` that renders a ring of radial "strings", each strung with a series of beads,
/// evoking a circular bead curtain.
///
/// Strings are distributed evenly around the circle, extending outward from an inner radius
/// (determined by ``thicknessRatio``) to the outer edge of the bounding square. Each string is
/// drawn as a thin rectangle and is populated with a random number of circular beads whose
/// positions and sizes vary, producing an organic, hand-strung appearance.
///
/// The randomized layout is generated once during initialization and captured in the shape's
/// stored ``beads``, so the path is stable across redraws. To produce a fixed, reproducible
/// layout, supply the beads directly via ``init(thicknessRatio:stringWidth:beads:)``.
public nonisolated struct BeadCurtainRing: Shape {

    /// A single bead positioned along one of the curtain's strings.
    public struct Bead: Sendable, CustomStringConvertible {

        /// The bead's location along its string, expressed as a fraction from `0.0` (inner end)
        /// to `1.0` (outer end).
        let position: CGFloat

        /// The bead's diameter, in points.
        let size: CGFloat

        public var description: String { "Bead{p: \(position), s: \(size)}" }
    }

    /// The fraction of the ring's radius occupied by the strings, from `0.0` (no depth) to
    /// `1.0` (strings reach the center). Larger values produce longer strings.
    public let thicknessRatio: CGFloat

    /// The width of each string, in points.
    public let stringWidth: CGFloat

    /// The beads for every string, indexed by string. The outer array holds one entry per
    /// string; each inner array holds that string's beads ordered from the inner to the outer end.
    private let beads: [[Bead]]

    /// Creates a bead curtain ring with a randomly generated bead layout.
    ///
    /// - Parameters:
    ///   - thicknessRatio: The fraction of the radius occupied by the strings, from `0.0` to `1.0`.
    ///     Defaults to `0.5`.
    ///   - stringCount: The number of strings distributed evenly around the ring. Defaults to `16`.
    ///   - beadsPerStringRange: The inclusive range of beads strung on each string. A value is
    ///     chosen at random per string. Defaults to `3...6`.
    ///   - stringWidth: The width of each string, in points. Defaults to `2.0`.
    ///   - beadSize: The inclusive range of bead diameters, in points. A value is chosen at random
    ///     per bead. Defaults to `4...12`.
    ///   - pinInnerBead: When `true`, the innermost bead on each string is fixed to the inner end
    ///     (position `0.0`). Defaults to `false`.
    ///   - pinOuterBead: When `true`, the outermost bead on each string is fixed to the outer end
    ///     (position `1.0`). Defaults to `true`.
    public init(thicknessRatio: CGFloat = 0.5,
         stringCount: Int = 16,
         beadsPerStringRange: ClosedRange<Int> = 3...6,
         stringWidth: CGFloat = 1.0,
         beadSize: ClosedRange<CGFloat> = 4...12,
         pinInnerBead: Bool = false,
         pinOuterBead: Bool = true
    ) {
        self.thicknessRatio = thicknessRatio
        self.stringWidth = stringWidth

        self.beads = (0..<stringCount).map { _ -> [Bead] in
            let beadCount = Int.random(in: beadsPerStringRange)
            let dp = 1.0 / CGFloat(beadCount)
            return (0..<beadCount).map { i in
                let size = CGFloat.random(in: beadSize)
                if pinInnerBead && i == 0 { return Bead(position: 0.0, size: size) }
                else if pinOuterBead && i == beadCount - 1 { return Bead(position: 1.0, size: size) }
                let posRange = (dp * CGFloat(i))...(dp * CGFloat(i+1))
                let pos = CGFloat.random(in: posRange)
                return Bead(position: pos, size: size)
            }
        }
    }

    /// Creates a bead curtain ring from an explicit, fixed bead layout.
    ///
    /// Use this initializer to render a deterministic curtain, bypassing the randomized
    /// generation performed by ``init(thicknessRatio:stringCount:beadsPerStringRange:stringWidth:beadSize:pinInnerBead:pinOuterBead:)``.
    ///
    /// - Parameters:
    ///   - thicknessRatio: The fraction of the radius occupied by the strings, from `0.0` to `1.0`.
    ///     Defaults to `0.5`.
    ///   - stringWidth: The width of each string, in points. Defaults to `2.0`.
    ///   - beads: The beads for every string. The outer array holds one entry per string; each
    ///     inner array holds that string's beads ordered from the inner to the outer end.
    public init(thicknessRatio: CGFloat = 0.5, stringWidth: CGFloat = 1.0, beads: [[Bead]]) {
        self.thicknessRatio = thicknessRatio
        self.stringWidth = stringWidth
        self.beads = beads
    }

    /// Builds the combined path of every string and its beads, fitted to the largest square
    /// centered within `rect`.
    ///
    /// - Parameter rect: The rectangle in which to draw the ring.
    /// - Returns: A path containing each string rectangle and the ellipses of its beads.
    public nonisolated func path(in rect: CGRect) -> Path {
        let c = beads.count
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let r0 = radius * (1 - thicknessRatio)
        let da: CGFloat = (2 * .pi) / CGFloat(c)
        let halfsw = stringWidth / 2
        let tt = CGAffineTransform(translationX: center.x, y: center.y)
        var p = Path()
        for (i, curBeads) in beads.enumerated() {
            let a = da * CGFloat(i) - (.pi * 0.5)
            // Add the string, centered on the radial axis (y = 0).
            let x0 = r0
            let y0 = -halfsw
            var r = Path()
            r.addRect(CGRect(origin: CGPoint(x: x0, y: y0), size: CGSize(width: radius - r0, height: stringWidth)))
            // Add beads
            for bead in curBeads {
                let s = bead.size
                // Inset each bead's travel by its own size so it stays fully within [r0, radius],
                // and center it on the radial axis to match the string.
                let bx = r0 + bead.position * (radius - r0 - s)
                let by = -s * 0.5
                let beadRect = CGRect(x: bx, y: by, width: s, height: s)
                r.addEllipse(in: beadRect)
            }
            let tr = CGAffineTransform(rotationAngle: a)
            p.addPath(r.applying(tr).applying(tt))

        }
        return p
    }
}

#Preview {
    VStack(spacing: 20) {
        BeadCurtainRing()
            .foregroundStyle(Color.blue)
        BeadCurtainRing(thicknessRatio: 0.8, stringCount: 32, pinInnerBead: false, pinOuterBead: false)
            .foregroundStyle(Color.green)
        BeadCurtainRing(thicknessRatio: 0.3, stringCount: 8, beadsPerStringRange: 2...3, stringWidth: 2, beadSize: 10...10, pinInnerBead: true, pinOuterBead: true)
            .foregroundStyle(Color.red)

    }
    .padding()
}
