//
//  CalendarGoalCell.swift
//  Andante
//
//  Created by Miles Vinson on 7/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CalendarGoalViewCell: UICollectionViewCell {
    
    private let content = UIView()
    private var dayLabel = UILabel()
    private let ring = ProgressRing()
    
    public var progress: CGFloat = 0 {
        didSet {
            ring.progress = progress
            ring.updateProgressWithoutAnimation()
            ring.alpha = progress > 0 ? 1 : 0
        }
    }

    
    public var day: Day? {
        didSet {
            guard let day = day else { return }
            
            dayLabel.text = "\(day.day)"
            
            if day == Day(date: Date()) {
                dayLabel.textColor = Colors.orange
                dayLabel.font = Fonts.semibold.withSize(15)
            }
            else {
                dayLabel.textColor = Colors.text
                dayLabel.font = Fonts.medium.withSize(15)
            }
        }
    }

    
    public var isInMonth = true {
        didSet {
            setContentAlpha()
        }
    }
    
    public var isPastToday = false {
        didSet {
            setContentAlpha()
        }
    }
    
    private func setContentAlpha() {
        if isInMonth && !isPastToday {
            content.alpha = 1
            ring.alpha = progress > 0 ? 1 : 0
        }
        else if isInMonth && isPastToday {
            content.alpha = 0.2
            ring.alpha = 0
        }
        else {
            content.alpha = 0
        }
    }
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.addSubview(content)
        
        content.layer.shouldRasterize = true
        content.layer.rasterizationScale = UIScreen.main.scale * 2
        
        ring.lineWidth = isSmallScreen() ? 4 : 5
        content.addSubview(ring)
        
        dayLabel.textColor = Colors.text
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
        
        let size = floor(min(self.bounds.width-2, self.bounds.height-2))
        let elementsFrame = CGRect(
            x: Int(self.bounds.center.x - size/2),
            y: Int(self.bounds.center.y - size/2),
            width: Int(size), height: Int(size))
        
        
        dayLabel.frame = elementsFrame
        
        let ringWidth = min(elementsFrame.width, 40)
        ring.bounds.size = CGSize(ringWidth)
        ring.center = elementsFrame.center

    }
    
}
