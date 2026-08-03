import SwiftUI

public struct SectorMapRing: Shape {

    /// Defines whether or not sectors are drawn as linked.
    public nonisolated enum LinkageStyle: Sendable {

        /// The default width of the linkage.
        public static let defaultLinkThickness = Angle(radians: .pi * 0.025)

        /// Sectors are not linked.
        case unlinked

        /// Sectors are linked, with a thin bridge connecting sectors on different tracks.
        ///
        /// - Parameters:
        ///   - thickness: The width of the linking line, expressed as an angle.
        ///   - roundedCorners: Whether the corners where each sector meets the link are rounded.
        case linked(thickness: Angle, roundedCorners: Bool = false)
    }

    /// A single sector of the ring, occupying one track and one angular arc.
    public nonisolated struct Sector: Sendable, CustomStringConvertible {
        /// The track this sector sits on, where `0` is the outermost.
        public let track: Int

        /// The sector's angular span.
        public let arc: Arc

        public var description: String { "Sector{track: \(track), arc: \(arc)}" }
    }

    /// A sector's outer and inner radii and angular span, after the link trim has been applied.
    private nonisolated struct SectorSpan: Sendable {
        let r0: CGFloat
        let r1: CGFloat
        let a0o: Angle
        let a1o: Angle
        let a0i: Angle
        let a1i: Angle
    }

    /// The tangent geometry where a straight junction line meets a rounded arc corner.
    private nonisolated struct CornerFillet: Sendable {
        let filletCenter: CGPoint
        let tangentOnLine: CGPoint
        let tangentOnArc: CGPoint
        let arcAngle: Angle
    }

    /// The pair of rounded corners bridging one sector's trailing edge to the next sector's leading edge.
    private nonisolated struct Junction: Sendable {
        let exit: CornerFillet
        let entry: CornerFillet
    }

    /// A target corner radius for one track edge, plus a cap on how far a single fillet may reach.
    private nonisolated struct EdgeRadius: Sendable {
        let target: CGFloat
        let maxReach: CGFloat
    }

    /// The fraction of a sector's own angular span its two corner fillets may together consume.
    private static nonisolated let cornerAngularMargin: CGFloat = 0.35

    /// The fraction of the track's radial thickness that a corner fillet is allowed to reach into.
    private static nonisolated let cornerRadialMargin: CGFloat = 0.16

    /// The ratio of the radius used by the shape.
    public nonisolated let thicknessRatio: CGFloat

    /// The number of tracks allowed.
    public nonisolated let trackCount: Int

    public nonisolated let linkStyle: LinkageStyle

    public nonisolated let sectorMap: [Sector]

    public init(thicknessRatio: CGFloat = 0.7,
                trackCount: Int = 3,
                sectorWidthRange: ClosedRange<CGFloat> = (.pi * 0.05)...(.pi * 0.3),
                allowMultiTrackJumps: Bool = true,
                linkStyle: LinkageStyle = .unlinked) {
        self.thicknessRatio = thicknessRatio
        self.trackCount = max(trackCount, 2)
        self.linkStyle = linkStyle

        var sMap: [Sector] = []
        var totalSpan: CGFloat = 0
        var prevTrack: Int = -1
        repeat {
            let w = CGFloat.random(in: sectorWidthRange)
            let t = Self.nextTrack(for: prevTrack, trackCount: trackCount, allowMultiTrackJumps: allowMultiTrackJumps)
            let s = Sector(track: t, arc: Arc(start: .radians(totalSpan), end: .radians(totalSpan + w), clockwise: true))
            sMap.append(s)
            totalSpan += w
            prevTrack = t
        } while (CGFloat.twoPi - totalSpan > sectorWidthRange.upperBound)

        let t = Self.nextTrack(for: prevTrack, trackCount: trackCount, allowMultiTrackJumps: allowMultiTrackJumps)
        let s = Sector(track: t, arc: Arc(start: .radians(totalSpan), end: .radians(.twoPi)))
        sMap.append(s)

        if allowMultiTrackJumps {
            self.sectorMap = sMap
        } else {
            self.sectorMap = Self.normalizeSectorTracks(sMap, trackCount: trackCount)
        }
    }

    public init(thicknessRatio: CGFloat = 0.7, sectorMap: [Sector], trackCount: Int = 3, linkStyle: LinkageStyle = .unlinked) {
        self.thicknessRatio = thicknessRatio
        self.sectorMap = sectorMap
        self.trackCount = trackCount
        self.linkStyle = linkStyle
    }

    public nonisolated func path(in rect: CGRect) -> Path {
        let drawRect = rect.centeredSquare()
        let center = drawRect.center
        let radius = drawRect.width * 0.5
        let innerRadius = radius * (1 - thicknessRatio)
        let trackWidth = (radius - innerRadius) / CGFloat(trackCount)
        switch linkStyle {
        case .unlinked:
            return createUnlinkedPath(for: sectorMap, trackWidth: trackWidth, radius: radius, center: center)
        case .linked(let thickness, let roundedCorners):
            let t = max(0, thickness.radians)
            if t == 0 {
                return createUnlinkedPath(for: sectorMap, trackWidth: trackWidth, radius: radius, center: center)
            }
            if roundedCorners {
                return createLinkedRoundedPath(for: sectorMap, trackWidth: trackWidth, radius: radius, center: center, linkThickness: t)
            }
            return createLinkedPath(for: sectorMap, trackWidth: trackWidth, radius: radius, center: center, linkThickness: t)
        }
    }

    private nonisolated func createUnlinkedPath(for sectors: [Sector], trackWidth: CGFloat, radius: CGFloat, center: CGPoint) -> Path {
        var mainPath = Path()
        sectors.forEach { sector in
            let r0 = radius - CGFloat(sector.track) * trackWidth
            let r1 = r0 - trackWidth
            let a0 = sector.arc.start
            let a1 = sector.arc.end
            let p0 = point(for: a0, radius: r0, center: center)

            var p = Path()
            p.move(to: p0)
            p.addArc(center: center, radius: r0, startAngle: a0, endAngle: a1, clockwise: false)
            p.addLine(to: point(for: a1, radius: r1, center: center))
            p.addArc(center: center, radius: r1, startAngle: a1, endAngle: a0, clockwise: true)
            p.addLine(to: p0)

            mainPath.addPath(p)
        }
        return mainPath
    }

    private nonisolated func createLinkedPath(for sectors: [Sector], trackWidth: CGFloat, radius: CGFloat, center: CGPoint, linkThickness: CGFloat) -> Path {
        let ht = Angle(radians: linkThickness * 0.5)
        let c = sectors.count
        var p = Path()
        var op = Path()
        var ip = Path()

        for (index, sector) in sectors.enumerated() {
            let prevSectorTrack = sectors[(index + c - 1) % c].track
            let isPrevOuter = prevSectorTrack < sector.track
            let nextSectorTrack = sectors[(index + 1) % c].track
            let isNextOuter = nextSectorTrack < sector.track
            let a0: Angle = sector.arc.start
            let a1: Angle = sector.arc.end
            let r0 = radius - CGFloat(sector.track) * trackWidth

            let a0o = a0 + (isPrevOuter ? ht : -ht)
            let a1o = a1 + (isNextOuter ? -ht : ht)

            op.addArc(center: center, radius: r0, startAngle: a0o, endAngle: a1o, clockwise: false)
        }
        op.closeSubpath()

        for (index, sector) in sectors.enumerated().reversed() {
            let prevSectorTrack = sectors[(index + c - 1) % c].track
            let isPrevOuter = prevSectorTrack < sector.track
            let nextSectorTrack = sectors[(index + 1) % c].track
            let isNextOuter = nextSectorTrack < sector.track
            let a0: Angle = sector.arc.start
            let a1: Angle = sector.arc.end
            let r0 = radius - CGFloat(sector.track) * trackWidth
            let r1 = r0 - trackWidth

            let a0i = a0 + (isPrevOuter ? -ht : ht)
            let a1i = a1 + (isNextOuter ? ht : -ht)

            ip.addArc(center: center, radius: r1, startAngle: a1i, endAngle: a0i, clockwise: true)
        }
        ip.closeSubpath()

        p.addPath(op)
        p.addPath(ip)
        return p
    }

    private nonisolated func createLinkedRoundedPath(for sectors: [Sector], trackWidth: CGFloat, radius: CGFloat, center: CGPoint, linkThickness: CGFloat) -> Path {
        let ht = Angle(radians: linkThickness * 0.5)
        let c = sectors.count

        let spans: [SectorSpan] = sectors.indices.map { index in
            let sector = sectors[index]
            let prevTrack = sectors[(index + c - 1) % c].track
            let nextTrack = sectors[(index + 1) % c].track
            let isPrevOuter = prevTrack < sector.track
            let isNextOuter = nextTrack < sector.track
            let r0 = radius - CGFloat(sector.track) * trackWidth
            let r1 = r0 - trackWidth
            let a0 = sector.arc.start
            let a1 = sector.arc.end
            return SectorSpan(
                r0: r0, r1: r1,
                a0o: a0 + (isPrevOuter ? ht : -ht),
                a1o: a1 + (isNextOuter ? -ht : ht),
                a0i: a0 + (isPrevOuter ? -ht : ht),
                a1i: a1 + (isNextOuter ? ht : -ht)
            )
        }

        let edgeRadii = cornerRadiiPerEdge(sectors: sectors, trackWidth: trackWidth, radius: radius, linkThickness: linkThickness)

        let outerJunctions: [Junction] = (0..<c).map { i in
            let a = spans[i]
            let b = spans[(i + 1) % c]
            let exitCorner = point(for: a.a1o, radius: a.r0, center: center)
            let entryCorner = point(for: b.a0o, radius: b.r0, center: center)
            let unit = unitVector(from: exitCorner, to: entryCorner)
            let exitEdge = edgeRadii[sectors[i].track]
            let entryEdge = edgeRadii[sectors[(i + 1) % c].track]
            let exit = lineArcFillet(corner: exitCorner, cornerAngle: a.a1o, lineDirection: unit, arcCenter: center, sectorAheadOfCorner: false, cornerRadius: exitEdge.target, maxReach: exitEdge.maxReach)
            let entry = lineArcFillet(corner: entryCorner, cornerAngle: b.a0o, lineDirection: CGVector(dx: -unit.dx, dy: -unit.dy), arcCenter: center, sectorAheadOfCorner: true, cornerRadius: entryEdge.target, maxReach: entryEdge.maxReach)
            return Junction(exit: exit, entry: entry)
        }

        let innerJunctions: [Junction] = (0..<c).map { i in
            let a = spans[i]
            let b = spans[(i + 1) % c]
            let exitCorner = point(for: a.a1i, radius: a.r1, center: center)
            let entryCorner = point(for: b.a0i, radius: b.r1, center: center)
            let unit = unitVector(from: exitCorner, to: entryCorner)
            let exitEdge = edgeRadii[sectors[i].track + 1]
            let entryEdge = edgeRadii[sectors[(i + 1) % c].track + 1]
            let exit = lineArcFillet(corner: exitCorner, cornerAngle: a.a1i, lineDirection: unit, arcCenter: center, sectorAheadOfCorner: false, cornerRadius: exitEdge.target, maxReach: exitEdge.maxReach)
            let entry = lineArcFillet(corner: entryCorner, cornerAngle: b.a0i, lineDirection: CGVector(dx: -unit.dx, dy: -unit.dy), arcCenter: center, sectorAheadOfCorner: true, cornerRadius: entryEdge.target, maxReach: entryEdge.maxReach)
            return Junction(exit: exit, entry: entry)
        }

        var op = Path()
        for idx in 0..<c {
            let span = spans[idx]
            let entryJ = outerJunctions[(idx + c - 1) % c].entry
            let exitJ = outerJunctions[idx].exit
            if idx == 0 {
                op.move(to: entryJ.tangentOnArc)
            }
            op.addArc(center: center, radius: span.r0, startAngle: entryJ.arcAngle, endAngle: exitJ.arcAngle, clockwise: false)
            addFilletArc(to: &op, center: exitJ.filletCenter, from: exitJ.tangentOnArc, to: exitJ.tangentOnLine)
            let nextEntryJ = outerJunctions[idx].entry
            op.addLine(to: nextEntryJ.tangentOnLine)
            addFilletArc(to: &op, center: nextEntryJ.filletCenter, from: nextEntryJ.tangentOnLine, to: nextEntryJ.tangentOnArc)
        }
        op.closeSubpath()

        var ip = Path()
        for idx in (0..<c).reversed() {
            let span = spans[idx]
            let exitJ = innerJunctions[idx].exit
            let entryJ = innerJunctions[(idx + c - 1) % c].entry
            if idx == c - 1 {
                ip.move(to: exitJ.tangentOnArc)
            }
            ip.addArc(center: center, radius: span.r1, startAngle: exitJ.arcAngle, endAngle: entryJ.arcAngle, clockwise: true)
            addFilletArc(to: &ip, center: entryJ.filletCenter, from: entryJ.tangentOnArc, to: entryJ.tangentOnLine)
            let prevExitJ = innerJunctions[(idx + c - 1) % c].exit
            ip.addLine(to: prevExitJ.tangentOnLine)
            addFilletArc(to: &ip, center: prevExitJ.filletCenter, from: prevExitJ.tangentOnLine, to: prevExitJ.tangentOnArc)
        }
        ip.closeSubpath()

        var mainPath = Path()
        mainPath.addPath(op)
        mainPath.addPath(ip)
        return mainPath
    }

    /// Computes a safe, consistent corner radius for each of the ring's `trackCount + 1` track edges,
    /// bounded by that edge's narrowest touching sector and the track's radial thickness.
    private nonisolated func cornerRadiiPerEdge(sectors: [Sector], trackWidth: CGFloat, radius: CGFloat, linkThickness: CGFloat) -> [EdgeRadius] {
        let trackCount = (sectors.map(\.track).max() ?? 0) + 1
        var minWidthPerEdge = [CGFloat](repeating: .infinity, count: trackCount + 1)
        for sector in sectors {
            let width = sector.arc.end.radians - sector.arc.start.radians
            minWidthPerEdge[sector.track] = min(minWidthPerEdge[sector.track], width)
            minWidthPerEdge[sector.track + 1] = min(minWidthPerEdge[sector.track + 1], width)
        }

        let radialBound = trackWidth * Self.cornerRadialMargin
        return (0...trackCount).map { edge in
            let minWidth = minWidthPerEdge[edge]
            guard minWidth.isFinite else { return EdgeRadius(target: 0, maxReach: 0) }
            let edgeRadius = radius - CGFloat(edge) * trackWidth
            let maxReach = edgeRadius * Self.cornerAngularMargin * max(0, minWidth - linkThickness) * 0.5
            return EdgeRadius(target: max(0, min(maxReach, radialBound)), maxReach: max(0, maxReach))
        }
    }

    /// Computes the fillet that eases a corner from the arc's tangent direction into the junction
    /// line's direction, rounding it with radius `cornerRadius`.
    ///
    /// - Parameters:
    ///   - corner: The unrounded corner point where the line would meet the arc.
    ///   - cornerAngle: `corner`'s angle around `arcCenter`, unwrapped to stay continuous with the
    ///     rest of the sector's angles.
    ///   - lineDirection: Unit vector along the straight edge, pointing away from `corner`.
    ///   - arcCenter: The center of the circle the arc lies on.
    ///   - sectorAheadOfCorner: Whether the sector lies at increasing angle from `corner`.
    ///   - cornerRadius: The target fillet radius.
    ///   - maxReach: The furthest the fillet may reach along either the arc or the junction line.
    private nonisolated func lineArcFillet(corner: CGPoint, cornerAngle: Angle, lineDirection: CGVector, arcCenter: CGPoint, sectorAheadOfCorner: Bool, cornerRadius: CGFloat, maxReach: CGFloat) -> CornerFillet {
        // The arc's tangent direction at `corner`, pointing into the sector's own material.
        let sinAngle = sin(cornerAngle.radians)
        let cosAngle = cos(cornerAngle.radians)
        let tangentSign: CGFloat = sectorAheadOfCorner ? 1 : -1
        let arcTangent = CGVector(dx: -sinAngle * tangentSign, dy: cosAngle * tangentSign)

        // The angle this corner turns through, between the arc's tangent and the junction line.
        let cosTheta = max(-1, min(1, arcTangent.dx * lineDirection.dx + arcTangent.dy * lineDirection.dy))
        let theta = acos(cosTheta)

        guard cornerRadius > 0, theta > 0.0001, theta < .pi - 0.0001 else {
            return CornerFillet(filletCenter: corner, tangentOnLine: corner, tangentOnArc: corner, arcAngle: cornerAngle)
        }

        let halfTheta = theta * 0.5
        let tangentDistance = min(cornerRadius / tan(halfTheta), maxReach)
        let effectiveRadius = tangentDistance * tan(halfTheta)
        let tangentOnArc = CGPoint(x: corner.x + tangentDistance * arcTangent.dx, y: corner.y + tangentDistance * arcTangent.dy)
        let tangentOnLine = CGPoint(x: corner.x + tangentDistance * lineDirection.dx, y: corner.y + tangentDistance * lineDirection.dy)

        let bisector = CGVector(dx: arcTangent.dx + lineDirection.dx, dy: arcTangent.dy + lineDirection.dy)
        let bisectorLen = (bisector.dx * bisector.dx + bisector.dy * bisector.dy).squareRoot()
        let filletDistance = effectiveRadius / sin(halfTheta)
        let filletCenter = CGPoint(
            x: corner.x + filletDistance * bisector.dx / bisectorLen,
            y: corner.y + filletDistance * bisector.dy / bisectorLen
        )

        // Measure the tangent point's angle as a small, unwrapped offset from `cornerAngle` rather
        // than deriving it fresh, so it stays continuous across the ±π boundary.
        let cornerVector = CGVector(dx: corner.x - arcCenter.x, dy: corner.y - arcCenter.y)
        let tangentVector = CGVector(dx: tangentOnArc.x - arcCenter.x, dy: tangentOnArc.y - arcCenter.y)
        let delta = atan2(
            cornerVector.dx * tangentVector.dy - cornerVector.dy * tangentVector.dx,
            cornerVector.dx * tangentVector.dx + cornerVector.dy * tangentVector.dy
        )
        let arcAngle = Angle(radians: cornerAngle.radians + delta)

        return CornerFillet(filletCenter: filletCenter, tangentOnLine: tangentOnLine, tangentOnArc: tangentOnArc, arcAngle: arcAngle)
    }

    /// Appends the minor arc from `from` to `to`, both assumed to lie on the circle of radius
    /// `|from - center|` around `center`.
    private nonisolated func addFilletArc(to path: inout Path, center: CGPoint, from: CGPoint, to: CGPoint) {
        let dx = from.x - center.x
        let dy = from.y - center.y
        let r = (dx * dx + dy * dy).squareRoot()
        guard r > 0 else {
            path.addLine(to: to)
            return
        }
        let startAngle = Angle(radians: atan2(dy, dx))
        var diff = atan2(to.y - center.y, to.x - center.x) - startAngle.radians
        while diff > .pi { diff -= .twoPi }
        while diff <= -.pi { diff += .twoPi }
        let endAngle = Angle(radians: startAngle.radians + diff)
        path.addArc(center: center, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: diff < 0)
    }

    /// Unit vector pointing from `a` to `b`; zero if the points coincide.
    private nonisolated func unitVector(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = (dx * dx + dy * dy).squareRoot()
        guard len > 0 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    private nonisolated func point(for angle: Angle, radius: CGFloat, center: CGPoint) -> CGPoint {
        CGPoint(x: cos(angle.radians) * radius + center.x, y: sin(angle.radians) * radius + center.y)
    }

    private static nonisolated func nextTrack(for prevTrack: Int, trackCount: Int, allowMultiTrackJumps: Bool) -> Int {
        var t = 0
        if allowMultiTrackJumps {
            repeat { t = Int.random(in: 0..<trackCount) } while t == prevTrack
        } else {
            if prevTrack < 0 { t = Int.random(in: 0..<trackCount) }
            else if prevTrack == 0 { t = 1 }
            else if prevTrack == trackCount - 1 { t = trackCount - 2 }
            else { t = prevTrack + (Bool.random() ? 1 : -1) }
        }
        return t 
    }

    private static nonisolated func normalizeSectorTracks(_ sectors: [Sector], trackCount: Int) -> [Sector] {
        let c = sectors.count
        let t0 = sectors[0].track
        guard c > 1 else { return sectors }

        var tracks = sectors.map(\.track)
        let lastIndex = c - 1

        // Clamp the final sector to within one track of the first sector.
        let lowerBound = max(0, t0 - 1)
        let upperBound = min(trackCount - 1, t0 + 1)
        tracks[lastIndex] = min(max(tracks[lastIndex], lowerBound), upperBound)

        // Walk backwards, pulling each preceding track one step closer until
        // the chain reconnects with its original (already-valid) values.
        var i = lastIndex
        while i > 1 {
            let diff = tracks[i - 1] - tracks[i]
            if abs(diff) <= 1 { break }
            tracks[i - 1] = tracks[i] + (diff > 0 ? 1 : -1)
            i -= 1
        }

        return zip(sectors, tracks).map { sector, track in
            Sector(track: track, arc: sector.arc)
        }
    }
}

extension SectorMapRing {
    fileprivate static func evenSectorMap(tracks: [Int]) -> [Sector] {
        let count = tracks.count
        return tracks.enumerated().map { index, track in
            let start = Angle(radians: .twoPi * Double(index) / Double(count))
            let end = Angle(radians: .twoPi * Double(index + 1) / Double(count))
            return Sector(track: track, arc: Arc(start: start, end: end))
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        SectorMapRing(thicknessRatio: 0.7, sectorMap: SectorMapRing.evenSectorMap(tracks: [0, 1, 2, 1, 0, 2, 1, 0, 2, 1]), trackCount: 3, linkStyle: .unlinked)
            .stroke(lineWidth: 2)
            .foregroundStyle(Color.blue)
        SectorMapRing(thicknessRatio: 0.5, sectorMap: SectorMapRing.evenSectorMap(tracks: [0, 3, 1, 4, 0, 2, 4, 1, 3, 0, 2, 4, 1, 3, 0]), trackCount: 5, linkStyle: .linked(thickness: Angle(radians: 0.02)))
            .foregroundStyle(Color.green)
        SectorMapRing(thicknessRatio: 0.6, sectorMap: SectorMapRing.evenSectorMap(tracks: [0, 1, 2, 1, 0, 1, 2, 1]), trackCount: 3, linkStyle: .linked(thickness: Angle(radians: 0.05), roundedCorners: true))
            .foregroundStyle(Color.red)
        SectorMapRing(thicknessRatio: 0.8, sectorMap: SectorMapRing.evenSectorMap(tracks: [0, 2, 3, 1, 0, 3, 1, 2, 0, 3, 1, 2]), trackCount: 4, linkStyle: .linked(thickness: Angle(radians: 0.06), roundedCorners: true))
            .foregroundStyle(Color.orange)
    }
    .padding()
}
