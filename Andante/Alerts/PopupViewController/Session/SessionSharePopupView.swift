//
//  SessionSharePopupView.swift
//  Andante
//
//  Created by Miles Vinson on 2/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class SessionSharePopupView: PopupContentView {
    
    private let header = PopupSecondaryViewHeader(title: "Share Session")
    
    private var options: [ShareOption] = []
    
    private let actionButton = PopupActionButtonView("Share")
    public var action: ((Set<SessionOptionsPopupController.ShareType>)->())?
    
    private var selectedOptions = Set<SessionOptionsPopupController.ShareType>()
    
    init(session: CDSession) {
        super.init()
        
        addSubview(header)
        
        let shareSession = ShareOption(.session)
        selectedOptions.insert(.session)
        shareSession.action = {
            [weak self] isOn in
            guard let self = self else { return }
            if isOn {
                self.selectedOptions.insert(.session)
            } else {
                self.selectedOptions.remove(.session)
            }
            self.updateActionButton()
        }
        options.append(shareSession)
        
        if session.hasNotes {
            let shareNotes = ShareOption(.notes)
            selectedOptions.insert(.notes)
            shareNotes.action = {
                [weak self] isOn in
                guard let self = self else { return }
                if isOn {
                    self.selectedOptions.insert(.notes)
                } else {
                    self.selectedOptions.remove(.notes)
                }
                self.updateActionButton()
            }
            options.append(shareNotes)
        }
        
        if session.hasRecording {
            let shareRecording = ShareOption(.recording)
            selectedOptions.insert(.recording)
            shareRecording.action = {
                [weak self] isOn in
                guard let self = self else { return }
                if isOn {
                    self.selectedOptions.insert(.recording)
                } else {
                    self.selectedOptions.remove(.recording)
                }
                self.updateActionButton()
            }
            options.append(shareRecording)
        }
        
        options.forEach { addSubview($0) }
        
        actionButton.color = .clear
        actionButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.action?(self.selectedOptions)
        }
        addSubview(actionButton)
        
    }
    
    private func updateActionButton() {
        actionButton.isEnabled = selectedOptions.count > 0
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        let headerHeight: CGFloat = PopupSecondaryViewHeader.height
        let optionHeight: CGFloat = 52
        let totalOptionHeight = optionHeight * CGFloat(options.count)
        return headerHeight + 10 + totalOptionHeight + PopupActionButtonView.height
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        header.frame = CGRect(x: 0, y: 0, width: bounds.width, height: PopupSecondaryViewHeader.height)
        
        let optionHeight: CGFloat = 52
        
        for (i, option) in options.enumerated() {
            option.frame = CGRect(
                x: 0, y: header.frame.maxY + 8 + CGFloat(i)*optionHeight,
                width: bounds.width, height: optionHeight)
        }
        
        actionButton.frame = CGRect(
            x: 0,
            y: bounds.maxY - PopupActionButtonView.height - safeAreaInsets.bottom,
            width: bounds.width,
            height: PopupActionButtonView.height)
        
    }
}

fileprivate class ShareOption: UIView {
    
    public let optionType: SessionOptionsPopupController.ShareType
    
    private let label = UILabel()
    private let button = UISwitch()
    
    public var action: ((Bool)->())?
    
    init(_ optionType: SessionOptionsPopupController.ShareType) {
        self.optionType = optionType
        
        super.init(frame: .zero)
        
        label.text = optionType.string
        label.textColor = Colors.text
        label.font = Fonts.regular.withSize(17)
        addSubview(label)
        
        button.isOn = true
        button.onTintColor = Colors.green
        button.addTarget(self, action: #selector(handleButton), for: .valueChanged)
        addSubview(button)
        
    }
    
    @objc func handleButton() {
        self.action?(button.isOn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.sizeToFit()
        button.center = CGPoint(
            x: bounds.maxX - Constants.smallMargin - button.bounds.width/2,
            y: bounds.midY)
        
        label.frame = CGRect(
            from: CGPoint(x: Constants.margin, y: 0),
            to: CGPoint(x: button.frame.minX - 14, y: bounds.maxY)
        )
        
    }
}
