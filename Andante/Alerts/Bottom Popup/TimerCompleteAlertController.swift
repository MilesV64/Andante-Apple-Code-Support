//
//  TimerCompleteAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 8/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TimerCompleteAlertController: PickerAlertController {
    
    private let label = TitleBodyGroup()
    private let repeatButton = PushButton()
    private let doneButton = UIButton(type: .system)
    
    public var repeatAction: (()->Void)? {
        didSet {
            repeatButton.action = {
                [weak self] in
                guard let self = self else { return }
                self.close()
                self.repeatAction?()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.titleLabel.text = "Practice Timer"
        label.titleLabel.textColor = PracticeColors.text
        label.titleLabel.font = Fonts.bold.withSize(24)
        
        label.textView.text = "Your timer is done!"
        label.textView.textColor = PracticeColors.lightText
        label.textView.font = Fonts.regular.withSize(17)
        label.textView.textContainerInset.left = 40
        label.textView.textContainerInset.right = 40
        
        label.textAlignment = .center
        contentView.addSubview(label)
        
        repeatButton.backgroundColor = Colors.orange
        repeatButton.buttonView.setTitle("Repeat", color: Colors.white, font: Fonts.semibold.withSize(16))
        repeatButton.image = UIImage(name: "repeat", pointSize: 16, weight: .semibold)
        repeatButton.imageColor = Colors.white
        repeatButton.buttonView.titleEdgeInsets.left = 14
        repeatButton.buttonView.contentEdgeInsets.right = 6
        repeatButton.buttonView.adjustsImageWhenHighlighted = false
        repeatButton.buttonView.setShadow(radius: 6, yOffset: 3, opacity: 0.04)
        contentView.addSubview(repeatButton)
        
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(PracticeColors.text, for: .normal)
        doneButton.titleLabel?.font = Fonts.medium.withSize(17)
        doneButton.addTarget(self, action: #selector(didTapDone), for: .touchUpInside)
        contentView.addSubview(doneButton)
        
    }
    
    @objc func didTapDone() {
        self.close()
    }
    
    override func viewDidLayoutSubviews() {
        
        let labelSize = label.sizeThatFits(self.view.bounds.size).height
        let buttonSize: CGFloat = 50
        
        self.contentHeight = labelSize + buttonSize*2 + 140
        
        super.viewDidLayoutSubviews()

        label.frame = CGRect(
            x: 0, y: 50,
            width: contentView.bounds.width,
            height: labelSize)
        
        let buttonWidth: CGFloat = 150
        
        repeatButton.frame = CGRect(
            x: contentView.bounds.midX - buttonWidth/2,
            y: label.frame.maxY + 56,
            width: buttonWidth, height: buttonSize)
        repeatButton.cornerRadius = buttonSize/2
        
        doneButton.frame = CGRect(
            x: contentView.bounds.midX - buttonWidth/2,
            y: repeatButton.frame.maxY + 12,
            width: buttonWidth, height: buttonSize)
        
        
        
    }
    
}
