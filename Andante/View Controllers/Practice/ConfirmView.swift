//
//  ConfirmView.swift
//  Andante
//
//  Created by Miles Vinson on 9/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//


import UIKit

class ScrollView: CancelTouchScrollView {
    override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        //intentionally empty to cancel uitextview auto scrolling the parent scroll view
    }
}

class ConfirmView: UIView, UITextViewDelegate, TransitionDelegate {
    
    private let topView = UIView()
    private let backButton = UIButton(type: .system)
        
    private let titleLabel = UITextField()
    private let titleSeparator = Separator(position: .bottom)
    private let notesLabel = UILabel()
    
    private let scrollView = ScrollView()
    private let textView = SessionNotesTextView()
    
    private let startCell = ConfirmStatCell()
    private let practicedCell = ConfirmStatCell()
    private let moodCell = MFCell()
    private let focusCell = MFCell()
    
    private let saveButton = BottomActionButton(title: "Save Session")
    
    public var session: SessionModel!
    
    public var saveAction: (()->Void)?
    
    public var cancelHandler: (()->Void)?
    
    public var premiumHandler: (()->Void)?
    
    init(_ session: SessionModel) {
        self.session = session
        
        super.init(frame: .zero)
                
        self.backgroundColor = Colors.foregroundColor
        
        scrollView.backgroundColor = Colors.foregroundColor
        scrollView.delaysContentTouches = false
        scrollView.canCancelContentTouches = true
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        self.addSubview(scrollView)
        
        titleLabel.tintColor = Colors.orange
        titleLabel.font = Fonts.bold.withSize(30)
        titleLabel.attributedPlaceholder = NSAttributedString(string: User.getActiveProfile()?.defaultSessionTitle ?? "Practice", attributes: [
            .foregroundColor : Colors.extraLightText
        ])
        titleLabel.textColor = Colors.text
        titleLabel.autocapitalizationType = .words
        titleLabel.returnKeyType = .done
        titleLabel.delegate = self
        scrollView.addSubview(titleLabel)
        
        titleSeparator.insetToMargins()
        scrollView.addSubview(titleSeparator)
        
        notesLabel.textColor = Colors.text
        notesLabel.font = Fonts.semibold.withSize(19)
        notesLabel.text = "Session notes"
        scrollView.addSubview(notesLabel)
        
        textView.font = Fonts.regular.withSize(17)
        textView.textColor = Colors.text.withAlphaComponent(0.9)
        textView.backgroundColor = .clear
        textView.placeholder = "Tap to add a note for this session"
        textView.text = session.notes ?? ""
        textView.isScrollEnabled = false
        textView.delegate = self
        scrollView.addSubview(textView)
        
        textView.shouldStartEditingHandler = {
            [weak self] in
            guard let self = self else { return false }
            
            if Settings.isPremium {
                return true
            }
            else {
                self.premiumHandler?()
                return false
            }
        }
        
        let toolbar = DoneToolbar()
        toolbar.doneHandler = {
            [weak self] in
            self?.textView.resignFirstResponder()
        }
        textView.inputAccessoryView = toolbar
        textView.delegate = self
                
        setStats()
        
        saveButton.action = {
            [weak self] in
            guard let self = self else { return }
            if self.titleLabel.hasText {
                self.session.title = self.titleLabel.text ??  User.getActiveProfile()?.defaultSessionTitle ?? "Practice"
            }
            self.textView.delegate = nil
            self.saveAction?()
        }
        self.addSubview(saveButton)
        
        backButton.setImage(UIImage(name: "chevron.left", pointSize: 16, weight: .bold), for: .normal)
        backButton.tintColor = Colors.text
        backButton.contentHorizontalAlignment = .left
        backButton.contentEdgeInsets.left = Constants.smallMargin
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        scrollView.addSubview(backButton)
        scrollView.delegate = self
        
        topView.backgroundColor = Colors.foregroundColor.withAlphaComponent(0.94)
        self.addSubview(topView)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
    }
    
    enum BackButtonType {
        case back, cancel
    }
    
    func setBackButtonType(_ type: BackButtonType) {
        if type == .cancel {
            backButton.setImage(nil, for: .normal)
            backButton.setTitle("Cancel", for: .normal)
            backButton.titleLabel?.font = Fonts.regular.withSize(17)
            backButton.tintColor = Colors.orange
            backButton.contentHorizontalAlignment = .left
            backButton.contentEdgeInsets.left = Constants.smallMargin
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateNotes() {
        textView.text = session.notes ?? ""
    }
    
    public func updateCells() {
        startCell.detailLabel.text = session.start.string(timeStyle: .short)
        practicedCell.detailLabel.text = "\(session.practiceTime) min"
    }
    
    @objc func didTapBack() {
        self.viewWillClose()
        self.cancelHandler?()
    }
    
    
    func viewWillOpen() {
        
    }
    
    func viewWillClose() {
        titleLabel.resignFirstResponder()
        textView.resignFirstResponder()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = self.convert(keyboardScreenEndFrame, from: self.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset.bottom = 0
        } else {
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentInset.bottom = max(0, keyboardViewEndFrame.height - self.saveButton.bounds.height)
                
                if self.titleLabel.isFirstResponder {
                    self.scrollView.setContentOffset(
                        CGPoint(x: 0, y: -self.scrollView.adjustedContentInset.top),
                        animated: false)
                }
                
            }
            
        }
                
        scrollView.scrollIndicatorInsets = scrollView.contentInset

    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.isFirstResponder {
            scrollTextView()
        }
    }
    
    func scrollTextView() {
        layoutTextView()
        
        let selectionFrame = textView.convert(textView.currentSelectionRect, to: scrollView)
        let maxOffset = scrollView.contentSize.height - self.scrollView.bounds.height + scrollView.contentInset.bottom
        
        UIView.animateWithCurve(duration: 0.35, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.scrollView.setContentOffset(
                CGPoint(
                    x: 0,
                    y: max(
                        self.scrollView.contentOffset.y,
                        min(maxOffset,
                            selectionFrame.origin.y - self.safeAreaInsets.top - self.bounds.height*0.15)
                    )
                ),
                animated: false)
        }, completion: nil)

        
    }
    
    func textViewDidChange(_ textView: UITextView) {
        session.notes = textView.text
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        layoutTextView()
        scrollTextView()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        layoutTextView()
    }
    
    private func setStats() {
        
        startCell.title = "Start"
        startCell.stat = .time
        startCell.detailLabel.text = session.start.string(timeStyle: .short)
        scrollView.addSubview(startCell)
                
        practicedCell.title = "Duration"
        practicedCell.stat = .practice
        practicedCell.detailLabel.text = "\(session.practiceTime) min"
        scrollView.addSubview(practicedCell)

        moodCell.title = "Mood"
        moodCell.stat = .mood
        moodCell.setType(.mood)
        scrollView.addSubview(moodCell)
        
        focusCell.title = "Focus"
        focusCell.stat = .focus
        focusCell.setType(.focus)
        scrollView.addSubview(focusCell)
        
        self.moodCell.valueChangeHandler = {
            [weak self] value in
            guard let self = self else { return }
            self.session.mood = value
        }
        
        self.focusCell.valueChangeHandler = {
            [weak self] value in
            guard let self = self else { return }
            self.session.focus = value
        }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let extraMargin: CGFloat = responsiveMargin - Constants.margin
                
        saveButton.sizeToFit()
        saveButton.inset = UIEdgeInsets(extraMargin > 0 ? Constants.margin : 0)
        saveButton.bounds.size.width = bounds.width - extraMargin*2
        saveButton.frame.origin = CGPoint(
            x: extraMargin, y: self.bounds.maxY - saveButton.bounds.height)
        
        scrollView.frame = self.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: saveButton.bounds.height, right: 0))
        
        topView.frame = CGRect(
            x: 0, y: 0, width: self.bounds.width,
            height: self.safeAreaInsets.top)
        
        if backButton.image(for: .normal) == nil {
            backButton.frame = CGRect(
                x: extraMargin, y: 6,
                width: 110, height: 48)
        }
        else {
            backButton.frame = CGRect(
                x: 0, y: 0,
                width: 60, height: 44)
        }
        
        
        layoutTitleLabel()
        
        titleSeparator.inset = UIEdgeInsets(responsiveMargin)
        titleSeparator.frame = CGRect(
            x: 0, y: titleLabel.frame.maxY,
            width: self.bounds.width,
            height: 10)
        
        let statHeight: CGFloat = 72
        let stats = [startCell, practicedCell, moodCell, focusCell]
        for (i, cell) in stats.enumerated() {
            cell.inset = UIEdgeInsets(responsiveMargin)
            cell.frame = CGRect(
                x: 0, y: titleSeparator.frame.maxY + CGFloat(i)*statHeight,
                width: scrollView.bounds.width,
                height: statHeight)
        }
        
        notesLabel.sizeToFit()
        notesLabel.frame.origin = CGPoint(
            x: responsiveMargin,
            y: stats[3].frame.maxY + 14)
        
        layoutTextView()
        
    }
    
    private func layoutTextView() {
        textView.textContainerInset = UIEdgeInsets(top: 0, left: responsiveMargin - 5, bottom: 50, right: responsiveMargin - 5)
        let textHeight = textView.sizeThatFits(self.bounds.size).height
        let height = textView.isFirstResponder ? max(textHeight, self.bounds.height*0.4) : textHeight
        
        textView.frame = CGRect(
            x: 0, y: notesLabel.frame.maxY + 4,
            width: scrollView.bounds.width,
            height: height)
        
        scrollView.contentSize = CGSize(
            width: self.bounds.width,
            height: textView.frame.maxY)
    }
    
    private func layoutTitleLabel() {
        titleLabel.sizeToFit()
        
        let titleWidth = titleLabel.isFirstResponder ? self.bounds.width - responsiveMargin*2 : min(titleLabel.bounds.width, self.bounds.width - responsiveMargin*2)
        
        titleLabel.frame = CGRect(x: responsiveMargin, y: 70,
                                  width: titleWidth,
                                  height: titleLabel.bounds.size.height)
        
                
    }
    
}

//MARK: Textfield delegate
extension ConfirmView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        layoutTitleLabel()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        layoutTitleLabel()
        
    }
    
}

class ConfirmStatCell: SessionStatCell {
    
    public let detailLabel = UILabel()
    
    override init() {
        super.init()
        
        detailLabel.textColor = Colors.text
        detailLabel.font = Fonts.semibold.withSize(17)
        detailLabel.textAlignment = .right
        self.addSubview(detailLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        detailLabel.frame = self.bounds.insetBy(dx: responsiveMargin, dy: 0)
        
    }
}
