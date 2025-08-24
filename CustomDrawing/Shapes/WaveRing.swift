//
//  WaveRing.swift
//  CustomDrawing
//
//  Created by Joshua Sullivan on 8/10/25.
//

import SwiftUI

/// Approximates a sine wave in a circular path, creating a wave-like ring shape.
public struct WaveRing: Shape {
    
    public var amplitudeRatio: CGFloat
    public var frequency: Int
    public var outerControlRatio: CGFloat
    public var innerControlRatio: CGFloat
    
    init(amplitudeRatio: CGFloat = 0.8, frequency: Int = 6, outerControlRatio: CGFloat = 0.25, innerControlRatio: CGFloat = 0.275) {
        self.amplitudeRatio = max(0.1, min(amplitudeRatio, 0.95))
        self.frequency = max(1, min(frequency, 60))
        self.outerControlRatio = outerControlRatio
        self.innerControlRatio = innerControlRatio
    }
    
    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * amplitudeRatio
        
        // Create the wave path using Bezier curves
        return createBezierWavePath(center: center, outerRadius: outerRadius, innerRadius: innerRadius, frequency: frequency)
    }
    
    private func createBezierWavePath(center: CGPoint, outerRadius: CGFloat, innerRadius: CGFloat, frequency: Int) -> Path {
        var path = Path()
        
        let theta = (2 * CGFloat.pi) / CGFloat(frequency)
        let halfTheta = theta * 0.5
        let cDistOuter = ((2 * CGFloat.pi * outerRadius) / CGFloat(frequency)) * outerControlRatio
        let cDistInner = ((2 * CGFloat.pi * innerRadius) / CGFloat(frequency)) * innerControlRatio
        
        path.move(to: CGPoint(x: center.x + outerRadius, y: center.y)) // Start at the first peak
        
        for i in 0..<frequency {
            let a0 = theta * CGFloat(i) // First "peak"
            let a1 = a0 + halfTheta // Valley between peaks
            let a2 = a0 + theta // Second "peak"
            let p1 = CGPoint(x: center.x + innerRadius * cos(a1), y: center.y + innerRadius * sin(a1))
            let p2 = CGPoint(x: center.x + outerRadius * cos(a2), y: center.y + outerRadius * sin(a2))
            let c0b = tangentPoints(circleCenter: center, radius: outerRadius, angleRadians: a0, tangentDistance: cDistOuter).0
            let c1 = tangentPoints(circleCenter: center, radius: innerRadius, angleRadians: a1, tangentDistance: cDistInner)
            let c2a = tangentPoints(circleCenter: center, radius: outerRadius, angleRadians: a2, tangentDistance: cDistOuter).1
            path.addCurve(to: p1, control1: c0b, control2: c1.1)
            path.addCurve(to: p2, control1: c1.0, control2: c2a)
            
        }
        
        return path
    }
    
    /// Calculates two tangent points on a circle at a given angle and distance from the intersection point.
    func tangentPoints(circleCenter: CGPoint, radius: CGFloat, angleRadians: CGFloat, tangentDistance: CGFloat) -> (CGPoint, CGPoint) {
        // Calculate the point on the circle
        let pointOnCircle = CGPoint(
            x: circleCenter.x + radius * cos(angleRadians),
            y: circleCenter.y + radius * sin(angleRadians)
        )
        
        // The tangent direction is perpendicular to the radius at this point
        // Radius direction: (cos(angleRadians), sin(angleRadians))
        // Perpendicular directions: (-sin(angleRadians), cos(angleRadians)) and (sin(angleRadians), -cos(angleRadians))
        
        let tangentDirection1 = CGPoint(x: -sin(angleRadians), y: cos(angleRadians))
        let tangentDirection2 = CGPoint(x: sin(angleRadians), y: -cos(angleRadians))
        
        // Calculate the two tangent points
        let tangentPoint1 = CGPoint(
            x: pointOnCircle.x + tangentDistance * tangentDirection1.x,
            y: pointOnCircle.y + tangentDistance * tangentDirection1.y
        )
        
        let tangentPoint2 = CGPoint(
            x: pointOnCircle.x + tangentDistance * tangentDirection2.x,
            y: pointOnCircle.y + tangentDistance * tangentDirection2.y
        )
        
        return (tangentPoint1, tangentPoint2)
    }

}

/// A hollow version of the `WaveRing` shape, creating a ring with waves on both the outer and inner edges.
public struct HollowWaveRing: Shape {
    
    /// The size of the waves relative to the radius.
    public let amplitudeRatio: CGFloat
    
    /// The frequency of the wave pattern.
    public let frequency: Int
    
    public let outerControlRatio: CGFloat
    
    public let innerControlRatio: CGFloat
    
    public let thicknessRatio: CGFloat
    
    init(amplitudeRatio: CGFloat = 0.8, frequency: Int = 6, outerControlRatio: CGFloat = 0.25, innerControlRatio: CGFloat = 0.275, thicknessRatio: CGFloat = 0.2) {
        self.amplitudeRatio = max(0.1, min(amplitudeRatio, 0.95))
        self.frequency = max(1, min(frequency, 60))
        self.outerControlRatio = outerControlRatio
        self.innerControlRatio = innerControlRatio
        self.thicknessRatio = max(0.01, min(thicknessRatio, 0.99))
    }
    
    public nonisolated func path(in rect: CGRect) -> Path {
        let thickness = min(rect.width, rect.height) * 0.5 * thicknessRatio
        
        var p = Path()
        p.addPath(WaveRing(amplitudeRatio: amplitudeRatio, frequency: frequency, outerControlRatio: outerControlRatio, innerControlRatio: innerControlRatio).path(in: rect))
        p.addPath(WaveRing(amplitudeRatio: amplitudeRatio, frequency: frequency, outerControlRatio: outerControlRatio, innerControlRatio: innerControlRatio).path(in: rect.insetBy(dx: thickness, dy: thickness)))
        return p.normalized(eoFill: true)
    }
    
}

#Preview {
    VStack {
        WaveRing()
            .foregroundStyle(.blue)
        WaveRing(amplitudeRatio: 0.5, frequency: 16)
            .foregroundStyle(.green)
        HollowWaveRing(amplitudeRatio: 0.9, frequency: 27, thicknessRatio: 0.1)
            .foregroundStyle(.red)
    }
}
