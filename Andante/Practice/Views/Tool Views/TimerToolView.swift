//
//  TimerToolView.swift
//  Andante
//
//  Created by Miles Vinson on 8/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

protocol TimerToolDelegate: class {
    func timerToolDidFinish()
}

class TimerToolView: PracticeToolView {
    
    public weak var delegate: TimerToolDelegate?
    
    public var isTimerRunning = false
    private var progress: CGFloat = 0
    
    private let alertLabel = UILabel()
    private let alertIcon = UIImageView()
    
    private let progressBarBG = UIView()
    private let progressBar = UIView()
    
    private var alertDate: Date?
    private var timerDuration: TimeInterval?
    private var displayLink: CADisplayLink?
    
    override init() {
        super.init()
        
        alertIcon.image = UIImage(name: "bell.fill", pointSize: 15, weight: .medium)
        alertIcon.setImageColor(color: PracticeColors.lightText)
        contentView.addSubview(alertIcon)
        
        alertLabel.text = "4:32 PM"
        alertLabel.textColor = PracticeColors.text
        alertLabel.font = Fonts.medium.withSize(16)
        contentView.addSubview(alertLabel)
        
        progressBarBG.backgroundColor = PracticeColors.lightFill
        contentView.addSubview(progressBarBG)
        
        progressBar.backgroundColor = PracticeColors.purple
        contentView.addSubview(progressBar)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let barHeight: CGFloat = 4
        
        alertLabel.sizeToFit()
        alertLabel.frame.origin = CGPoint(
            x: Constants.smallMargin + 26,
            y: floor(contentView.bounds.midY - alertLabel.bounds.height/2))
        
        alertIcon.sizeToFit()
        alertIcon.frame.origin = CGPoint(
            x: alertLabel.frame.minX - alertIcon.bounds.width - 6,
            y: alertLabel.frame.midY - alertIcon.bounds.height/2)
        
        progressBarBG.frame = CGRect(
            x: alertLabel.frame.maxX + Constants.smallMargin,
            y: contentView.bounds.midY - barHeight/2,
            width: contentView.bounds.width - Constants.margin*2 - alertLabel.frame.maxX,
            height: barHeight)
        
        progressBar.layer.cornerRadius = barHeight/2
        progressBarBG.layer.cornerRadius = barHeight/2
        
    }
    
    private func layoutProgressBar() {
        progressBar.frame = CGRect(
            x: progressBarBG.frame.minX,
            y: progressBarBG.frame.minY,
            width: progressBarBG.bounds.width * progress,
            height: progressBarBG.bounds.height)
    }
    
    public func startTimer(_ duration: TimeInterval) {
        let endDate = Date().addingTimeInterval(duration)
        alertLabel.text = endDate.string(timeStyle: .short)
        
        progress = 0
        self.timerDuration = duration
        self.alertDate = endDate
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
        displayLink?.add(to: .current, forMode: .common)
        
        setNeedsLayout()
    }
    
    public func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
        progress = 0
    }
    
    @objc func updateTimer() {
        
        guard let alertDate = self.alertDate, let timerDuration = self.timerDuration else { return }
        
        let progress = CGFloat( 1 - alertDate.timeIntervalSince(Date()) / timerDuration )
        
        if progress >= 1 {
            self.progress = 1
            layoutProgressBar()
            displayLink?.invalidate()
            displayLink = nil
            delegate?.timerToolDidFinish()
        }
        else {
            self.progress = progress
            layoutProgressBar()
        }
        
    }
    
}
