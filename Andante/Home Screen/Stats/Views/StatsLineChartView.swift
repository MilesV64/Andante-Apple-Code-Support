//
//  StatsLineChartView.swift
//  Andante
//
//  Created by Miles Vinson on 8/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class StatsLineChartView: UIView {
    
    public var color: UIColor?
    
    private var lineShape = CAShapeLayer()
    private var fillShape = CAShapeLayer()
    private var yAxisLines = CAShapeLayer()
    
    private var values: [CGFloat] = []
    
    private var xAxisLabels: [UILabel] = []
    private var yAxisLabels: [UILabel] = []
    
    public var fixedMaxValue: CGFloat?
    private var maxValue: CGFloat = 0
    public var defaultValue: CGFloat = 0
    
    public func setChart(values: [CGFloat], xAxisLabels: [String]) {
        clearData()
        reloadData(values: values, xAxisLabels: xAxisLabels)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        fillShape.fillColor = color?.withAlphaComponent(0.1).cgColor
        yAxisLines.strokeColor = Colors.text.withAlphaComponent(0.13).cgColor
        lineShape.strokeColor = color?.cgColor
        
    }
    
    private func clearData() {
        
        fillShape.removeFromSuperlayer()
        fillShape.fillColor = color?.withAlphaComponent(0.1).cgColor
        self.layer.addSublayer(fillShape)
        
        yAxisLines.removeFromSuperlayer()
        yAxisLines.strokeColor = Colors.text.withAlphaComponent(0.13).cgColor
        yAxisLines.lineWidth = 1
        yAxisLines.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(yAxisLines)
        
        lineShape.removeFromSuperlayer()
        lineShape.strokeColor = color?.cgColor
        lineShape.lineWidth = 3
        lineShape.lineCap = .round
        lineShape.lineJoin = .round
        lineShape.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(lineShape)
        
        
        values.removeAll()
        
        xAxisLabels.forEach { (label) in
            label.removeFromSuperview()
        }
        xAxisLabels.removeAll()
        
        yAxisLabels.forEach { (label) in
            label.removeFromSuperview()
        }
        yAxisLabels.removeAll()
        
    }
    
    private func reloadData(values: [CGFloat], xAxisLabels: [String]) {
        self.values = values
        
        var maxValue: CGFloat = 0
        for value in values {
            if value > maxValue {
                maxValue = value
            }
        }
        
        for str in xAxisLabels {
            let label = UILabel()
            label.text = str
            label.textAlignment = .center
            label.font = Fonts.regular.withSize(12)
            label.textColor = Colors.lightText
            self.addSubview(label)
            self.xAxisLabels.append(label)
        }
        
        self.maxValue = fixedMaxValue ?? maxValue
        
        for i in 0...2 {
            let label = UILabel()
            label.textAlignment = .right
            label.font = Fonts.regular.withSize(12)
            label.textColor = Colors.lightText
            
            if i == 0 {
                label.text = "\(fixedMaxValue == nil ? 0 : 1)"
            }
            else if i == 1 {
                label.text = "\(fixedMaxValue == nil ? Int(Int(maxValue)/2) : 3)"
            }
            else {
                label.text = "\(fixedMaxValue == nil ? Int(maxValue) : 5)"
            }
            
            self.addSubview(label)
            self.yAxisLabels.append(label)
        }
        
    }
    
    private func getYAxisSpace() -> CGFloat {
        var maxWidth: CGFloat = 0
        for label in yAxisLabels {
            let width = label.sizeThatFits(UIScreen.main.bounds.size).width
           
            if width > maxWidth {
                maxWidth = width
            }
        }
        return maxWidth
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let yAxisSpace = getYAxisSpace() + 10

        let frame = self.bounds.inset(
            by: UIEdgeInsets(top: 28, left: yAxisSpace + 10, bottom: 38, right: Constants.margin + 10))
        
        let lineWidth = frame.width / CGFloat(values.count - 1)
        
        let linePath = UIBezierPath()
        let fillPath = UIBezierPath()
        let yAxisPath = UIBezierPath()
        
        fillPath.move(to: CGPoint(x: frame.minX, y: frame.maxY))
        
        for (i, value) in values.enumerated() {
            
            let x = frame.minX + CGFloat(i)*lineWidth
            
            if value == -1 {
                
            }
            else {
                let value = fixedMaxValue != nil ? ( value / 5 ) : ( value / maxValue )
                
                let position = CGPoint(
                    x: x,
                    y: frame.maxY - (maxValue == 0 ? 0 : frame.height*value))
                
                linePath.move(to: position)
                linePath.addArc(
                    withCenter: position,
                    radius: 2, startAngle: 0, endAngle: CGFloat.pi*2, clockwise: true)
                linePath.move(to: position)
                
                fillPath.move(to: position)
                
                yAxisPath.move(to: position)
                yAxisPath.addLine(to: CGPoint(x: position.x, y: frame.maxY))
                
                if i < values.count - 1 {
                    let next = values[i+1]
                    if next == -1 {
                        fillPath.addLine(to: CGPoint(x: position.x, y: frame.maxY))
                    }
                    else {
                        let nextValue = fixedMaxValue != nil ? ( next / 5 ) : ( next / maxValue )
                        let nextPosition = CGPoint(
                            x: frame.minX + CGFloat(i+1)*lineWidth,
                            y: frame.maxY - (maxValue == 0 ? 0 : frame.height*nextValue))
                        linePath.addLine(to: nextPosition)
                        
                        fillPath.addLine(to: nextPosition)
                        fillPath.addLine(to: CGPoint(x: nextPosition.x, y: frame.maxY))
                        fillPath.addLine(to: CGPoint(x: position.x, y: frame.maxY))
                        fillPath.addLine(to: position)
                    }
                }
                
                
            }
            
            let label = xAxisLabels[i]
            label.sizeToFit()
            label.frame.origin = CGPoint(
                x: x - label.bounds.width/2,
                y: frame.maxY + 12)
            
        }
        

        fillShape.path = fillPath.cgPath
        
        lineShape.path = linePath.cgPath
        
        yAxisLines.path = yAxisPath.cgPath
        
        let labelFrame = fixedMaxValue == nil ? frame : CGRect(
            x: frame.minX, y: frame.minY,
            width: frame.width, height: frame.height * 0.8)
        
        for (i, label) in yAxisLabels.enumerated() {
            var centerY: CGFloat = frame.minY
            if i == 0 {
                centerY = labelFrame.maxY
            }
            else if i == 1 {
                centerY = labelFrame.midY
            }
            
            label.frame = CGRect(
                x: 0, y: centerY - 15,
                width: labelFrame.minX - 10,
                height: 30)

        }
        
        
    }
    
}

