//
//  ContentView.swift
//  CustomDrawing
//
//  Created by Joshua Sullivan on 7/10/25.
//

import SwiftUI

struct ContentView: View {
    
    private let gear: [any View] = [
        GearRing().stroke(lineWidth: 2).foregroundStyle(.blue),
        GearRing(toothCount: 6, toothDepthRatio: 0.7, spokeCount: 12, spokeWidthRatio: 0.25, includeCenterHole: true).foregroundStyle(.green),
        GearRing(toothCount: 48, toothDepthRatio: 0.9, spokeCount: 8, spokeWidthRatio: 0.8, includeCenterHole: false).foregroundStyle(.red),
    ]
    
    private let burst: [any View] = [
        BurstRing(thickness: 40, backgroundColor: .blue, foregroundColor: .green),
        BurstRing(thickness: 20, backgroundColor: .red, foregroundColor: .yellow),
        BurstRing(thickness: 10, backgroundColor: .purple, foregroundColor: .orange),
    ]
    
    private let tech: [any View] = [
        TechRing().foregroundStyle(.blue),
        HollowTechRing(thicknessRatio: 0.25).foregroundStyle(.green),
        TechRing(insetRatio: 0.05, arcCountRange: 6...6).stroke(.red, lineWidth: 4),
        HollowTechRing().fill(.orange),
        TechRing(insetRatio: 0.2, arcCountRange: 1...3).stroke(.black, lineWidth: 2).fill(.yellow),
    ]
    
    private let wave: [any View] = [
        WaveRing()
            .foregroundStyle(.blue),
        WaveRing(amplitudeRatio: 0.5, frequency: 16)
            .foregroundStyle(.green),
        HollowWaveRing(amplitudeRatio: 0.9, frequency: 27, thicknessRatio: 0.1)
            .foregroundStyle(.red),
        HollowWaveRing(amplitudeRatio: 0.4, frequency: 2, thicknessRatio: 0.5)
            .foregroundStyle(.purple),
        HollowWaveRing(amplitudeRatio: 0.2, frequency: 1, thicknessRatio: 0.3)
            .foregroundStyle(.orange),
        WaveRing(frequency: 16)
            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [0.01, 6]))
            .foregroundStyle(.gray),
    ]
    
    private let sparseStreaks: [any View] = [
        SparseStreakRing()
            .stroke(lineWidth: 1)
            .foregroundStyle(.blue),
        
        SparseStreakRing(thicknessRatio: 0.2, layerCount: 4, streaksPerLayer: 2...6)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .foregroundStyle(.green),
        
        SparseStreakRing(thicknessRatio: 0.5, layerCount: 3, streaksPerLayer: 1...1)
            .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round))
            .foregroundStyle(.red),
    ]
    
    private let offsetStreaks: [any View] = [
        OffsetStreakRing()
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(.blue),
        
        OffsetStreakRing(thicknessRatio: 0.5, streakArc: .pi * 0.3333, clockwise: false)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.green),
        
        OffsetStreakRing(thicknessRatio: 0.6, streakCount: 12, streakArc: .pi * 1.8, streakOffset: .pi * 0.05)
            .stroke(style: StrokeStyle(lineWidth: 2))
            .foregroundStyle(.red),
    ]
    
    private let gauge: [any View] = [
        GaugeRing()
            .stroke(style: .init(lineWidth: 2))
            .foregroundStyle(.blue),
        
        GaugeRing(tickCount: 120, thicknessRatio: 0.05)
            .stroke(style: StrokeStyle(lineWidth: 1))
            .foregroundStyle(.green),
        
        ZStack {
            GaugeRing(tickCount: 64)
                .stroke()
                .foregroundStyle(.yellow)
            
            GaugeRing(tickCount: 16, thicknessRatio: 0.2)
                .stroke(style: StrokeStyle(lineWidth: 2))
                .foregroundStyle(.red)
        }
    ]
    
    private let broadcast: [any View] = [
        BroadcastRing()
            .stroke(lineWidth: 2)
            .foregroundStyle(.blue),
        
        BroadcastRing(thicknessRatio: 0.5, layerCount: 12, rayCountRange: 3...3, uniformSpacing: false)
            .stroke()
            .foregroundStyle(.green),
        
        BroadcastRing(thicknessRatio: 0.9, layerCount: 8, rayCountRange: 6...6, arcWidthRatioRange: 0.3...0.3, uniformSpacing: true)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .foregroundStyle(.red),
    ]
    
    private let racetrack: [any View] = [
        RacetrackRing()
            .stroke(lineWidth: 2)
            .foregroundStyle(.blue),

        RacetrackRing(thicknessRatio: 0.3, loopCount: 1, arc: Arc(start: .degrees(270), end: .degrees(90)))
            .stroke(style: StrokeStyle(lineWidth: 16, lineCap: .round))
            .foregroundStyle(.green),

        RacetrackRing(thicknessRatio: 0.5, loopCount: 5, arc: Arc(start: .degrees(135), end: .degrees(225)))
            .stroke(lineWidth: 3)
            .foregroundStyle(.red),
    ]

    private let metaRing: [any View] = [
        MetaRing(thicknessRatio: 0.2, repeatCount: 12, orientation: .radial) {
            Rectangle()
                .fill(.blue)
        },

        MetaRing(thicknessRatio: 0.15, repeatCount: 6, orientation: .fixed) {
            StarRing(points: 5, innerRadiusRatio: 0.4)
                .fill(.orange)
        },

        MetaRing(
            views: [
                Circle().fill(.red),
                Rectangle().fill(.orange),
                Circle().fill(.yellow),
                Rectangle().fill(.green),
                Circle().fill(.blue),
            ] as [any View],
            thicknessRatio: 0.2
        ),
    ]

    private let shader: [any View] = [
        
        Circle()
            .colorEffect(ShaderLibrary.truchetHalfTri(
                .float2(200, 200),
                .color(.blue),
                .color(.green),
            )),
        
        Circle()
            .colorEffect(ShaderLibrary.truchetCurve(
                .float2(200, 200),
                .color(.orange),
                .color(.red),
            )),
        Circle()
            .colorEffect(ShaderLibrary.truchetMaze(
                .float2(200, 200),
                .color(.clear),
                .color(.blue),
            )),
        
    ]
    
    private let allViews: [[any View]]
    private let rowTitles = ["Gear Rings", "Burst Rings", "Tech Rings", "Wave Rings", "Sparse Streak Ring", "Offset Streak Ring", "Gauge Ring", "Broadcast Ring", "Racetrack Ring", "Meta Ring", "Shader Effects"]

    init() {
        allViews = [gear, burst, tech, wave, sparseStreaks, offsetStreaks, gauge, broadcast, racetrack, metaRing, shader]
    }
    
    var body: some View {
        ScrollView(.vertical) {
            LazyVStack {
                ForEach(0..<allViews.count, id: \.self) { index in
                    VStack(spacing: 2) {
                        Text(rowTitles[index])
                            .font(.title)
                        HorizontalScrollRow(views: allViews[index])
                            .frame(height: 200)
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct HorizontalScrollRow: View {
    let views: [any View]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 12) {
                ForEach(Array(views.enumerated()), id: \.offset) { index, view in
                    AnyView(view)
                        .frame(width: 200)
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    ContentView()
}
