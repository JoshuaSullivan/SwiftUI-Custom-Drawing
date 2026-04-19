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

    public let strands: [Strand]

    @State private var cache: [CGRect : (nodes: [CGPoint], connections: [(CGPoint, CGPoint)])] = [:]

    public init(thicknessRatio: CGFloat = 0.5, strandCount: Int = 3, nodeCount: Int = 20, nodeReach: Int = 1, nodeRadius: CGFloat = 10) {
        self.thicknessRatio = thicknessRatio
        self.strandCount = strandCount
        self.nodeCount = nodeCount
        self.nodeReach = nodeReach
        self.nodeRadius = nodeRadius

        strands = (0..<strandCount).map { _ in
            Strand(nodeCount: nodeCount, centerBiasStrength: 2)
        }
    }

    public var body: some View {
        Canvas { ctx, size in
            let bounds = CGRect(origin: .zero, size: size).centeredSquare()
            let resolvedNodes: [CGPoint]
            let connections: [(CGPoint, CGPoint)]
            if let cachedValues = cache[bounds] {
                resolvedNodes = cachedValues.nodes
                connections = cachedValues.connections
            } else {
                let r1NoInset = (bounds.width) / 2
                let r0NoInset = r1NoInset * (1 - thicknessRatio)
                let r1 = r1NoInset - nodeRadius / 2
                let r0 = r0NoInset + nodeRadius / 2
                let dr = r1 - r0
                // Divide the radial range into strandCount lanes. Each strand's
                // window spans 2 lane widths, centered on its lane midpoint, so
                // neighbors overlap by one lane. The center bias on node.radius
                // keeps most nodes near the lane center despite the wider window.
                let laneWidth = dr / CGFloat(strandCount)
                let center = bounds.center
                let res = strands.enumerated().map { index, strand in
                    let laneMid = r0 + (CGFloat(index) + 0.5) * laneWidth
                    let r0s = max(r0, laneMid - laneWidth)
                    let r1s = min(r1, laneMid + laneWidth)
                    let drs = r1s - r0s
                    return strand.nodes.map { node in
                        let x = center.x + cos(node.angle) * (node.radius * drs + r0s)
                        let y = center.y + sin(node.angle) * (node.radius * drs + r0s)
                        return CGPoint(x: x, y: y)
                    }
                }
                let con: [(CGPoint, CGPoint)] = zip(res, res.dropFirst()).flatMap { s0, s1 in
                    let c = s0.count
                    return (0..<c).flatMap { i in
                        let p0 = s0[i]
                        return ((i - nodeReach)...(i + nodeReach)).map { j in
                            let index = (j + c) % c
                            let p1 = s1[index]
                            return (p0, p1)
                        }
                    }
                }
                let resNodes = res.flatMap { $0 }
                cache.removeAll()
                cache[bounds] = (nodes: resNodes, connections: con)
                resolvedNodes = resNodes
                connections = con
            }
            for c in connections {
                var p = Path()
                p.move(to: c.0)
                p.addLine(to: c.1)
                ctx.stroke(p, with: .foreground, lineWidth: 1)
            }
            if let dot = ctx.resolveSymbol(id: "node") {
                for n in resolvedNodes {
                    ctx.draw(dot, at: n)
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
        StarMapRing(thicknessRatio: 0.4 , strandCount: 2, nodeCount: 15, nodeRadius: 14)
            .foregroundStyle(.red)
    }
    .padding()
}
