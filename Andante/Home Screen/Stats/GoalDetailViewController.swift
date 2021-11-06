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
    
    private let headerView = ModalViewHeader(title: "Daily Practice Goal")
    
    private let goalCell = AndanteCellView(
        title: "Daily Goal",
        icon: Stat.practice.icon,
        imageSize: CGSize(22),
        iconColor: Stat.practice.color
    )
    
    private let goalButton = MinutePickerView(.prominent)
    private let separator = Separator(position: .top)
    private let descriptionLabel = UILabel()
    
    private var currentGoal = 0
    
    private let goalCalendar = CalendarGoalView()
            
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = Colors.foregroundColor
        
        if let profile = User.getActiveProfile() {
            currentGoal = Int(profile.dailyGoal)
            goalButton.value = currentGoal
            self.descriptionLabel.isHidden = true
        }
        else {
            currentGoal = CDProfile.getTotalDailyGoal()
            goalButton.value = currentGoal
            goalButton.button.backgroundColor = .clear
            goalButton.isUserInteractionEnabled = false
            
            self.descriptionLabel.text = "Showing the sum of each profile’s individual goals. You can change each profile’s goal in Settings."
            self.descriptionLabel.numberOfLines = 0
            self.descriptionLabel.textColor = Colors.lightText
            self.descriptionLabel.font = Fonts.regular.withSize(14)
            self.descriptionLabel.lineBreakMode = .byWordWrapping
            self.view.addSubview(self.descriptionLabel)
            
        }
        
        goalButton.delegate = self
        
        self.goalCell.button.isUserInteractionEnabled = false
        self.view.addSubview(self.goalCell)
        
        self.goalCell.addSubview(goalButton)
        
        self.separator.insetToMargins()
        self.view.addSubview(self.separator)
        
        self.view.addSubview(goalCalendar)
        
        
        headerView.backgroundColor = .clear
        headerView.showsSeparator = true
        headerView.headerSeparator.insetToMargins()
        
        headerView.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            
            self.goalButton.resignFirstResponder()
            self.goalButton.value = Int(self.currentGoal)
            
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
            self.goalButton.value = self.currentGoal
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
            self.goalButton.value = self.currentGoal
        }
        else {
            if self.currentGoal != self.goalButton.value {
                self.currentGoal = self.goalButton.value
                
                User.getActiveProfile()?.dailyGoal = Int64(self.currentGoal)
                
                DataManager.saveContext()
                WidgetDataManager.writeData()
                
                self.goalCalendar.reloadData()
                
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
            height: 70)
        
        goalCell.frame = CGRect(
            x: 0,
            y: headerView.frame.maxY,
            width: self.view.bounds.width,
            height: 76
        )
        
        goalButton.sizeToFit()
        goalButton.center = CGPoint(
            x: goalCell.bounds.maxX - Constants.margin - goalButton.bounds.width/2,
            y: goalCell.bounds.midY)
        
        if self.descriptionLabel.isHidden == false {
            let height = self.descriptionLabel.sizeThatFits(self.view.bounds.insetBy(dx: Constants.margin*2, dy: 0).size).height
            descriptionLabel.frame = CGRect(x: Constants.margin, y: goalCell.frame.maxY - 12, width: self.view.bounds.width - Constants.margin*2, height: height)
            self.separator.frame = CGRect(x: 0, y: descriptionLabel.frame.maxY + 10, width: self.view.bounds.width, height: 1)
        }
        else {
            self.separator.frame = CGRect(x: 0, y: goalCell.frame.maxY, width: self.view.bounds.width, height: 1)
        }
        
        goalCalendar.frame = CGRect(
            x: 0,
            y: separator.frame.maxY + 10,
            width: self.view.bounds.width,
            height: totalHeight - (goalCell.frame.maxY + 20))
        
        if goalCalendar.bounds.height < 100 {
            goalCalendar.alpha = 0
        } else {
            goalCalendar.alpha = 1
        }
        
    }
    
}
