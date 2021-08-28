//
//  ProgressCircle.swift
//  Andante
//
//  Created by Miles Vinson on 9/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import SwiftUI

struct IconProgressCircle: View {
    var icon: String = "Piano"
    var progress: CGFloat = 0
    
    var body: some View {
        ZStack {
            Image(icon).resizable()
                .padding(4)
            Circle()
                .stroke(lineWidth: 4)
                .foregroundColor(Color("LightColor"))
            Circle()
                .trim(from: 0.0, to: min(progress, 1))
                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.AndanteOrange)
                .rotationEffect(Angle(degrees: 270.0))
        }
        .frame(width: 44, height: 44)
            
            
    }
}
