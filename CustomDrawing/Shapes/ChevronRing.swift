import SwiftUI

/// A `Shape` that arranges a ring of chevron (arrowhead) wedges around an annular band.
///
/// Each chevron is a constant-thickness arm that runs from the inner rim out to the outer rim,
/// bending at the band's mid-radius toward an apex that is offset tangentially by
/// ``centerOffsetAngle``. The wedges are distributed evenly around the circle, leaving a gap
/// between neighbors whose size is governed by ``spacingRatio``.
///
/// The inner and outer ends of every chevron are terminated exactly on the band's bounding
/// circles: the corners are computed as the intersections of the arm edges with the rim circles,
/// and the caps are drawn as arcs of those circles. Because the geometry lands precisely on the
/// rims, the shape needs no clipping mask to keep the chevrons inside the band — the edges are
/// clean by construction.
public nonisolated struct ChevronRing: Shape {

    /// The number of chevrons distributed evenly around the ring. Values below `1` yield an empty shape.
    public let chevronCount: Int

    /// The fraction of the radius occupied by the band, from `0` (no band) to `1` (band reaches the
    /// center). Clamped to a valid range when the path is built. Larger values produce a deeper band.
    public let radiusRatio: CGFloat

    /// The thickness of each chevron arm as a fraction of the arc available per chevron at the inner
    /// rim, from `0` (degenerate) to `1` (arms span their whole slot, leaving no gap). Higher values
    /// make thicker chevrons with narrower gaps; despite the name, this controls arm width, not the gap.
    public let spacingRatio: CGFloat

    /// The magnitude of each chevron apex's tangential lean from its radial centerline, in radians.
    /// `0` yields a straight radial spoke; larger values produce a more pronounced arrowhead. The
    /// value is treated as a magnitude — its sign is ignored — and is clamped to `0...π/2` when the
    /// path is built; use ``clockwise`` to choose the lean direction.
    public let centerOffsetAngle: CGFloat

    /// The direction each chevron's apex leans. When `true` (the default) the apexes lean clockwise
    /// in screen space; when `false` they lean counterclockwise, mirroring the arrangement.
    public let clockwise: Bool

    /// Creates a chevron ring.
    ///
    /// - Parameters:
    ///   - chevronCount: The number of chevrons around the ring. Defaults to `24`.
    ///   - radiusRatio: The band depth as a fraction of the radius, from `0` to `1`. Defaults to `0.4`.
    ///   - spacingRatio: The arm thickness as a fraction of the per-chevron arc, from `0` to `1`.
    ///     Defaults to `0.5`.
    ///   - centerOffsetAngle: The magnitude of each apex's tangential lean, in radians. Defaults to `.pi / 16`.
    ///   - clockwise: The lean direction — `true` for clockwise, `false` for counterclockwise. Defaults to `true`.
    public init(chevronCount: Int = 24,
                radiusRatio: CGFloat = 0.4,
                spacingRatio: CGFloat = 0.5,
                centerOffsetAngle: CGFloat = .pi / 16,
                clockwise: Bool = true) {
        self.chevronCount = chevronCount
        self.radiusRatio = radiusRatio
        self.spacingRatio = spacingRatio
        self.centerOffsetAngle = centerOffsetAngle
        self.clockwise = clockwise
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        var p = Path()

        // Clamp every input so degenerate parameters can't crash the loop or emit NaN coordinates.
        guard chevronCount > 0 else { return p }
        let bandRatio = min(max(radiusRatio, 0.0001), 1)
        let armRatio = min(max(spacingRatio, 0), 1)
        let magnitude = min(abs(centerOffsetAngle), .halfPi)
        let lean = clockwise ? magnitude : -magnitude

        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let rOuter = drawRect.width * 0.5
        guard rOuter > 0 else { return p }
        let rInner = rOuter * (1 - bandRatio)
        let rCenter = (rOuter + rInner) / 2
        let da: CGFloat = .twoPi / CGFloat(chevronCount)

        // Half the linear thickness of each arm, derived from the arc length available per chevron at
        // the inner rim (the tightest part of the band).
        let halfWidth = (rInner * da) * armRatio / 2
        guard halfWidth > 0 else { return p }
        let h2 = halfWidth * halfWidth
        let miterLimit: CGFloat = 4

        for i in 0..<chevronCount {
            let a0 = -.halfPi + da * CGFloat(i)
            let a1 = a0 + lean
            let ux = cos(a0)
            let uy = sin(a0)

            // Apex at the band mid-radius (offset tangentially), and the rim base points along a0.
            let apex = CGPoint(x: center.x + cos(a1) * rCenter, y: center.y + sin(a1) * rCenter)
            let innerBase = CGPoint(x: center.x + ux * rInner, y: center.y + uy * rInner)
            let outerBase = CGPoint(x: center.x + ux * rOuter, y: center.y + uy * rOuter)

            // Arm directions and their half-width normals. Skip a chevron whose arms collapse to a
            // point (only possible with a zero-depth band).
            guard let dirInner = Self.unit(from: innerBase, to: apex),
                  let dirOuter = Self.unit(from: apex, to: outerBase) else { continue }
            let nIn = CGPoint(x: -dirInner.y * halfWidth, y: dirInner.x * halfWidth)
            let nOut = CGPoint(x: -dirOuter.y * halfWidth, y: dirOuter.x * halfWidth)

            // Miter join at the apex. `denom` vanishes only when the arms fold back exactly 180°;
            // otherwise this is the exact intersection of the two offset edges. The result is then
            // clamped to the miter limit so a sharp bend produces a bevel-length nub, not a spike.
            let dot = nIn.x * nOut.x + nIn.y * nOut.y
            let denom = h2 + dot
            var m = denom > 1e-9
                ? CGPoint(x: (nIn.x + nOut.x) * h2 / denom, y: (nIn.y + nOut.y) * h2 / denom)
                : nIn
            let mLen = hypot(m.x, m.y)
            let maxLen = miterLimit * halfWidth
            if mLen > maxLen {
                let s = maxLen / mLen
                m = CGPoint(x: m.x * s, y: m.y * s)
            }
            let apexPlus = CGPoint(x: apex.x + m.x, y: apex.y + m.y)
            let apexMinus = CGPoint(x: apex.x - m.x, y: apex.y - m.y)

            // Where the four arm edges cross the rim circles. Because these land exactly on the rims,
            // the caps below trace true circular arcs and no clip is required.
            let toInner = CGPoint(x: -dirInner.x, y: -dirInner.y)
            guard let innerPlus = Self.rimHit(origin: apexPlus, dir: toInner, center: center, radius: rInner),
                  let innerMinus = Self.rimHit(origin: apexMinus, dir: toInner, center: center, radius: rInner),
                  let outerPlus = Self.rimHit(origin: apexPlus, dir: dirOuter, center: center, radius: rOuter),
                  let outerMinus = Self.rimHit(origin: apexMinus, dir: dirOuter, center: center, radius: rOuter)
            else { continue }

            p.move(to: innerPlus)
            p.addLine(to: apexPlus)
            p.addLine(to: outerPlus)
            Self.appendRimArc(to: &p, center: center, radius: rOuter, from: outerPlus, to: outerMinus)
            p.addLine(to: apexMinus)
            p.addLine(to: innerMinus)
            Self.appendRimArc(to: &p, center: center, radius: rInner, from: innerMinus, to: innerPlus)
            p.closeSubpath()
        }
        return p
    }

    /// Returns the unit vector from `a` to `b`, or `nil` if the points coincide.
    private nonisolated static func unit(from a: CGPoint, to b: CGPoint) -> CGPoint? {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { return nil }
        return CGPoint(x: dx / len, y: dy / len)
    }

    /// Returns the first intersection (smallest non-negative parameter) of the ray from `origin`
    /// along unit vector `dir` with the circle of `radius` centered at `center`, or `nil` if the ray
    /// misses the circle.
    private nonisolated static func rimHit(origin: CGPoint, dir: CGPoint, center: CGPoint, radius: CGFloat) -> CGPoint? {
        let fx = origin.x - center.x
        let fy = origin.y - center.y
        let b = fx * dir.x + fy * dir.y
        let c = fx * fx + fy * fy - radius * radius
        let disc = b * b - c
        guard disc >= 0 else { return nil }
        let root = disc.squareRoot()
        let near = -b - root
        let s = near >= 0 ? near : -b + root
        guard s >= 0 else { return nil }
        return CGPoint(x: origin.x + dir.x * s, y: origin.y + dir.y * s)
    }

    /// Appends line segments tracing the shorter arc of the circle (`center`, `radius`) from `start`
    /// to `end`. Both points are assumed to lie on the circle; the segments are fine enough that the
    /// rim reads as a smooth curve.
    private nonisolated static func appendRimArc(to path: inout Path, center: CGPoint, radius: CGFloat, from start: CGPoint, to end: CGPoint) {
        let a0 = atan2(start.y - center.y, start.x - center.x)
        let a1 = atan2(end.y - center.y, end.x - center.x)
        var delta = a1 - a0
        while delta > .pi { delta -= .twoPi }
        while delta < -.pi { delta += .twoPi }
        // Roughly one segment per two degrees of sweep.
        let steps = max(1, Int((abs(delta) / .twoPi) * 180))
        for k in 1...steps {
            let a = a0 + delta * CGFloat(k) / CGFloat(steps)
            path.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ChevronRing()
            .foregroundStyle(Color.blue)
        ChevronRing(chevronCount: 16, radiusRatio: 0.6, spacingRatio: 0.7, centerOffsetAngle: .pi / 12, clockwise: false)
            .foregroundStyle(Color.green)
        ChevronRing(chevronCount: 36, radiusRatio: 0.28, spacingRatio: 0.55, centerOffsetAngle: .pi / 30)
            .stroke(lineWidth: 2)
            .foregroundStyle(Color.red)
    }
    .padding()
}
