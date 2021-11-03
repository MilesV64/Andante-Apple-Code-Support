//
//  TimerPopupStackContentView.swift
//  Andante
//
//  Created by Miles on 10/29/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class TimerPopupStackContentView: PopupStackContentView {
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        return 310
    }
    
    private let picker = UIDatePicker()
    private let actionButton = PushButton()
    
    public var action: ((TimeInterval)->Void)? {
        didSet {
            actionButton.action = {
                [weak self] in
                guard let self = self else { return }
                self.popupViewController?.hide(completion: { [weak self] in
                    guard let self = self else { return }
                    self.action?(self.picker.countDownDuration)
                })
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        picker.datePickerMode = .countDownTimer
        
        picker.countDownDuration = TimeInterval(Settings.practiceTimerMinutes * 60)
        self.addSubview(picker)
        
        actionButton.setTitle("Start Timer", color: Colors.white, font: Fonts.semibold.withSize(16))
        actionButton.backgroundColor = Colors.orange
        self.addSubview(actionButton)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        
        let buttonHeight: CGFloat = 50
        
        actionButton.frame = CGRect(x: Constants.margin, y: self.bounds.maxY - buttonHeight - 22,
                                    width: self.bounds.width - Constants.margin*2,
                                    height: buttonHeight)
        actionButton.cornerRadius = 25
        
        picker.frame = CGRect(
            from: CGPoint(x: Constants.margin, y: 0),
            to: CGPoint(x: self.bounds.maxX - Constants.margin*2, y: actionButton.frame.minY - 22))
        
        
    }
    
}
