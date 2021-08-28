//
//  SessionShareView.swift
//  Andante
//
//  Created by Miles Vinson on 9/11/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class SessionShareView: UIView {
    
    private let titleLabel = UILabel()
    private let dateLabel = UILabel()
    
    private let timeCell = SessionStatsCell()
    private let practicedCell = SessionStatsCell()
    private let moodCell = SessionStatsCell()
    private let focusCell = SessionStatsCell()
    
    private let andanteIcon = UIImageView()
    private let andanteLabel = UILabel()
    
    init(session: CDSession) {
        super.init(frame: CGRect(x: 0, y: 0, width: 360, height: 510))
        
        titleLabel.text = session.getTitle()
        titleLabel.font = Fonts.bold.withSize(30)
        titleLabel.textColor = Colors.text
        self.addSubview(titleLabel)
        
        dateLabel.font = Fonts.regular.withSize(20)
        dateLabel.textColor = Colors.lightText
        dateLabel.text = session.startTime.string(dateStyle: .long)
        self.addSubview(dateLabel)
        
        timeCell.setTimeTitle(start: session.startTime, end: session.getEndTime())
        timeCell.iconView.stat = .time
        self.addSubview(timeCell)
        
        practicedCell.setTitle(Formatter.formatMinutes(mins: session.practiceTime), " practiced")
        practicedCell.iconView.stat = .practice
        self.addSubview(practicedCell)
        
        moodCell.setTitle("\(session.mood)", " / 5 mood")
        moodCell.iconView.stat = .mood
        moodCell.iconView.value = session.mood
        self.addSubview(moodCell)
        
        focusCell.setTitle("\(session.focus)", " / 5 focus")
        focusCell.iconView.stat = .focus
        focusCell.iconView.value = session.focus
        self.addSubview(focusCell)
        
        andanteIcon.image = UIImage(named: "AppIcon")
        andanteIcon.roundCorners(5)
        andanteIcon.layer.borderWidth = 1.2
        andanteIcon.layer.borderColor = Colors.lightSeparatorColor.cgColor
        andanteIcon.clipsToBounds = true
        self.addSubview(andanteIcon)
        
        andanteLabel.text = "Andante - Practice Journal"
        andanteLabel.font = Fonts.medium.withSize(10)
        andanteLabel.textColor = Colors.extraLightText
        self.addSubview(andanteLabel)
        
        self.backgroundColor = Colors.foregroundColor
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let margin: CGFloat = 40
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: margin, y: 70,
                                  width: self.bounds.width - (margin*2),
                                  height: titleLabel.bounds.size.height)
        
        dateLabel.sizeToFit()
        dateLabel.frame.origin = CGPoint(x: margin, y: titleLabel.frame.maxY + 4)
                
        let cellHeight: CGFloat = 64
        
        timeCell.frame = CGRect(
            x: margin, y: dateLabel.frame.maxY + 16,
            width: self.bounds.width,
            height: cellHeight)
        
        practicedCell.frame = CGRect(
            x: margin, y: timeCell.frame.maxY,
            width: self.bounds.width,
            height: cellHeight)
        
        moodCell.frame = CGRect(
            x: margin, y: practicedCell.frame.maxY,
            width: self.bounds.width,
            height: cellHeight)
        
        focusCell.frame = CGRect(
            x: margin, y: moodCell.frame.maxY,
            width: self.bounds.width,
            height: cellHeight)
        
        let iconSize = CGSize(18)
        andanteIcon.bounds.size = iconSize
        
        andanteLabel.sizeToFit()
        let width = andanteIcon.bounds.width + andanteLabel.bounds.width + 6
        let minX = bounds.midX - width/2
        andanteIcon.frame.origin = CGPoint(x: minX, y: focusCell.frame.maxY + 45)
        andanteLabel.frame.origin = CGPoint(x: andanteIcon.frame.maxX + 6, y: andanteIcon.center.y - andanteLabel.bounds.height/2)
        
    }
}
