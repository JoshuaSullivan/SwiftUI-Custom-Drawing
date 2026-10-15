//
//  NodeFXAppIcon.swift
//  CustomDrawing
//
//  Created by Joshua Sullivan on 7/18/26.
//

import SwiftUI
import RingsOfPower

struct NodeFXAppIcon: View {
    var body: some View {
        ConstellationRing(thicknessRatio: 0.6, strandCount: 3, nodeCount: 24, nodeReach: 1, nodeRadius: 12, lineOpacity: 0.6)
    }
}

#Preview {
    ZStack {
        Rectangle()
            .foregroundStyle(Color(hue: 0, saturation: 0, brightness: 0.1, opacity: 1))
        Circle()
            .foregroundStyle(AngularGradient(colors: [.red, .green, .blue, .red], center: .center))
            .mask(NodeFXAppIcon().padding(60))
    }
    .frame(width: 1024, height: 1024)
}
