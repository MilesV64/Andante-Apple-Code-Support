//
//  StatsChartView.swift
//  Andante
//
//  Created by Miles Vinson on 8/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class StatsChartView: UIView {
    
    public var color: UIColor?
    
    private var bars: [UIView] = []
    private var values: [CGFloat] = []
    private var xAxisLabels: [UILabel] = []
    private var yAxisLabels: [UILabel] = []
    
    public var fixedMaxValue: CGFloat?
    private var maxValue: CGFloat = 0
    
    public func setChart(values: [CGFloat], xAxisLabels: [String]) {
        clearData()
        reloadData(values: values, xAxisLabels: xAxisLabels)
    }
    
    private func clearData() {
        
        bars.forEach { (bar) in
            bar.removeFromSuperview()
        }
        bars.removeAll()
        
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
            
            let bar = UIView()
            bar.backgroundColor = color
            bar.roundCorners(2)
            self.addSubview(bar)
            bars.append(bar)
            
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
                label.text = fixedMaxValue == nil ? "0m" : "1"
            }
            else if i == 1 {
                label.text = fixedMaxValue == nil ? "\(Formatter.formatMinutesShorter(mins: Int(maxValue)/2))" : "3"
            }
            else {
                label.text = fixedMaxValue == nil ? "\(Formatter.formatMinutesShorter(mins: Int(maxValue)))" : "5"
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
                
        let yAxisSpace = getYAxisSpace() + 14

        let barsFrame = self.bounds.inset(
            by: UIEdgeInsets(top: 28, left: yAxisSpace + 14, bottom: 38, right: Constants.margin))
        
        let barWidth = barsFrame.width / CGFloat(bars.count)
        
        for (i, bar) in bars.enumerated() {
            let value = values[i]
            
            if value == 0 {
                bar.backgroundColor = Colors.lightColor
                bar.frame = CGRect(
                    x: barsFrame.minX + CGFloat(i)*barWidth,
                    y: barsFrame.maxY - 1,
                    width: barWidth,
                    height: 1)
            }
            else {
                let value = fixedMaxValue != nil ? ( value / 5 ) : ( value / maxValue )
                let height = value*barsFrame.height
                
                bar.alpha = 0.5 + (value / 2)
                bar.backgroundColor = color
                
                bar.frame = CGRect(
                    x: barsFrame.minX + CGFloat(i)*barWidth,
                    y: barsFrame.maxY - height,
                    width: barWidth,
                    height: height).insetBy(dx: 0.5, dy: 0)
                
            }
                        
            let label = xAxisLabels[i]
            label.sizeToFit()
            label.frame.origin = CGPoint(
                x: bar.frame.midX - label.bounds.width/2,
                y: barsFrame.maxY + 12)
            
        }
        
        let frame = fixedMaxValue == nil ? barsFrame : CGRect(
            x: barsFrame.minX, y: barsFrame.minY,
            width: barsFrame.width, height: barsFrame.height * 0.8)
        
        for (i, label) in yAxisLabels.enumerated() {
            var centerY: CGFloat = barsFrame.minY
            if i == 0 {
                centerY = frame.maxY
            }
            else if i == 1 {
                centerY = frame.midY
            }
            
            label.frame = CGRect(
                x: 0, y: centerY - 15,
                width: frame.minX - 14,
                height: 30)

        }
        
        
    }
    
}

