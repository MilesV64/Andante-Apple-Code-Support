//
//  CalendarPickerCell.swift
//  Andante
//
//  Created by Miles Vinson on 6/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CalendarPickerCell: UICollectionViewCell {
    
    private let content = UIView()
    private var dayLabel = UILabel()
    private var bgView = UIView()
    
    public var day: Day? {
        didSet {
            guard let day = day else { return }
            
            dayLabel.text = "\(day.day)"
            
            if day == Day(date: Date()) {
                bgView.backgroundColor = Colors.lightColor
            }
            else {
                bgView.backgroundColor = .clear
            }
        }
    }
    
    public var isInMonth = true {
        didSet {
            if isInMonth {
                content.alpha = 1
            }
            else {
                content.alpha = 0.2
            }
        }
    }
    
    public var selectedDay = false {
        didSet {
            if selectedDay {
                bgView.backgroundColor = Colors.orange
                bgView.setShadow(radius: 5, yOffset: 2, opacity: 0.08)
                dayLabel.textColor = Colors.white
                dayLabel.font = Fonts.semibold.withSize(17)
            }
            else {
                if day == Day(date: Date()) {
                    bgView.backgroundColor = Colors.lightColor
                }
                else {
                    bgView.backgroundColor = .clear
                }
                
                bgView.setShadow(radius: 5, yOffset: 2, opacity: 0)
                
                dayLabel.textColor = Colors.text
                dayLabel.font = Fonts.regular.withSize(16)
            }
        }
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.addSubview(content)
        
        bgView = UIView()
        bgView.backgroundColor = .clear
        content.addSubview(bgView)
        
        dayLabel = UILabel()
        dayLabel.textColor = Colors.text
        dayLabel.font = Fonts.medium.withSize(16)
        dayLabel.textAlignment = .center
        content.addSubview(dayLabel)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
  
        content.frame = self.bounds
        
        var elementsFrame = self.bounds.insetBy(dx: 2.0, dy: 2.0)
        
        let smallestSide = min(elementsFrame.width, elementsFrame.height)
        elementsFrame = elementsFrame.insetBy(dx: (elementsFrame.width - smallestSide) / 2.0,
            dy: (elementsFrame.height - smallestSide) / 2.0).offsetBy(dx: 1, dy: 0)
        
        
        dayLabel.frame = elementsFrame.integral
 
        bgView.frame = elementsFrame.integral
        bgView.roundCorners(prefersContinuous: false)
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            
        }
    }
}
