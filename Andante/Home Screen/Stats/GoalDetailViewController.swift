//
//  GoalDetailViewController.swift
//  Andante
//
//  Created by Miles Vinson on 6/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine

class PopoverViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    public var isPopover: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .popover
        if #available(iOS 15.0, *) {
            self.popoverPresentationController?.adaptiveSheetPresentationController.preferredCornerRadius = 25
        }
        self.popoverPresentationController?.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIDevice.current.userInterfaceIdiom == .pad ? .none : .automatic
    }
    
}

class HitTestView: UIView {
    public var hitTestHandler: ((UIView?)->Void)?
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        hitTestHandler?(view)
        return view
    }    
}

class GoalDetailViewController: PopoverViewController, PickerViewDelegate {
    
    private let headerView = ModalViewHeader(title: "")
    
    private let titleLabel = TitleBodyGroup()

    private let goalButton = MinutePickerView(.inline)
    private var profile: CDProfile?
    private var currentGoal = 0
    
    private let goalCalendar = CalendarGoalView()
        
    private let goalPicker = PracticeGoalPickerView()
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profile = User.getActiveProfile()
        
        profile?.publisher(for: \.dailyGoal, options: .new).sink {
            [weak self] goal in
            guard let self = self else { return }
            self.currentGoal = Int(goal)
            self.goalButton.value = self.currentGoal
            self.goalCalendar.reloadData()
        }.store(in: &cancellables)
        
        self.view.backgroundColor = Colors.foregroundColor
        
        titleLabel.titleLabel.text = "Daily Goal"
        titleLabel.titleLabel.textColor = Colors.text
        titleLabel.titleLabel.font = Fonts.bold.withSize(28)
        titleLabel.padding = -1
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 3
        titleLabel.textView.attributedText = NSAttributedString(
            string: "Stay motivated with a daily practice goal for this profile.",
            attributes: [
                .foregroundColor : Colors.lightText,
                .font : Fonts.regular.withSize(17),
                .paragraphStyle : paragraphStyle
            ])
        titleLabel.textView.textContainerInset.left = Constants.margin + 5
        titleLabel.textView.textContainerInset.right = Constants.margin + 5
        titleLabel.textAlignment = .center
        self.view.addSubview(titleLabel)
        
        currentGoal = Int(profile?.dailyGoal ?? 10)
        goalButton.value = currentGoal
        goalButton.delegate = self
        
        goalPicker.goalButton = goalButton
        self.view.addSubview(goalPicker)
        
        self.view.addSubview(goalCalendar)
        
        headerView.backgroundColor = .clear
        headerView.showsSeparator = false
        
        headerView.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            
            self.goalButton.resignFirstResponder()
            self.goalButton.value = Int(self.profile?.dailyGoal ?? 10)
            
        }
        headerView.doneButtonText = "Save"
        headerView.doneButtonAction = {
            [weak self] in
            guard let self = self else { return }
            
            self.didSave = true
            
            self.goalButton.resignFirstResponder()
            
        }
        self.view.addSubview(headerView)
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        
        notificationCenter.addObserver(self, selector: #selector(reloadData), name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
        
    }
    
    
    @objc func reloadData() {
        goalCalendar.reloadData()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: UIApplication.shared.windows.first)
        print(keyboardViewEndFrame, self.view.bounds)
        if notification.name == UIResponder.keyboardWillHideNotification {
            
        } else {
            
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        headerView.showsHandle = UIDevice.current.userInterfaceIdiom != .pad
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if goalButton.isFirstResponder {
            self.goalButton.resignFirstResponder()
            self.goalButton.value = Int(self.profile?.dailyGoal ?? 10)
        }
        
    }

    func pickerViewWillBeginEditing(_ view: UIView) {
        didSave = false
        UIView.animate(withDuration: 0.25) {
            self.headerView.showsDoneButton = true
            self.headerView.showsCancelButton = true
        }
    }
    
    private var didSave = false
    func pickerViewDidEndEditing(_ view: UIView) {
        UIView.animate(withDuration: 0.15) {
            self.headerView.showsDoneButton = false
            self.headerView.showsCancelButton = false
        }
        
        if !didSave {
            self.goalButton.value = Int(self.profile?.dailyGoal ?? 10)
        }
        else {
            if self.currentGoal != self.goalButton.value {
                self.currentGoal = self.goalButton.value
                
                self.profile?.dailyGoal = Int64(self.currentGoal)
                
                DataManager.saveContext()
                WidgetDataManager.writeData()
            }
        }
        
    }
    
    func pickerViewDidSelectAnySuggested(_ view: UIView) {
        didSave = true
    }
    
    override func viewDidLayoutSubviews() {
        self.preferredContentSize = CGSize(
            width: 380, height: 600)
        super.viewDidLayoutSubviews()
        
        headerView.showsHandle = !(popoverPresentationController?.arrowDirection != .unknown)
        
        var bottomHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        if popoverPresentationController?.arrowDirection != .unknown {
            bottomHeight = 0
            totalHeight = self.view.bounds.height - self.view.safeAreaInsets.top
        }
        else {
            bottomHeight = 30 + self.view.safeAreaInsets.bottom
            totalHeight = self.view.bounds.height - self.view.safeAreaInsets.top - bottomHeight - 30
        }
        
        headerView.frame = CGRect(
            x: 0, y: self.view.safeAreaInsets.top,
            width: self.view.bounds.width,
            height: 48)
        
        var titleSpace: CGFloat = 50
        if self.view.bounds.height < 300 {
            titleSpace = 24 //adjusting for keyboard in popover presentation
        }
        let size = titleLabel.sizeThatFits(self.view.bounds.size)
        titleLabel.frame = CGRect(
            x: self.view.bounds.midX - size.width/2,
            y: self.view.safeAreaInsets.top + titleSpace,
            width: size.width,
            height: size.height)
        
        goalPicker.sizeToFit()
        goalPicker.bounds.size.width = self.view.bounds.width
        goalPicker.frame.origin = CGPoint(
            x: 0, y: titleLabel.frame.maxY + 18)
        
        goalCalendar.frame = CGRect(
            x: 0,
            y: goalPicker.frame.maxY + 20,
            width: self.view.bounds.width,
            height: totalHeight - (goalPicker.frame.maxY + 20))
        
        if goalCalendar.bounds.height < 100 {
            goalCalendar.alpha = 0
        } else {
            goalCalendar.alpha = 1
        }
        
    }
    
}

class PracticeGoalPickerView: OptionPickerView {
    
    public var goalButton: MinutePickerView? {
        didSet {
            guard let goalButton = goalButton else { return }
            bgView.addSubview(goalButton)
        }
    }
     
    init() {
        super.init("Goal")
        self.selectHandler = {
            [weak self] in
            guard let self = self else { return }
            self.goalButton?.button.action?()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if let goalButton = self.goalButton {
            goalButton.sizeToFit()
            goalButton.frame.origin = CGPoint(
                x: bgView.bounds.maxX - goalButton.bounds.width - 4,
                y: bgView.bounds.midY - goalButton.bounds.height/2
            )
        }
        
    }
}
