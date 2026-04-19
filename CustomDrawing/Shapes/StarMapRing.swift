import SwiftUI

public struct StarMapRing: View {

    public struct Node: Sendable, Equatable {
        public let angle: CGFloat
        public let radius: CGFloat

        public init(angle: CGFloat, radius: CGFloat) {
            self.angle = angle
            self.radius = radius
        }
    }

    public struct Strand: Sendable, Equatable {
        public let nodes: [Node]

        public init(nodes: [Node]) {
            self.nodes = nodes
        }

        public init(nodeCount: Int = 30, centerBiasStrength: CGFloat = 1.0) {
            let nodeCount = max(1, min(120, nodeCount))
            let shiftRange: CGFloat = (2 * .pi) / CGFloat(nodeCount)
            nodes = (0..<nodeCount).map { i in
                let a0 = shiftRange * CGFloat(i)
                let a1 = shiftRange * CGFloat(i + 1)
                let a: CGFloat = .random(in: a0..<a1)
                let r: CGFloat = .random(in: 0...1).centerBiased(strength: centerBiasStrength)
                return Node(angle: a, radius: r)
            }
        }
    }

    public let thicknessRatio: CGFloat
    public let strandCount: Int
    public let nodeCount: Int
    public let nodeReach: Int
    public let nodeRadius: CGFloat
    /// Opacity applied to the connecting lines between nodes. Expected range `0...1`.
    /// Nodes themselves render at full opacity.
    public let lineOpacity: CGFloat

    /// Normalized (angle, radius) node data held in `@State` so the random star
    /// pattern stays stable across view re-initializations. Only the absolute
    /// coordinates derived from these values get recomputed when the bounds
    /// change.
    @State private var strands: [Strand]

    /// Cached drawing bounds and the node positions computed for those bounds.
    /// Updated from `onGeometryChange` so state mutation happens outside of the
    /// Canvas renderer (which would otherwise trigger the "modifying state
    /// during view update" runtime warning).
    @State private var cachedBounds: CGRect = .zero
    @State private var cachedPositions: [CGPoint] = []

    /// Connection topology as pairs of indices into the flat positions array.
    /// Depends only on the init parameters, so it's computed once per struct
    /// instance and reused on every draw.
    private let connectionIndices: [(from: Int, to: Int)]

    public init(
        thicknessRatio: CGFloat = 0.5,
        strandCount: Int = 3,
        nodeCount: Int = 20,
        nodeReach: Int = 1,
        nodeRadius: CGFloat = 10,
        lineOpacity: CGFloat = 0.5
    ) {
        self.thicknessRatio = thicknessRatio
        self.strandCount = strandCount
        self.nodeCount = nodeCount
        self.nodeReach = nodeReach
        self.nodeRadius = nodeRadius
        self.lineOpacity = lineOpacity

        _strands = State(initialValue: Self.makeStrands(strandCount: strandCount, nodeCount: nodeCount))
        connectionIndices = Self.makeConnectionIndices(
            strandCount: strandCount,
            nodeCount: nodeCount,
            nodeReach: nodeReach
        )
    }

    public var body: some View {
        Canvas { ctx, size in
            let bounds = CGRect(origin: .zero, size: size).centeredSquare()
            let expectedCount = strands.reduce(0) { $0 + $1.nodes.count }
            let positions: [CGPoint]
            if bounds == cachedBounds, cachedPositions.count == expectedCount {
                positions = cachedPositions
            } else {
                positions = computePositions(for: bounds, strands: strands)
            }
            guard !positions.isEmpty else { return }
            let previousOpacity = ctx.opacity
            ctx.opacity = previousOpacity * Double(lineOpacity)
            for pair in connectionIndices where pair.from < positions.count && pair.to < positions.count {
                var path = Path()
                path.move(to: positions[pair.from])
                path.addLine(to: positions[pair.to])
                ctx.stroke(path, with: .foreground, lineWidth: 1)
            }
            ctx.opacity = previousOpacity
            if let dot = ctx.resolveSymbol(id: "node") {
                for point in positions {
                    ctx.draw(dot, at: point)
                }
            }
        } symbols: {
            Circle()
                .fill(.foreground)
                .mask {
                    RadialGradient(
                        colors: [.white, .clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: nodeRadius
                    )
                }
                .frame(width: nodeRadius * 2, height: nodeRadius * 2)
                .tag("node")
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            CGRect(origin: .zero, size: proxy.size).centeredSquare()
        } action: { _, newBounds in
            guard newBounds != cachedBounds else { return }
            cachedBounds = newBounds
            cachedPositions = computePositions(for: newBounds, strands: strands)
        }
        .onChange(of: GenerationKey(strandCount: strandCount, nodeCount: nodeCount)) { _, newKey in
            let regenerated = Self.makeStrands(strandCount: newKey.strandCount, nodeCount: newKey.nodeCount)
            strands = regenerated
            cachedPositions = computePositions(for: cachedBounds, strands: regenerated)
        }
        .onChange(of: LayoutKey(thicknessRatio: thicknessRatio, nodeRadius: nodeRadius, strandCount: strandCount)) { _, _ in
            cachedPositions = computePositions(for: cachedBounds, strands: strands)
        }
    }

    // MARK: - Private helpers

    private struct GenerationKey: Equatable {
        let strandCount: Int
        let nodeCount: Int
    }

    private struct LayoutKey: Equatable {
        let thicknessRatio: CGFloat
        let nodeRadius: CGFloat
        let strandCount: Int
    }

    private static func makeStrands(strandCount: Int, nodeCount: Int) -> [Strand] {
        (0..<strandCount).map { _ in
            Strand(nodeCount: nodeCount, centerBiasStrength: 2)
        }
    }

    private static func makeConnectionIndices(
        strandCount: Int,
        nodeCount: Int,
        nodeReach: Int
    ) -> [(from: Int, to: Int)] {
        guard strandCount > 1, nodeCount > 0 else { return [] }
        var indices: [(from: Int, to: Int)] = []
        indices.reserveCapacity((strandCount - 1) * nodeCount * (2 * nodeReach + 1))
        for s in 0..<(strandCount - 1) {
            let fromBase = s * nodeCount
            let toBase = (s + 1) * nodeCount
            for i in 0..<nodeCount {
                for offset in (-nodeReach)...nodeReach {
                    let wrapped = ((i + offset) % nodeCount + nodeCount) % nodeCount
                    indices.append((from: fromBase + i, to: toBase + wrapped))
                }
            }
        }
        return indices
    }

    private func computePositions(for bounds: CGRect, strands: [Strand]) -> [CGPoint] {
        guard bounds.width > 0, !strands.isEmpty else { return [] }
        let outerRadius = bounds.width / 2 - nodeRadius / 2
        let innerRadius = (bounds.width / 2) * (1 - thicknessRatio) + nodeRadius / 2
        let radialRange = outerRadius - innerRadius
        let laneWidth = radialRange / CGFloat(max(1, strandCount))
        let center = bounds.center
        return strands.enumerated().flatMap { index, strand in
            let laneMid = innerRadius + (CGFloat(index) + 0.5) * laneWidth
            let r0 = max(innerRadius, laneMid - laneWidth)
            let r1 = min(outerRadius, laneMid + laneWidth)
            let dr = r1 - r0
            return strand.nodes.map { node in
                let radius = node.radius * dr + r0
                return CGPoint(
                    x: center.x + cos(node.angle) * radius,
                    y: center.y + sin(node.angle) * radius
                )
            }
        }
    }
}

private extension CGFloat {
    nonisolated func centerBiased(strength: CGFloat) -> CGFloat {
        let c = self * 2.0 - 1.0            // remap to [-1, 1]
        let biased = c.sign == .minus       // preserve sign,
        ? -pow(-c, strength)                // apply power to magnitude
        :  pow( c, strength)
        return (biased + 1.0) / 2.0
    }
}

#Preview {
    VStack {
        StarMapRing()
            .foregroundStyle(.blue)
        StarMapRing(thicknessRatio: 0.9, strandCount: 5, nodeCount: 30, nodeReach: 2, nodeRadius: 6)
            .foregroundStyle(.green)
        StarMapRing(thicknessRatio: 0.4 , strandCount: 2, nodeCount: 15, nodeRadius: 14, lineOpacity: 1)
            .foregroundStyle(.red)
    }
    .padding()
}
