//
//  CreateProfileViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CreateProfileViewController: UIViewController, UITextFieldDelegate {
    
    private let headerView = ModalViewHeader(title: "")
    private let scrollView = CancelTouchScrollView()
    
    private let iconPicker = IconPickerView()
    
    private let iconView = IconView()
    
    private let textField = UITextField()
    
    private var selectedIconName = ""
    
    public var handler: ((CDProfile)->Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.foregroundColor
        
        headerView.showsSeparator = false
        headerView.showsCancelButton = true
        headerView.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        headerView.doneButtonText = "Save"
        headerView.doneButtonAction = {
            [weak self] in
            guard let self = self else { return }
            let profile = CDProfile(context: DataManager.context)
            profile.name = self.textField.text ?? "Profile"
            profile.iconName = self.selectedIconName
            CDProfile.saveProfile(profile)
            User.setActiveProfile(profile)
            User.reloadData()
            
            DataManager.saveNewObject(profile)
            
            self.handler?(profile)
            self.dismiss(animated: true, completion: nil)
        }
        headerView.setDoneButtonEnabled(false)
        headerView.showsDoneButton = true
        headerView.showsHandle = false
        self.view.addSubview(headerView)
        
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        self.view.addSubview(scrollView)
        
        iconView.backgroundColor = Colors.lightColor
        self.scrollView.addSubview(iconView)
        
        textField.textColor = Colors.text
        textField.font = Fonts.medium.withSize(19)
        textField.textAlignment = .center
        textField.attributedPlaceholder = NSAttributedString(string: "Profile Name", attributes: [
            .foregroundColor : Colors.extraLightText
        ])
        textField.layer.borderColor = Colors.lightColor.cgColor
        textField.layer.borderWidth = 2
        textField.roundCorners(14)
        textField.setPadding(Constants.margin)
        textField.returnKeyType = .done
        textField.addTarget(self, action: #selector(textDidUpdate), for: .editingChanged)
        textField.delegate = self
        textField.autocapitalizationType = .words
        self.scrollView.addSubview(textField)
        
        iconPicker.selectionAction = {
            [weak self] iconName in
            guard let self = self else { return }
            self.iconView.icon = UIImage(named: iconName)
            self.selectedIconName = iconName
            self.updateSaveState()
        }
        self.scrollView.addSubview(iconPicker)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    @objc func textDidUpdate() {
        updateSaveState()
    }
    
    private func updateSaveState() {
        headerView.setDoneButtonEnabled(selectedIconName != "" && textField.hasText)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        textField.layer.borderColor = Colors.lightColor.cgColor
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        UIView.animate(withDuration: 0.25) {
            let height = self.scrollView.frame.height - self.scrollView.contentInset.top - (keyboardViewEndFrame.height)
            let scrollTopY = self.textField.frame.maxY - height
            let offset = -self.scrollView.contentInset.top + scrollTopY
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: max(self.scrollView.contentOffset.y, offset)), animated: false)
            
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let (width, margin) = view.constrainedWidth
        
        headerView.frame = CGRect(
            x: 0, y: 0, width: self.view.bounds.width, height: 50)
        
        scrollView.frame = self.view.bounds.inset(by: UIEdgeInsets(top: headerView.frame.maxY, left: 0, bottom: 0, right: 0))
        
        let spacing: CGFloat = 38
        let iconBGSize = width * 0.48
        iconView.frame = CGRect(
            x: self.view.bounds.midX - iconBGSize/2,
            y: spacing,
            width: iconBGSize,
            height: iconBGSize)
        iconView.iconInsets = UIEdgeInsets(floor(iconBGSize*0.16))
        iconView.roundCorners(prefersContinuous: false)
                
        textField.frame = CGRect(
            x: margin + 6, y: iconView.frame.maxY + spacing,
            width: self.view.bounds.width - margin*2 - 12,
            height: 52)
        
        let size = iconPicker.sizeThatFits(
            CGSize(width: view.bounds.width - margin*2, height: .infinity))
        
        iconPicker.frame = CGRect(
            x: margin, y: textField.frame.maxY + spacing,
            width: size.width, height: size.height)
        
        scrollView.contentSize.height = iconPicker.frame.maxY + 40
        
    }
    
}

extension UITextField {
    func setLeftPadding(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    func setRightPadding(_ amount:CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    func setPadding(_ amount: CGFloat) {
        setLeftPadding(amount)
        setRightPadding(amount)
    }
}
