//
//  TimerPickerAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 8/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TimerPickerAlertController: PickerAlertController {
    
    private let picker = UIDatePicker()
    private let actionButton = PushButton()
    
    public var action: ((TimeInterval)->Void)? {
        didSet {
            actionButton.action = {
                [weak self] in
                guard let self = self else { return }
                self.closeCompletion = {
                    [weak self] in
                    guard let self = self else { return }
                    self.action?(self.picker.countDownDuration)
                }
                self.close()
            }
        }
    }
    
    override func close() {
        super.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.datePickerMode = .countDownTimer
        
        picker.countDownDuration = TimeInterval(Settings.practiceTimerMinutes * 60)
        self.contentView.addSubview(picker)
        
        actionButton.setTitle("Start Timer", color: Colors.white, font: Fonts.semibold.withSize(16))
        actionButton.backgroundColor = Colors.orange
        self.contentView.addSubview(actionButton)
        
    }
    
    override func viewDidLayoutSubviews() {

        let buttonHeight: CGFloat = 50
        
        self.contentHeight = buttonHeight + 250
        
        super.viewDidLayoutSubviews()
        
        actionButton.frame = CGRect(x: Constants.margin, y: self.contentView.bounds.maxY - buttonHeight - 22,
                                    width: self.view.bounds.width - Constants.margin*2,
                                    height: buttonHeight)
        actionButton.cornerRadius = 14
        
        picker.frame = CGRect(
            from: CGPoint(x: Constants.margin, y: 0),
            to: CGPoint(x: contentView.bounds.maxX - Constants.margin*2, y: actionButton.frame.minY - 22))
        
        
    }
    
}
