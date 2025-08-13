//
//  GearRing.swift
//  CustomDrawing
//
//  Created by Joshua Sullivan on 7/10/25.
//

import SwiftUI

struct GearRingView: View {
    
    var toothCount: Int
    var toothDepthRatio: CGFloat
    var spokeCount: Int
    var spokeWidthRatio: CGFloat
    var includeCenterHole: Bool
    
    var body: some View {
        Canvas { context, size in
            let dim = min(size.width, size.height)
            let dx = (size.width - dim) / 2
            let dy = (size.height - dim) / 2
            let drawRect = CGRect(x: dx, y: dy, width: dim, height: dim)
            let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
            let rOuter = dim / 2
            let rInner = rOuter * toothDepthRatio
            let toothAngle = (CGFloat.pi * 2) / CGFloat(toothCount)
            let segmentAngle = toothAngle / 4
            var p = Path()
            p.move(to: CGPoint(x: rInner + center.x, y: center.y))
            for i in 0..<toothCount {
                let a = toothAngle * CGFloat(i)
                for j in (1...4) {
                    let a0 = a + segmentAngle * CGFloat(j)
                    let r0 = (j / 2) % 2 == 0 ? rInner : rOuter
                    p.addLine(to: CGPoint(x: r0 * cos(a0) + center.x, y: r0 * sin(a0) + center.y))
                }
            }
            if spokeCount >= 2 {
                let holeWidth = (CGFloat.pi * 2) / CGFloat(spokeCount) * spokeWidthRatio
                let sOuter = rOuter * (toothDepthRatio - 0.1)
                let sInner = sOuter * 0.35
                for i in 0..<spokeCount {
                    let a0 = (CGFloat.pi * 2 / CGFloat(spokeCount)) * CGFloat(i)
                    let a1 = a0 + holeWidth
                    let a2 = a1 - holeWidth * 0.25 * spokeWidthRatio
                    let a3 = a0 + holeWidth * 0.25 * spokeWidthRatio
                    let start = CGPoint(x: cos(a0) * sOuter + center.x, y: sin(a0) * sOuter + center.y)
                    p.move(to: start)
                    p.addArc(center: center, radius: sOuter, startAngle: .radians(a0), endAngle: .radians(a1), clockwise: false)
                    p.addLine(to: CGPoint(x: cos(a2) * sInner + center.x, y: sin(a2) * sInner + center.y))
                    p.addArc(center: center, radius: sInner, startAngle: .radians(a2), endAngle: .radians(a3), clockwise: true)
                    p.addLine(to: start)
                }
                if includeCenterHole {
                    p.addArc(center: center, radius: sInner * 0.4, startAngle: .radians(0), endAngle: .radians(CGFloat.pi * 2), clockwise: false)
                }
            } else if includeCenterHole {
                p.addArc(center: center, radius: rOuter * 0.1, startAngle: .radians(0), endAngle: .radians(CGFloat.pi * 2), clockwise: false)
            }
            context.fill(p, with: .foreground, style: .init(eoFill: true))
        }
    }
    
    init(toothCount: Int = 24, toothDepthRatio: CGFloat = 0.8, spokeCount: Int = 6, spokeWidthRatio: CGFloat = 0.7, includeCenterHole: Bool = true) {
        self.toothCount = max(2, min(toothCount, 64))
        self.toothDepthRatio = max(0.65, min(toothDepthRatio, 1))
        self.spokeCount = max(0, min(spokeCount, 12))
        self.spokeWidthRatio = max(0.2, min(spokeWidthRatio, 0.9))
        self.includeCenterHole = includeCenterHole
    }
}

#Preview {
    VStack {
        GearRingView()
            .foregroundStyle(.red)
        GearRingView(toothCount: 7, toothDepthRatio: 0.5, spokeCount: 3, spokeWidthRatio: 0.9, includeCenterHole: true)
            .foregroundStyle(.green)
            .rotationEffect(.degrees(18))
        GearRingView(toothCount: 64, toothDepthRatio: 0.9, spokeCount: 12, includeCenterHole: false)
            .foregroundStyle(.blue)
    }
    .padding()
}
