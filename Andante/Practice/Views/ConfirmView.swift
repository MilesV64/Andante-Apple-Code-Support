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

class ConfirmView: UIView, UITextViewDelegate, TransitionDelegate, PickerViewDelegate {
    
    public weak var viewControllerForPresenting: UIViewController?
    
    private let topView = Separator(position: .bottom)
    private let backButton = Button("chevron.left")
        
    private let titleLabel = UITextField()
    private let titleSeparator = Separator(position: .bottom)
    private let notesLabel = UILabel()
    
    private let scrollView = ScrollView()
    private let textView = SessionNotesTextView()
    
    private let profileCell = ChooseProfileCell()
    
    private let timeCell = SessionStatCell()
    private let timePicker = TimePickerView()
    
    private let practicedCell = SessionStatCell()
    private let practicePicker = MinutePickerView(.prominent)
    
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
            self.session.practiceTime = self.practicePicker.value
            self.session.start = self.timePicker.date
            self.session.profile = self.profileCell.profile
            self.saveAction?()
        }
        self.addSubview(saveButton)
        
        
        topView.backgroundColor = Colors.foregroundColor
        topView.alpha = 0
        self.addSubview(topView)
        
        backButton.contentHorizontalAlignment = .left
        backButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.didTapBack()
        }
        self.addSubview(backButton)
        
        scrollView.delegate = self
        
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
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateNotes() {
        textView.text = session.notes
    }
    
    public func updateCells() {
        timePicker.date = session.start
        practicePicker.value = session.practiceTime
        
        if User.getActiveProfile() == nil, profileCell.profile == nil {
            profileCell.profile = CDProfile.getAllProfiles().first
        }
        
        profileCell.isHidden = User.getActiveProfile() != nil
        self.setNeedsLayout()
        
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
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        topView.alpha = (offset - 20)/20
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
        
        profileCell.profile = CDProfile.getAllProfiles().first
        profileCell.action = { [weak self] in
            guard let self = self else { return }
            self.profileCell.highlight()
            let popup = ProfilesPopupViewController()
            popup.selectedProfile = self.profileCell.profile
            popup.useNewProfileButton = false
            popup.allowsAllProfiles = false
            popup.action = { profile in
                self.profileCell.profile = profile
                
            }
            popup.willDismiss = {
                self.profileCell.endHighlight()
            }
            self.viewControllerForPresenting?.presentPopupViewController(popup)
        }
        profileCell.isHidden = User.getActiveProfile() != nil
        self.scrollView.addSubview(profileCell)
        
        timeCell.title = "Start"
        timeCell.stat = .time
        scrollView.addSubview(timeCell)
        
        timePicker.delegate = self
        scrollView.addSubview(timePicker)
        
        practicedCell.title = "Duration"
        practicedCell.stat = .practice
        scrollView.addSubview(practicedCell)

        practicePicker.value = 30
        practicePicker.useSuggested = true
        practicePicker.delegate = self
        scrollView.addSubview(practicePicker)

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
    
    func pickerViewWillBeginEditing(_ view: UIView) {
        
        if view === practicePicker {
            let date = Calendar.current.date(bySetting: .second, value: 0, of: Date()) ?? Date()
            let interval = Int(date.timeIntervalSince(timePicker.date)/60) - 1
            if interval > 0 && interval < 3*60 {
                practicePicker.useSuggested = true
            }
            else {
                practicePicker.useSuggested = false
            }
        }
    }
    
    func pickerViewDidEndEditing(_ view: UIView) {
        
    }
    
    func pickerViewDidSelectSuggested(_ view: UIView) {
        let date = Calendar.current.date(bySetting: .second, value: 0, of: Date()) ?? Date()
        practicePicker.value = Int(date.timeIntervalSince(timePicker.date)/60) - 1
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        practicePicker.resignFirstResponder()
        timePicker.resignFirstResponder()
        titleLabel.resignFirstResponder()
    }
    
    
    // MARK: - LayoutSubviews
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let extraMargin: CGFloat = responsiveMargin - Constants.margin
                
        saveButton.sizeToFit()
        saveButton.inset = UIEdgeInsets(extraMargin > 0 ? Constants.margin : 0)
        saveButton.bounds.size.width = bounds.width - extraMargin*2
        saveButton.frame.origin = CGPoint(
            x: extraMargin, y: self.bounds.maxY - saveButton.bounds.height)
        
        topView.frame = CGRect(
            x: 0, y: 0,
            width: self.bounds.width,
            height: 44 + self.safeAreaInsets.top)
        
        topView.inset.left = responsiveMargin
        topView.inset.right = responsiveMargin
        
        if backButton.image(for: .normal) == nil {
            backButton.frame = CGRect(
                x: extraMargin, y: 6,
                width: 110, height: 48)
        }
        else {
            backButton.contentEdgeInsets.left = responsiveMargin - 1
            backButton.frame = CGRect(
                x: 0, y: self.safeAreaInsets.top,
                width: responsiveMargin + 56, height: 44)
        }
        
        
        scrollView.frame = self.bounds.inset(by: UIEdgeInsets(top: topView.frame.maxY, left: 0, bottom: saveButton.bounds.height, right: 0))
        
        layoutTitleLabel()
        
        titleSeparator.inset = UIEdgeInsets(responsiveMargin)
        titleSeparator.frame = CGRect(
            x: 0, y: titleLabel.frame.maxY,
            width: self.bounds.width,
            height: 10)
        
        let statHeight: CGFloat = 72
        var stats: [Separator] = [timeCell, practicedCell, moodCell, focusCell]
        if self.profileCell.isHidden == false {
            stats.insert(profileCell, at: 0)
        }
        for (i, cell) in stats.enumerated() {
            cell.inset = UIEdgeInsets(responsiveMargin)
            cell.frame = CGRect(
                x: 0, y: titleSeparator.frame.maxY + CGFloat(i)*statHeight,
                width: scrollView.bounds.width,
                height: statHeight)
        }
        
        let margin = responsiveSmallMargin
        
        let practiceFrame = practicedCell.frame
        
        practicePicker.sizeToFit()
        practicePicker.frame.origin = CGPoint(
            x: practiceFrame.maxX - margin - practicePicker.bounds.width,
            y: practiceFrame.midY - practicePicker.bounds.height/2)
        
        let timeFrame = timeCell.frame
        
        timePicker.sizeToFit()
        timePicker.frame.origin = CGPoint(
            x: timeFrame.maxX - margin - timePicker.bounds.width,
            y: timeFrame.midY - timePicker.bounds.height/2)
        
        notesLabel.sizeToFit()
        notesLabel.frame.origin = CGPoint(
            x: responsiveMargin,
            y: focusCell.frame.maxY + 14)
        
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
        
        titleLabel.frame = CGRect(x: responsiveMargin, y: 36,
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
