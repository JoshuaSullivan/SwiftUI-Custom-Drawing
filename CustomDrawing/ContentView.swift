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
        TechRing(insetRatio: 0.05, spanCountRange: 6...6).stroke(.red, lineWidth: 4),
        HollowTechRing().fill(.orange),
        TechRing(insetRatio: 0.2, spanCountRange: 1...3).stroke(.black, lineWidth: 2).fill(.yellow),
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
        
        OffsetStreakRing(thicknessRatio: 0.5, streakSpan: .pi * 0.3333, clockwise: false)
            .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            .foregroundStyle(.green),
        
        OffsetStreakRing(thicknessRatio: 0.6, streakCount: 12, streakSpan: .pi * 1.8, streakOffset: .pi * 0.05)
            .stroke(style: StrokeStyle(lineWidth: 2))
            .foregroundStyle(.red),
    ]
    
    private let gaugeRings: [any View] = [
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
    private let rowTitles = ["Gear Rings", "Burst Rings", "Tech Rings", "Wave Rings", "Sparse Streak Ring", "Offset Streak Ring", "Gauge Ring", "Shader Effects"]
    
    init() {
        allViews = [gear, burst, tech, wave, sparseStreaks, offsetStreaks, gaugeRings, shader]
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
