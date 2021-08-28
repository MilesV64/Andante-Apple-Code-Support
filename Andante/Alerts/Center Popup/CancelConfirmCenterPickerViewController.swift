//
//  CancelConfirmCenterPickerViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/1/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CancelConfirmCenterPickerViewController: CenterPickerViewController {
    
    private let cancelButton = UIButton(type: .system)
    private let confirmButton = UIButton(type: .system)
    public let buttonsView = Separator()
    private let midSeparator = UIView()
    
    public var confirmText: String?
    
    public var isConfirmEnabled: Bool {
        get {
            return confirmButton.isEnabled
        }
        set {
            confirmButton.isEnabled = newValue
        }
    }
    
    public var confirmAction: (()->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        buttonsView.position = .top
        self.contentView.addSubview(buttonsView)
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(Colors.orange, for: .normal)
        cancelButton.titleLabel?.font = Fonts.regular.withSize(17)
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        buttonsView.addSubview(cancelButton)
        
        confirmButton.setTitle(confirmText ?? "Confirm", for: .normal)
        confirmButton.setTitleColor(Colors.orange, for: .normal)
        confirmButton.setTitleColor(Colors.text.withAlphaComponent(0.2), for: .disabled)
        confirmButton.titleLabel?.font = Fonts.semibold.withSize(17)
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        buttonsView.addSubview(confirmButton)
        
        buttonsView.addSubview(midSeparator)
        midSeparator.backgroundColor = Colors.separatorColor
        
        
    }
    
    @objc func didTapCancel() {
        close()
    }
    
    @objc func didTapConfirm() {
        confirmAction?()
        close()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        buttonsView.frame = CGRect(
            x: 0, y: contentView.bounds.maxY - 56,
            width: contentView.bounds.width,
            height: 56)
        
        cancelButton.frame = CGRect(
            x: 0, y: 0,
            width: contentView.bounds.width/2,
            height: buttonsView.bounds.height)
        
        confirmButton.frame = CGRect(
            x: contentView.bounds.midX, y: 0,
            width: contentView.bounds.width/2,
            height: buttonsView.bounds.height)
        
        midSeparator.frame = CGRect(
            x: buttonsView.bounds.midX,
            y: 0, width: 1/UIScreen.main.scale,
            height: buttonsView.bounds.height)
        
    }
    
}
