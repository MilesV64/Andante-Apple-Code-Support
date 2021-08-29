//
//  NewReminderViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class NewReminderViewController: UIViewController {
    
    struct ReminderModel {
        let date: Date
        let days: Array<Int>
        let profileID: String
        let isEnabled: Bool
    }

    
    private let headerView = ModalViewHeader()
    
    private let datePickerView = Separator(position: .bottom)
    private let datePicker = UIDatePicker()
    
    private let profilePickerView = CustomButton()
    private let profilePickerSeparator = Separator(position: .bottom)
    private let profileLabel = UILabel()
    
    private let repeatView = UIView()
    private let repeatDaysView = RepeatDaysView()
    private let repeatLabel = UILabel()
    
    public var profile: CDProfile?
    
    public var action: ((_ reminder: ReminderModel)->Void)?
    public var deleteAction: (()->Void)?
    
    public var reminder: CDReminder?
    private var deleteButton: PushButton?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.modalPresentationStyle = .popover
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        preferredContentSize = CGSize(width: 375, height: 550)
                
        if let reminder = reminder {
            datePicker.date = reminder.date ?? Date()
            repeatDaysView.selectedDays = Set(reminder.getDays())
            headerView.title = "Edit Reminder"
            
            deleteButton = PushButton()
            deleteButton?.cornerRadius = 12
            deleteButton?.backgroundColor = Colors.lightColor
            deleteButton?.setTitle("Delete Reminder", color: Colors.red, font: Fonts.medium.withSize(17))
            deleteButton?.action = {
                [weak self] in
                guard let self = self else { return }
                self.dismiss(animated: true, completion: nil)
                self.deleteAction?()
            }
            view.addSubview(deleteButton!)
            
        } else {
            headerView.title = "New Reminder"
        }
        
        view.backgroundColor = Colors.foregroundColor
        
        headerView.showsHandle = false
        
        headerView.showsCancelButton = true
        headerView.cancelButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true, completion: nil)
        }
        
        headerView.showsDoneButton = true
        headerView.doneButtonText = "Save"
        headerView.doneButtonAction = {
            [weak self] in
            guard let self = self else { return }
            self.save()
        }
        
        view.addSubview(headerView)
        
        datePicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            datePicker.preferredDatePickerStyle = .wheels
        }
        
        datePickerView.addSubview(datePicker)
        view.addSubview(datePickerView)
        
        profilePickerView.contentHorizontalAlignment = .left
        profilePickerView.setTitle("Profile", color: Colors.text, font: Fonts.semibold.withSize(17))
        profilePickerView.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.profilePickerView.backgroundColor = Colors.cellHighlightColor
            } else {
                UIView.animate(withDuration: 0.25) {
                    self.profilePickerView.backgroundColor = .clear
                }
            }
        }
        
        profilePickerView.action = {
            [weak self] in
            guard let self = self else { return }
            
            let vc = ProfilesPopupViewController()
            vc.selectedProfile = self.profile
            vc.useNewProfileButton = false
            vc.action = {
                [weak self] profile in
                guard let self = self else { return }
                self.profile = profile
                self.profileLabel.text = profile.name
            }
            
            self.presentPopupViewController(vc)
        }
        
        profilePickerView.addSubview(profilePickerSeparator)
        
        profileLabel.text = profile?.name ?? ""
        profileLabel.textAlignment = .right
        profileLabel.textColor = Colors.lightText
        profileLabel.font = Fonts.regular.withSize(17)
        profileLabel.isUserInteractionEnabled = false
        profilePickerView.addSubview(profileLabel)
        view.addSubview(profilePickerView)
        
        repeatLabel.text = "Repeat"
        repeatLabel.font = Fonts.semibold.withSize(17)
        repeatLabel.textColor = Colors.text
        repeatView.addSubview(repeatLabel)
        
        repeatView.addSubview(repeatDaysView)
        
        view.addSubview(repeatView)
            
    }
    
    private func save() {
        
        let calendar = Calendar.current
        var dateComponents = DateComponents()
        dateComponents.second = 0
        dateComponents.day = 1
        dateComponents.month = 1
        dateComponents.year = 2000
        dateComponents.hour = calendar.component(.hour, from: datePicker.date)
        dateComponents.minute = calendar.component(.minute, from: datePicker.date)
        
        self.dismiss(animated: true, completion: nil)
        
        self.action?(
            ReminderModel(
                date: calendar.date(from: dateComponents)!,
                days: Array(repeatDaysView.selectedDays),
                profileID: profile?.uuid ?? "",
                isEnabled: self.reminder?.isEnabled ?? true))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let leftInset = view.safeAreaInsets.left

        headerView.extraInset.left = leftInset
        headerView.sizeToFit()
        headerView.bounds.size.width = view.bounds.width
        headerView.frame.origin = .zero
        
        datePickerView.frame = CGRect(
            x: 0, y: headerView.frame.maxY,
            width: view.bounds.width, height: view.bounds.height*0.33)
        
        datePicker.frame = datePickerView.bounds.inset(
            by: UIEdgeInsets(top: 0, left: leftInset + 6, bottom: 0, right: 6))
        
        profilePickerView.contentEdgeInsets.left = Constants.margin + leftInset
        profilePickerView.frame = CGRect(
            x: 0, y: datePickerView.frame.maxY,
            width: view.bounds.width, height: 68)
        
        profilePickerSeparator.frame = profilePickerView.bounds
        
        profileLabel.frame = CGRect(
            x: profilePickerView.bounds.maxX - 200 - Constants.margin,
            y: 0, width: 200, height: profilePickerView.bounds.height)
        
        repeatView.frame = CGRect(
            x: 0, y: profilePickerView.frame.maxY,
            width: view.bounds.width,
            height: 132)
        
        repeatLabel.sizeToFit()
        repeatLabel.frame.origin = CGPoint(x: Constants.margin + leftInset, y: 22)
        
        repeatDaysView.frame = CGRect(
            x: leftInset, y: repeatLabel.frame.maxY + 20,
            width: view.bounds.width - leftInset,
            height: 60)
        
        if let deleteButton = deleteButton {
            let bottomSpace: CGFloat = max(view.safeAreaInsets.bottom + 6, 16)
            deleteButton.frame = CGRect(
                x: Constants.smallMargin + leftInset,
                y: view.bounds.maxY - bottomSpace - 50,
                width: view.bounds.width - Constants.smallMargin*2 - leftInset,
                height: 50)
        }
        
        
    }
    
}

fileprivate class RepeatDaysView: UIView {
    
    private var buttons: [DayButton] = []
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    
    public var selectedDays = Set<Int>() {
        didSet {
            for i in 0...6 {
                buttons[i].setSelected(selectedDays.contains(i))
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        selectedDays = [0,1,2,3,4,5,6]
        
        for i in 0...6 {
            let button = DayButton(dayIndex: i, selected: selectedDays.contains(i))
            button.tag = i
            button.action = {
                [weak self] in
                guard let self = self else { return }
                
                self.selectionFeedback.impactOccurred()
                if self.selectedDays.contains(button.tag) {
                    self.selectedDays.remove(button.tag)
                    UIView.animate(withDuration: 0.1) {
                        button.setSelected(false)
                    }
                    
                } else {
                    self.selectedDays.insert(button.tag)
                    button.setSelected(true)
                }
            }
            buttons.append(button)
            self.addSubview(button)
        }
        
        selectionFeedback.prepare()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let inset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        let buttonSize = CGSize(
            width: 40 + inset.left + inset.right,
            height: 40 + inset.top + inset.bottom)
        
        let totalWidth = self.bounds.width - Constants.smallMargin*2
        let spacing = (totalWidth - buttonSize.width*7)/6
        
        
        for i in 0..<buttons.count {
            let button = buttons[i]
            button.inset = inset
            button.frame = CGRect(
                x: Constants.smallMargin + CGFloat(i)*(buttonSize.width+spacing),
                y: 0,
                width: buttonSize.width,
                height: buttonSize.height)
        }
        
        
    }
    
    private class DayButton: PushButton {
        
        init(dayIndex: Int, selected: Bool) {
            super.init()
            
            switch dayIndex {
            case 0:
                self.setTitle("M", for: .normal)
            case 1:
                self.setTitle("T", for: .normal)
            case 2:
                self.setTitle("W", for: .normal)
            case 3:
                self.setTitle("T", for: .normal)
            case 4:
                self.setTitle("F", for: .normal)
            case 5:
                self.setTitle("S", for: .normal)
            default:
                self.setTitle("S", for: .normal)
            }
            
            setSelected(selected)
                  
        }
        
        func setSelected(_ selected: Bool) {
            self.setTitleColor(selected ? Colors.white : Colors.text, for: .normal)
            self.titleLabel?.font = selected ? Fonts.semibold.withSize(16) : Fonts.regular.withSize(16)
            self.backgroundColor = selected ? Colors.orange : Colors.lightColor
            self.setShadow(radius: 6, yOffset: 3, opacity: selected ? 0.05 : 0)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError()
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            self.cornerRadius = self.bounds.inset(by: self.inset).width/2
        }
        
    }
}
