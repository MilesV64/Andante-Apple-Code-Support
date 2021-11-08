//
//  EditSessionViewController.swift
//  Andante
//
//  Created by Miles Vinson on 10/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class EditSessionViewController: ManualSessionViewController {
    
    struct SessionEdits {
        let title: String
        let notes: String
        let mood: Int
        let focus: Int
        let begin: Date
        let practiceTime: Int
    }
    
    private var session: CDSession!
    public var saveHandler: ((_:EditSessionViewController.SessionEdits)->Void)?
    
    convenience init(_ session: CDSession) {
        self.init()
        
        self.session = session
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = Constants.modalSize
        
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(Colors.extraLightText, for: .disabled)
        saveButton.isEnabled = false
        
        titleLabel.text = session.getTitle()
        calendarPicker.setInitialDay(Day(date: session.startTime))
        timePicker.date = session.startTime
        practicePicker.value = session.practiceTime
        moodCell.setInitialValue(session.mood)
        focusCell.setInitialValue(session.focus)
        textView.text = session.notes ?? ""
        
        self.profileCell.removeFromSuperview()
        
    }
    
    override func setDidEdit() {
        if !didEdit {
            saveButton.isEnabled = true
        }
        didEdit = true
    }
    
    override func didTapSave() {
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
        
        let edits = SessionEdits(
            title: title,
            notes: textView.text,
            mood: moodCell.value,
            focus: focusCell.value,
            begin: start,
            practiceTime: practicePicker.value)
        
        saveHandler?(edits)
        
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
}
