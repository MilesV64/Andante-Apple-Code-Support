//
//  NewFolderCenterAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 7/18/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class NewFolderCenterAlertController: CancelConfirmCenterPickerViewController, UITextFieldDelegate {
    
    public let labelGroup = LabelGroup()
    public let textField = UITextField()
    
    override func viewDidLoad() {
        self.confirmText = "Save"

        super.viewDidLoad()
                
        self.contentSize.height = 200
        self.contentSize.width = 310
        
        labelGroup.textAlignment = .center
        
        labelGroup.titleLabel.text = "New Folder"
        labelGroup.titleLabel.textColor = Colors.text
        labelGroup.titleLabel.font = Fonts.semibold.withSize(16)
        
        labelGroup.detailLabel.text = "Enter a name for this folder."
        labelGroup.detailLabel.textColor = Colors.lightText
        labelGroup.detailLabel.font = Fonts.regular.withSize(15)
        
        labelGroup.padding = 3
        
        self.contentView.addSubview(labelGroup)

        let iconView = IconView()
        iconView.icon = UIImage(name: "folder.fill", pointSize: 17, weight: .medium)
        iconView.iconColor = Colors.lightText
        iconView.iconInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 10)
        textField.leftView = iconView
        textField.leftViewMode = .always
        
        textField.textColor = Colors.text
        textField.font = Fonts.regular.withSize(16)
        textField.attributedPlaceholder = NSAttributedString(string: "Name", attributes: [
            .foregroundColor : Colors.extraLightText
        ])
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        
        textField.backgroundColor = Colors.lightColor
        textField.tintColor = Colors.orange
        
        textField.delegate = self
        
        textField.addTarget(self, action: #selector(didChangeText), for: .editingChanged)
        
        self.contentView.addSubview(textField)
        
        self.isConfirmEnabled = false
    }
    
    @objc func didChangeText() {
        self.isConfirmEnabled = textField.hasText
    }
    
    override func viewDidLayoutSubviews() {
            
        super.viewDidLayoutSubviews()
        
        let height = labelGroup.sizeThatFits(self.contentView.bounds.size).height
        labelGroup.frame = CGRect(
            x: 0, y: 24,
            width: contentView.bounds.width,
            height: height)
        
        textField.frame = CGRect(
            x: Constants.margin,
            y: labelGroup.frame.maxY + 16,
            width: contentView.bounds.width - Constants.margin*2,
            height: 46)
        
        textField.roundCorners(10)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        textField.becomeFirstResponder()
    }
    
    override func close(withCloseAction: Bool = false) {
        textField.resignFirstResponder()
        super.close(withCloseAction: withCloseAction)
    }
    
}

class RenameFolderAlertController: NewFolderCenterAlertController {
    
    private var initialTitle: String = "Name"
    
    convenience init(_ folder: CDJournalFolder) {
        self.init(animateWithKeyboard: true)
        initialTitle = folder.title ?? "Name"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.contentSize.height = 180
        
        labelGroup.titleLabel.text = "Rename Folder"
        labelGroup.detailLabel.text = nil
        
        textField.text = initialTitle
        
        self.isConfirmEnabled = true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectedTextRange = textField.textRange(from: textField.beginningOfDocument, to: textField.endOfDocument)
    }
    
}
