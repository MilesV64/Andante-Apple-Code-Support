//
//  ManualSessionViewController.swift
//  Andante
//
//  Created by Miles Vinson on 6/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class SessionNotesTextView: PlaceHolderTextView {
    
    public var shouldStartEditingHandler: (()->Bool)?
    
    override func touchesShouldCancel(in view: UIView) -> Bool {
        return true
    }
    
    override var canBecomeFirstResponder: Bool {
        return shouldStartEditingHandler?() ?? true
    }
    
}

extension UITextView {
    public var currentSelectionRect: CGRect {
        if let cursorPosition = self.selectedTextRange?.start {
            return self.caretRect(for: cursorPosition)
        }
        return .zero
    }
}

class ManualSessionViewController: UIViewController, UITextViewDelegate, CalendarPickerDelegate, PickerViewDelegate {
      
    public let titleLabel = UITextField()
    private let titleSep = Separator()
    private let notesLabel = UILabel()
    
    private let scrollView = ScrollView()
    public let textView = SessionNotesTextView()
    private let contentView = UIView()
    
    private let topView = UIView()
    private let cancelButton = UIButton(type: .system)
    public let saveButton = UIButton(type: .system)
    
    public let calendarPicker = CalendarPickerView()
    private let timeCell = SessionStatCell()
    public let timePicker = TimePickerView()
    private let practicedCell = SessionStatCell()
    public let practicePicker = MinutePickerView(.prominent)
    public let moodCell = MFCell()
    public let focusCell = MFCell()
    
    public let profileCell = ChooseProfileCell()
    
    private var startTime = Date()
    
    public var didEdit = false
    
    override func loadView() {
        let view = HitTestView()
        self.view = view
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.backgroundColor = Colors.foregroundColor
        scrollView.canCancelContentTouches = true
        scrollView.delegate = self
        scrollView.keyboardDismissMode = .interactive
        self.view.addSubview(scrollView)
        
        textView.font = Fonts.regular.withSize(18)
        textView.textColor = Colors.text.withAlphaComponent(0.9)
        textView.placeholder = "Tap to add a note for this session"
        textView.text = ""
        textView.delegate = self
        textView.isScrollEnabled = false
        scrollView.addSubview(textView)
        
        textView.shouldStartEditingHandler = {
            [weak self] in
            guard let self = self else { return false }
            
            if Settings.isPremium {
                return true
            }
            else {
                self.presentModal(AndanteProViewController(), animated: true, completion: nil)
                return false
            }
        }
                
        titleLabel.tintColor = Colors.orange
        titleLabel.font = Fonts.bold.withSize(30)
        titleLabel.placeholder = User.getActiveProfile()?.defaultSessionTitle ?? "Practice"
        titleLabel.textColor = Colors.text
        titleLabel.autocapitalizationType = .words
        titleLabel.delegate = self
        titleLabel.returnKeyType = .done
        titleLabel.addTarget(self, action: #selector(didEditTitle), for: .editingChanged)
        scrollView.addSubview(titleLabel)
        
        titleSep.inset = UIEdgeInsets(Constants.margin)
        scrollView.addSubview(titleSep)
        
        notesLabel.textColor = Colors.text
        notesLabel.font = Fonts.semibold.withSize(20)
        notesLabel.text = "Notes"
        scrollView.addSubview(notesLabel)
        
        calendarPicker.delegate = self
        calendarPicker.interactionHandler = {
            self.practicePicker.resignFirstResponder()
            self.timePicker.resignFirstResponder()
            self.titleLabel.resignFirstResponder()
        }
        scrollView.addSubview(calendarPicker)
        
        let toolbar = DoneToolbar()
        toolbar.doneHandler = {
            [weak self] in
            self?.textView.resignFirstResponder()
        }
        textView.inputAccessoryView = toolbar
        textView.delegate = self
        
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.setTitleColor(Colors.orange, for: .normal)
        cancelButton.titleLabel?.font = Fonts.regular.withSize(17)
        cancelButton.contentHorizontalAlignment = .left
        cancelButton.titleEdgeInsets.left = Constants.margin
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        topView.addSubview(cancelButton)
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(Colors.orange, for: .normal)
        saveButton.titleLabel?.font = Fonts.semibold.withSize(17)
        saveButton.contentHorizontalAlignment = .right
        saveButton.titleEdgeInsets.right = Constants.margin
        saveButton.addTarget(self, action: #selector(didTapSave), for: .touchUpInside)
        topView.addSubview(saveButton)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        setStatCells()

        timePicker.date = Date().addingTimeInterval(-3600)
        
        topView.backgroundColor = Colors.foregroundColor
        self.view.addSubview(topView)
        
    }
    
    @objc func didEditTitle() {
        setDidEdit()
    }
    
    func setDidEdit() {
        didEdit = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        textView.resignFirstResponder()
        titleLabel.resignFirstResponder()
        
    }
    
    func scrollTextView() {
        layoutTextView()
        
        let selectionFrame = textView.convert(textView.currentSelectionRect, to: scrollView)
        let maxOffset = scrollView.contentSize.height - self.scrollView.bounds.height + scrollView.contentInset.bottom
        
        UIView.animateWithCurve(duration: 0.35, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.scrollView.setContentOffset(
                CGPoint(x: 0, y: min(maxOffset, selectionFrame.origin.y - 50 - self.view.bounds.height*0.15)),
                animated: false)
        }, completion: nil)

    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        if textView.isFirstResponder {
            scrollTextView()
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        layoutTextView()
        scrollTextView()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        layoutTextView()
    }
    
    func textViewDidChange(_ textView: UITextView) {
        setDidEdit()
    }
    
    @objc func didTapCancel() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func didTapSave() {
        
        let session = SessionModel()
        
        if practicePicker.isFirstResponder {
            practicePicker.resignFirstResponder()
            return
        }
        else if timePicker.isFirstResponder {
            timePicker.resignFirstResponder()
            return
        }

        let title = titleLabel.hasText ? titleLabel.text! : User.getActiveProfile()?.defaultSessionTitle ?? "Practice"
        let startDay = calendarPicker.selectedDay
        let timePickerDate = timePicker.date
        
        let calendar = Calendar.current
        var dateComponents = DateComponents(calendar: calendar)
        dateComponents.day = startDay.day
        dateComponents.month = startDay.month
        dateComponents.year = startDay.year
        dateComponents.hour = Calendar.current.component(.hour, from: timePickerDate)
        dateComponents.minute = Calendar.current.component(.minute, from: timePickerDate)
        
        let start = dateComponents.date ?? Date()
        let end = start.addingTimeInterval(TimeInterval(practicePicker.value * 60))
        
        session.start = start
        session.end = end
        session.practiceTime = practicePicker.value
        session.mood = moodCell.value
        session.focus = focusCell.value
        session.notes = textView.text
        session.title = title
        session.profile = profileCell.profile
                
        if let container = self.presentingViewController as? AndanteViewController {
            container.savePracticeSession(session)
        }
        
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset.bottom = 0
        } else {
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentInset.bottom = keyboardViewEndFrame.height - self.view.safeAreaInsets.bottom
                
                if self.titleLabel.isFirstResponder {
                    self.scrollView.setContentOffset(.init(x: 0, y: -self.scrollView.contentInset.top), animated: false)
                }
                else if self.practicePicker.isFirstResponder || self.timePicker.isFirstResponder {
                    let height = self.scrollView.frame.height - self.scrollView.contentInset.top - (keyboardViewEndFrame.height)
                    let scrollTopY = self.practicedCell.frame.maxY - height
                    let offset = -self.scrollView.contentInset.top + scrollTopY - 1
                    self.scrollView.setContentOffset(
                        CGPoint(x: 0, y: max(self.scrollView.contentOffset.y, offset)), animated: false)
                }
                
            }
            
        }
                
        scrollView.scrollIndicatorInsets = scrollView.contentInset

    }
    
    func setStatCells() {
        
        if User.getActiveProfile() == nil {
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
                self.presentPopupViewController(popup)
            }
            self.scrollView.addSubview(profileCell)
        }
        
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
        moodCell.valueChangeHandler = {
            [weak self] value in
            guard let self = self else { return }
            self.setDidEdit()
        }
        scrollView.addSubview(moodCell)
        
        focusCell.title = "Focus"
        focusCell.stat = .focus
        focusCell.setType(.focus)
        focusCell.valueChangeHandler = {
            [weak self] value in
            guard let self = self else { return }
            self.setDidEdit()
        }
        scrollView.addSubview(focusCell)
        
    }
    
    func pickerViewDidEdit(_ view: UIView) {
        setDidEdit()
    }
    
    func pickerViewWillBeginEditing(_ view: UIView) {
        
        if view === practicePicker {
            if calendarPicker.selectedDay == Day(date: Date()) {
                let date = Calendar.current.date(bySetting: .second, value: 0, of: Date()) ?? Date()
                let interval = Int(date.timeIntervalSince(timePicker.date)/60) - 1
                if interval > 0 && interval < 3*60 {
                    practicePicker.useSuggested = true
                }
                else {
                    practicePicker.useSuggested = false
                }
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    //MARK: viewDidLayoutSubviews
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        topView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 54)
        scrollView.frame = self.view.bounds.inset(by: UIEdgeInsets(top: topView.bounds.height, left: 0, bottom: 0, right: 0))
        
        cancelButton.frame = CGRect(
            x: (view.responsiveMargin - Constants.margin), y: 6,
            width: 90, height: topView.bounds.height-6)
        
        saveButton.frame = CGRect(
            x: self.view.bounds.maxX - 80 - (view.responsiveMargin - Constants.margin), y: 6,
            width: 80, height: topView.bounds.height-6)
        
        
        layoutTitleLabel()
        
        titleSep.inset = UIEdgeInsets(view.responsiveMargin)
        titleSep.frame = CGRect(x: 0, y: titleLabel.frame.maxY + 8, width: self.view.bounds.width, height: 1)
        
        let calendarHeight = calendarPicker.sizeThatFits(self.view.bounds.size).height
        calendarPicker.frame = CGRect(
            x: view.responsiveMargin - Constants.margin, y: titleSep.frame.maxY + 10,
            width: self.view.bounds.width - (view.responsiveMargin - Constants.margin)*2,
            height: calendarHeight)
        
        layoutStats()
        
        layoutPickers()
        
        notesLabel.sizeToFit()
        notesLabel.frame.origin = CGPoint(
            x: view.responsiveMargin,
            y: focusCell.frame.maxY + 14)
        
        layoutTextView()
        
    }
    
    private func layoutTextView() {
        
        let margin = view.responsiveMargin
        
        textView.textContainerInset = UIEdgeInsets(top: 0, left: margin - 5, bottom: 70, right: margin - 5)
        
        let textHeight = max(200, textView.sizeThatFits(self.view.bounds.size).height)
        let height = textView.isFirstResponder ? max(textHeight, self.view.bounds.height*0.35) : textHeight
        
        textView.frame = CGRect(
            x: 0, y: notesLabel.frame.maxY + 4,
            width: scrollView.bounds.width,
            height: height)
        
        scrollView.contentSize = CGSize(
            width: self.view.bounds.width,
            height: textView.frame.maxY)
        
    }
    
    private func layoutTitleLabel() {
        titleLabel.sizeToFit()
        
        let margin = view.responsiveMargin
        
        let titleWidth = titleLabel.isFirstResponder ? self.view.bounds.width - margin*2 : min(titleLabel.bounds.width, self.view.bounds.width - margin*2)
        
        titleLabel.frame = CGRect(x: view.responsiveMargin, y: 20,
                                  width: titleWidth,
                                  height: titleLabel.bounds.size.height)
                
    }
    
    private func layoutPickers() {
        
        let margin = view.responsiveSmallMargin
        
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
        
    }
    
    private func layoutStats() {
        
        let cellHeight: CGFloat = 70
        
        var cells: [Separator] = [timeCell, practicedCell, moodCell, focusCell]
        if self.profileCell.superview == self {
            cells.insert(self.profileCell, at: 0)
        }
        
        for (i, cell) in cells.enumerated() {
            cell.inset = UIEdgeInsets(view.responsiveMargin)
            cell.frame = CGRect(
                x: 0, y: calendarPicker.frame.maxY + CGFloat(i)*cellHeight,
                width: self.view.bounds.width,
                height: cellHeight)
        }
        
        
    }
    
    func calendarPickerDidChangeMonth(to month: Month) {
        view.setNeedsLayout()
    }
    
    func calendarPickerDidSelectDay(day: Day) {
        setDidEdit()
    }
    
}

//MARK: Textfield delegate
extension ManualSessionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        layoutTitleLabel()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        layoutTitleLabel()
        
    }
    
}

fileprivate class StatsCell: UIView {
    
    private let iconView = StatIconView()
    private let titleLabel = UILabel()
    
    public var stat: Stat? {
        didSet {
            iconView.stat = stat ?? .mood
        }
    }
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    public func setTitle(_ part1: String, _ part2: String) {
        let str = NSMutableAttributedString(string: part1, attributes: [
            NSAttributedString.Key.foregroundColor : Colors.text,
            NSAttributedString.Key.font : Fonts.semibold.withSize(18),
            .kern : 0//.6
        ])
        
        str.append(NSAttributedString(string: part2, attributes: [
            NSAttributedString.Key.foregroundColor : Colors.lightText,
            NSAttributedString.Key.font : Fonts.medium.withSize(18),
            .kern : 0//.6
        ]))
        
        titleLabel.attributedText = str
    }
    
    public func setTimeTitle(start: Date, end: Date) {
        func timeAttributedString(_ date: Date, color: UIColor, lightWeight: Bool = false) -> NSAttributedString {
            let text = Formatter.getTimeTextSplit(from: date)
            
            let str = NSMutableAttributedString(string: text.time, attributes: [
                .foregroundColor : color,
                .font : lightWeight ? Fonts.medium.withSize(18) : Fonts.semibold.withSize(18),
                .kern : 0//.6
            ])
            
            if let suffix = text.suffix {
                str.append(NSAttributedString(string: " \(suffix)", attributes: [
                    .foregroundColor : color,
                    .font : lightWeight ? Fonts.medium.withSize(18) : Fonts.regular.withSize(18),
                    .kern : 0//1.3
                ]))
            }
            
            return str
        }
        let str = NSMutableAttributedString()
        
        str.append(timeAttributedString(start, color: Colors.text))
        
        str.append(NSAttributedString(string: "  -  ", attributes: [
            NSAttributedString.Key.foregroundColor : Colors.lightText,
            NSAttributedString.Key.font : Fonts.semibold.withSize(18),
        ]))
        
        str.append(timeAttributedString(end, color: Colors.lightText, lightWeight: true))
        
        titleLabel.attributedText = str
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        self.addSubview(iconView)
        
        titleLabel.font = Fonts.medium.withSize(19)
        titleLabel.textColor = Colors.text
        self.addSubview(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.iconSize = CGSize(22)
        iconView.frame = CGRect(
            x: Constants.margin,
            y: self.bounds.midY - 18,
            width: 36,
            height: 36).integral
        iconView.roundCorners(10)
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: iconView.frame.maxX + 16, y: 0,
                                  width: titleLabel.bounds.width,
                                  height: self.bounds.height)
    }
}

class SessionStatCell: Separator {
    
    private let iconView = StatIconView()
    private let titleLabel = UILabel()
    
    public var stat: Stat? {
        didSet {
            iconView.stat = stat ?? .mood
        }
    }
    
    public var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        self.addSubview(iconView)
        
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textColor = Colors.text
        self.addSubview(titleLabel)
        
        self.position = .bottom
        self.inset = UIEdgeInsets(Constants.margin)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.iconSize = CGSize(22)
        iconView.frame = CGRect(
            x: responsiveMargin,
            y: self.bounds.midY - 18,
            width: 36,
            height: 36).integral
        iconView.roundCorners(10)
        
        titleLabel.sizeToFit()
        titleLabel.frame = CGRect(x: iconView.frame.maxX + 16, y: 0,
                                  width: titleLabel.bounds.width,
                                  height: self.bounds.height)
    }
}

class ChooseProfileCell: Separator {
    
    private let button = UIButton()
    private let profileIcon = ProfileImageView()
    private let label = UILabel()
    
    private var cancellables = Set<AnyCancellable>()
    
    public var profile: CDProfile? {
        didSet {
            self.cancellables.removeAll()
            self.profileIcon.profile = profile
            self.profile?.publisher(for: \.name).sink { [weak self] name in
                self?.button.setTitle(name ?? "", for: .normal)
            }.store(in: &cancellables)
            self.setNeedsLayout()
        }
    }
    
    public func highlight() {
        button.setTitleColor(Colors.orange, for: .normal)
    }
    
    public func endHighlight() {
        self.button.setTitleColor(Colors.text, for: .normal)
    }
    
    public var action: (()->Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        profileIcon.inset = 5
        self.addSubview(profileIcon)
        
        label.text = "Profile"
        label.font = Fonts.semibold.withSize(17)
        label.textColor = Colors.text
        self.addSubview(label)
        
        self.position = .bottom
        self.inset = UIEdgeInsets(Constants.margin)
        
        button.setTitleColor(Colors.text, for: .normal)
        button.titleLabel?.font = Fonts.medium.withSize(16)
        button.backgroundColor = Colors.lightColor
        button.roundCorners(10)
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        
        self.addSubview(button)

        
    }
    
    @objc func didTapButton() {
        action?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        profileIcon.frame = CGRect(
            x: responsiveMargin,
            y: self.bounds.midY - 18,
            width: 36,
            height: 36).integral
        profileIcon.cornerRadius = 10
        
        label.sizeToFit()
        label.frame = CGRect(
            x: profileIcon.frame.maxX + 16, y: 0,
            width: label.bounds.width,
            height: self.bounds.height
        )
        
        let labelSize = button.titleLabel!.sizeThatFits(self.bounds.size)
        button.frame = CGRect(
            x: self.bounds.width - Constants.margin - labelSize.width - 28,
            y: self.bounds.midY - labelSize.height/2 - 8,
            width: labelSize.width + 28, height: labelSize.height + 16)
        
    }
}

class MFCell: SessionStatCell {
    
    private let bgView = UIView()
    private let selectedView = UIView()
    private var buttons: [UIButton] = []
    private let feedback = UIImpactFeedbackGenerator(style: .light)
        
    enum MFType {
        case mood, focus
    }
    
    public func setType(_ type: MFCell.MFType) {
        feedback.prepare()
        
        for i in 0...4 {
            let button = MFButton()
            button.tag = i+1
            
            if type == .mood {
                button.fgImage = UIImage(named: "mood\(i+1)")?.withRenderingMode(.alwaysTemplate)
            }
            else {
                button.bgImage = UIImage(named: "focusBG")?.withRenderingMode(.alwaysTemplate)
                if i == 0 {
                    button.fgImage = nil
                }
                else if i == 4 {
                    button.fgImage = UIImage(named: "focusBG")?.withRenderingMode(.alwaysTemplate)
                }
                else {
                    button.fgImage = UIImage(named: "focus\(i+1)")?.withRenderingMode(.alwaysTemplate)
                }
                
            }
            
            button.action = {
                [weak self] in
                guard let self = self else { return }
                self.didSelectButton(button)
                self.feedback.impactOccurred()
            }
            
            if i == 2 {
                button.isUserInteractionEnabled = false
                button.alpha = 1
                button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            else {
                button.isUserInteractionEnabled = true
                button.alpha = 0.8
                button.transform = .identity
            }
            
            self.addSubview(button)
            buttons.append(button)
            
        }
    }
    
    public var value = 3
    public func setInitialValue(_ value: Int) {
        self.value = value
        for button in buttons {
            if button.tag == value {
                button.isUserInteractionEnabled = false
                button.alpha = 1
                button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            else {
                button.isUserInteractionEnabled = true
                button.alpha = 0.8
                button.transform = .identity
            }
        }
        
        self.setNeedsLayout()
    }
    
    public var valueChangeHandler: ((_:Int)->Void)?
    
    override init() {
        super.init()
        
        bgView.backgroundColor = Colors.lightColor
        bgView.roundCorners(10)
        self.addSubview(bgView)
        
        selectedView.backgroundColor = Colors.dynamicColor(
            light: Colors.foregroundColor,
            dark: Colors.text.withAlphaComponent(0.25))
        selectedView.setShadow(radius: 4, yOffset: 1, opacity: 0.08)
        selectedView.roundCorners(8)
        self.addSubview(selectedView)
                
    }
    
    @objc func didSelectButton(_ sender: UIButton) {
        
        self.value = sender.tag
        
        self.valueChangeHandler?(value)
        
        for button in buttons {
            UIView.animate(withDuration: 0.18) {
                if button.tag == sender.tag {
                    button.isUserInteractionEnabled = false
                    button.alpha = 1
                    button.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                }
                else {
                    button.isUserInteractionEnabled = true
                    button.alpha = 0.8
                    button.transform = .identity
                }
            }
        }
        
        UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.88, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.layoutSubviews()
        }, completion: nil)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let totalWidth: CGFloat = isSmallScreen() ? 166 : 200
        
        bgView.frame = CGRect(
            x: self.bounds.maxX - responsiveSmallMargin - totalWidth,
            y: self.bounds.midY - 20,
            width: totalWidth, height: 40).insetBy(dx: -2, dy: 0)
        
        let width = (bgView.bounds.width - 4)/5
        
        for i in 0..<buttons.count {
            
            let button = buttons[i]
            let frame = CGRect(
                x: 2 + bgView.frame.minX + CGFloat(i)*width,
                y: 0, width: width, height: self.bounds.height)
            button.bounds.size = frame.size
            button.center = frame.center
            
        }
        
        let selectedValue = value-1
        selectedView.frame = CGRect(
            x: bgView.frame.minX + CGFloat(selectedValue)*width + 4,
            y: bgView.frame.minY + 4,
            width: width - 4,
            height: bgView.bounds.height - 8)
        
    }
    
    private class MFButton: CustomButton {
        
        private let imagesView = UIView()
        private let bgImageView = UIImageView()
        private let fgImageView = UIImageView()
        
        public var bgImage: UIImage? {
            didSet {
                bgImageView.image = bgImage
                bgImageView.setImageColor(color: Colors.text.withAlphaComponent(0.2))
            }
        }
        public var fgImage: UIImage? {
            didSet {
                fgImageView.image = fgImage
                fgImageView.setImageColor(color: Colors.text)
            }
        }
        
        override init() {
            super.init()
            
            imagesView.isUserInteractionEnabled = false
            
            imagesView.addSubview(bgImageView)
            imagesView.addSubview(fgImageView)
            self.addSubview(imagesView)
            
            self.highlightAction = {
                [weak self] highlighted in
                guard let self = self else { return }
                
                if highlighted {
                    UIView.animate(withDuration: 0.2) {
                        self.imagesView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                        self.imagesView.alpha = 0.5
                    }
                }
                else {
                    UIView.animate(withDuration: 0.25) {
                        self.imagesView.transform = CGAffineTransform(scaleX: 1, y: 1)
                        self.imagesView.alpha = 1
                    }
                }
            }
            
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            imagesView.bounds.size = self.bounds.size
            imagesView.center = self.bounds.center
            
            fgImageView.bounds.size = CGSize(22)
            fgImageView.center = imagesView.bounds.center
            
            bgImageView.bounds.size = CGSize(22)
            bgImageView.center = imagesView.bounds.center
            
        }
    }
        
}
