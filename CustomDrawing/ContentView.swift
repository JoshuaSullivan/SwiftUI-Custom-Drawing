//
//  ContentView.swift
//  CustomDrawing
//
//  Created by Joshua Sullivan on 7/10/25.
//

import SwiftUI

struct ContentView: View {
        
    private let gear: [any View] = [
        GearRingView()
            .foregroundStyle(.red),
        GearRingView(toothCount: 7, toothDepthRatio: 0.5, spokeCount: 3, spokeWidthRatio: 0.9, includeCenterHole: true)
            .foregroundStyle(.green)
            .rotationEffect(.degrees(18)),
        GearRingView(toothCount: 64, toothDepthRatio: 0.9, spokeCount: 12, includeCenterHole: false)
            .foregroundStyle(.blue),
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
    ]
    
    private let shader: [any View] = [
            Circle()
                .colorEffect(ShaderLibrary.truchetCurve(
                    .float2(200, 200),
                    .float(0)
                )),
            Circle()
                .colorEffect(ShaderLibrary.truchetMaze(
                    .float2(200, 200),
                )),
        
    ]
    
    private let allViews: [[any View]]
    private let rowTitles = ["Gear Rings", "Burst Rings", "Tech Rings", "Wave Rings", "Shader Effects"]
    
    init() {
        allViews = [gear, burst, tech, wave, shader]
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
