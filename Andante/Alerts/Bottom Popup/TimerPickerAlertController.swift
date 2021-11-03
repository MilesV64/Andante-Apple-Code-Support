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
    private let actionButton = BottomActionButton(title: "Start Timer")
    
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
        
        actionButton.color = .clear
        self.contentView.addSubview(actionButton)
        
    }
    
    override func viewDidLayoutSubviews() {

        let buttonHeight: CGFloat = BottomActionButton.height
        
        self.contentHeight = buttonHeight + 250
        
        super.viewDidLayoutSubviews()
        
        actionButton.frame = CGRect(x: 0, y: self.contentView.bounds.maxY - buttonHeight,
                                    width: self.contentView.bounds.width,
                                    height: buttonHeight)
        
        picker.frame = CGRect(
            from: CGPoint(x: Constants.margin, y: 0),
            to: CGPoint(x: contentView.bounds.maxX - Constants.margin, y: actionButton.frame.minY))
        
        
    }
    
}
