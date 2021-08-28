//
//  ProgressCircle.swift
//  AndanteWidgetExtension
//
//  Created by Miles Vinson on 10/13/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import SwiftUI
import WidgetKit

struct RingShape: Shape {
    static func percentToAngle(percent: Double) -> Double {
        (percent / 100 * 360) - 90
    }
    
    private var percent: Double
    
    init(percent: Double = 100) {
        self.percent = min(100, percent)
    }
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width/2,
            startAngle: Angle(degrees: -90),
            endAngle: Angle(degrees: RingShape.percentToAngle(percent: percent)),
            clockwise: false)
        
        return path
        
    }
}

struct ShadowShape: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width/2,
            startAngle: Angle(degrees: -150),
            endAngle: Angle(degrees: -90),
            clockwise: false)
        
        return path
        
    }
}

struct ShadowMask: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width/2,
            startAngle: Angle(degrees: -95),
            endAngle: Angle(degrees: 50),
            clockwise: false)
        
        return path
        
    }
}

struct ShadowCover: Shape {
    
    func path(in rect: CGRect) -> Path {
        
        var path = Path()
        
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width/2,
            startAngle: Angle(degrees: 180),
            endAngle: Angle(degrees: 270),
            clockwise: false)
        
        return path
        
    }
}

struct ProgressCircle: View {
    private let ringWidth: CGFloat
    private let percent: Double
    
    init(percent: Double, ringWidth: CGFloat) {
        self.percent = min(100, percent)
        self.ringWidth = ringWidth
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RingShape()
                    .stroke(lineWidth: ringWidth)
                    .fill(Color("LightColor"))
                
                RingShape(percent: percent)
                    .stroke(style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                    .fill(Color("AndanteOrange"))
                
                if percent >= 100 {
                    ShadowShape()
                        .stroke(style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .fill(Color("AndanteOrange"))
                        .shadow(color: .black, radius: 9, x: 12, y: 2)
                        .mask(ShadowMask()
                                .stroke(style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                                .fill(Color("AndanteOrange")))
                    
                    ShadowCover()
                        .stroke(style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .fill(Color("AndanteOrange"))
                }
                

            }
            .padding(ringWidth/2)
        }
    }
    
    private func getEndOffset(_ size: CGSize) -> CGSize {
        let radius = size.width/2
        let p = CGFloat(percent/100)
        let total = 2*CGFloat.pi
        let start = CGFloat.pi/2
        let angle = total*p - start
        
        return CGSize(
            width: radius*cos(angle),
            height: radius*sin(angle))
    }
    
    
}

extension Double {
    func toRadians() -> Double {
        return self * Double.pi / 180
    }
    func toCGFloat() -> CGFloat {
        return CGFloat(self)
    }
}

struct ProgressCircle_Previews: PreviewProvider {
    static var previews: some View {
        ProgressCircle(percent: 100, ringWidth: 8)
            .frame(width: 100, height: 100)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
