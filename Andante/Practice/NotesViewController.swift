//
//  NotesViewController.swift
//  Andante
//
//  Created by Miles Vinson on 6/7/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class NotesViewController: UIViewController {
    
    private let header = ModalViewHeader()
    private let notesView = NotesControllerNotesView()
    
    public var notes: String = "" {
        didSet {
            notesView.setNotes(notes)
        }
    }
    
    public var notesAction: ((String)->Void)? {
        didSet {
            notesView.notesAction = notesAction
        }
    }
    
    public var closeHandler: (()->Void)?
    
    override func viewDidLoad() {
        self.view.backgroundColor = Colors.foregroundColor
        
        header.showsSeparator = false
        header.showsHandle = true
        self.view.addSubview(header)
        
        header.doneButtonAction = {
            [weak self] in
            guard let self = self else { return }
            
            self.notesView.textView.resignFirstResponder()
        }
        
        notesView.editingHandler = {
            [weak self] isEditing in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.25) {
                self.header.showsDoneButton = isEditing
            }
            
        }
        
        self.view.addSubview(notesView)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.closeHandler?()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.notesView.textView.resignFirstResponder()
    }
    
    private var hasAppeared = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if hasAppeared {
            return
        }
        
        hasAppeared = true
        
        DispatchQueue.main.async {
            [weak self] in
            guard let self = self else { return }
            
            if self.notes == "" {
                self.notesView.textView.becomeFirstResponder()
            }
        }
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        header.frame = CGRect(
            x: 0, y: 0, width: self.view.bounds.width, height: 50)
        
        notesView.frame = CGRect(
            from: CGPoint(x: 0, y: header.bounds.maxY),
            to: CGPoint(x: self.view.bounds.maxX, y: self.view.bounds.maxY))
        
    }
    
}

class NotesControllerNotesView: UIView, UITextViewDelegate {
    
    private var infoView: PushButton?
    private var infoLabel: UILabel?
        
    private let titleLabel = UILabel()
    public let textView = PlaceHolderTextView()
    
    private var keyboardHeight: CGFloat = 0
    
    public func setNotes(_ notes: String) {
        textView.text = notes
    }
    
    public var editingHandler: ((_ isEditing: Bool)->Void)?
    
    public var notesAction: ((String)->Void)?
    
    init() {
        super.init(frame: .zero)
        
        textView.backgroundColor = .clear
        textView.textColor = Colors.text
        textView.font = Fonts.regular.withSize(18)
        textView.returnKeyType = .default
        textView.textContainerInset.left = Constants
            .margin - 4
        textView.textContainerInset.right = Constants.margin - 4
        textView.textContainerInset.bottom = 40
        textView.textContainerInset.top = 32
        textView.tintColor = Colors.orange
        textView.keyboardDismissMode = .interactive
        
        textView.placeholder = "Type something..."
        textView.delegate = self
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        self.addSubview(textView)
        
        titleLabel.font = Fonts.bold.withSize(19)
        titleLabel.textColor = Colors.text
        titleLabel.text = "Session notes"
        titleLabel.isUserInteractionEnabled = false
        textView.addSubview(titleLabel)
        
        
        if ToolTips.didShowNotesTooltip == false {
            infoView = PushButton()
            infoView?.backgroundColor = Colors.lightColor
            infoView?.cornerRadius = 10
            infoView?.action = {
                [weak self] in
                guard let self = self else { return }
                ToolTips.didShowNotesTooltip = true
                UIView.animate(withDuration: 0.25, animations: {
                    self.infoView?.alpha = 0
                }, completion: {
                    [weak self] complete in
                    guard let self = self else { return }
                    self.infoView?.removeFromSuperview()
                    self.infoView = nil
                })
            }

            infoLabel = UILabel()
            infoLabel?.numberOfLines = 2
            infoLabel?.text = "Notes you take here are automatically\nsaved to this session."
            infoLabel?.textColor = Colors.text.withAlphaComponent(0.85)
            infoLabel?.font = Fonts.medium.withSize(16)
            infoView?.addSubview(infoLabel!)
            
            self.addSubview(infoView!)
        }

    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        editingHandler?(true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        editingHandler?(false)
    }
    
    var counter = 0
    func textViewDidChange(_ textView: UITextView) {
        
        notesAction?(textView.text)
        
        if infoLabel == nil { return }
        
        if counter < 3 {
            counter += 1
        }
        else if counter == 3 {
            UIView.animate(withDuration: 0.25, animations: {
                self.infoView?.alpha = 0
            }, completion: {
                [weak self] complete in
                guard let self = self else { return }
                self.infoView?.removeFromSuperview()
                self.infoView = nil
            })
            ToolTips.didShowNotesTooltip = true
        }
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let window = UIApplication.shared.windows.first!
        let keyboardScreenEndFrame = window.convert(keyboardValue.cgRectValue, to: self)

        let effectiveHeight = max(0, self.bounds.height - keyboardScreenEndFrame.minY)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            textView.contentInset.bottom = 0
            self.keyboardHeight = 0
        } else {
            UIView.animate(withDuration: 0.25) {
                self.textView.contentInset.bottom = effectiveHeight - self.safeAreaInsets.bottom
            }
            self.keyboardHeight = effectiveHeight
        }
        
        UIView.animate(withDuration: 0.25) {
            self.layoutInfoView()
        }
        
        textView.scrollIndicatorInsets = textView.contentInset

        let selectedRange = textView.selectedRange
        textView.scrollRangeToVisible(selectedRange)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    private func layoutInfoView() {
        guard let infoLabel = infoLabel, let infoView = infoView else { return }
        
        infoLabel.font = isSmallScreen() ? Fonts.medium.withSize(15) : Fonts.medium.withSize(16)
        
        infoLabel.sizeToFit()
        infoView.bounds.size.height = infoLabel.bounds.height + 32
        
        if keyboardHeight == 0 {
            infoView.contextualFrame = CGRect(
                x: Constants.smallMargin,
                y: self.bounds.maxY - self.safeAreaInsets.bottom - infoView.bounds.size.height - 32,
                width: self.bounds.width - Constants.smallMargin*2,
                height: infoView.bounds.size.height)
        }
        else {
            infoView.contextualFrame = CGRect(
                x: Constants.smallMargin,
                y: self.bounds.maxY - keyboardHeight - infoView.bounds.size.height - 16,
                width: self.bounds.width - Constants.smallMargin*2,
                height: infoView.bounds.size.height)
        }
        
        infoLabel.frame.origin = CGPoint(x: Constants.margin, y: 16)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        textView.frame = self.bounds
        
        titleLabel.sizeToFit()
        titleLabel.frame.origin = CGPoint(x: Constants.margin, y: 5)
        
        layoutInfoView()
        
        
    }
}

