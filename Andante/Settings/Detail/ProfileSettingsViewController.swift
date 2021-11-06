//
//  ProfileSettingsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/28/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine

class ProfileSettingsViewController: SettingsDetailViewController, PickerViewDelegate {
    
    private var profile: CDProfile
        
    init(profile: CDProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let nameCell = SettingsDetailTextFieldView(title: "Name")
    let iconCell = SettingsDetailProfileIconView(title: "Icon")
    let dailyGoalCell = SettingsDetailTextFieldView(title: "Daily Practice Goal")
    let sessionTitleCell = SettingsDetailTextFieldView(title: "Default Session Title")
    let mergeProfileCell = SettingsDetailView(title: "Merge Profile")
    let resetDataCell = SettingsDetailView(title: "Clear Data", destructive: true)
    let deleteCell = SettingsDetailView(title: "Delete Profile", destructive: true)
    
    private let goalButton = MinutePickerView(.inline)
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addItem(SettingsDetailGroupView(items: [nameCell, iconCell, dailyGoalCell, sessionTitleCell]))
        
        var manageItems: [SettingsDetailItem] = [mergeProfileCell, resetDataCell]
        if CDProfile.getAllProfiles().count > 1 {
            manageItems.append(deleteCell)
        }
        
        addItem(SettingsDetailGroupView(items: manageItems))
        
        profile.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            if self.profile.isDeleted {
                self.close()
            }
        }.store(in: &cancellables)
        
        profile.publisher(for: \.name).sink {
            [weak self] name in
            guard let self = self else { return }
            self.nameCell.detailText = name
            self.title = name
        }.store(in: &cancellables)
        
        profile.publisher(for: \.dailyGoal).sink {
            [weak self] goal in
            guard let self = self else { return }
            self.goalButton.value = Int(goal)
        }.store(in: &cancellables)
        
        nameCell.textAction = {
            [weak self] text in
            guard let self = self else { return }
            
            if text != nil && text!.isEmpty == false {
                self.profile.name = text!
                DataManager.saveContext()
            }
            else {
                self.nameCell.detailText = self.profile.name
            }
            
        }
        
        iconCell.profile = profile
        iconCell.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.stopEditing()
            
            let alert = IconPickerPopupController()
            alert.initialIcon = self.profile.iconName
            alert.selectionAction = {
                [weak self] string in
                guard let self = self else { return }
                self.profile.iconName = string
                DataManager.saveContext()
            }
            self.presentPopupViewController(alert)
            
        }
        
        profile.publisher(for: \.defaultSessionTitle).sink {
            [weak self] title in
            guard let self = self else { return }
            self.sessionTitleCell.detailText = title
        }.store(in: &cancellables)
        
        self.goalButton.delegate = self
        self.goalButton.allowsEditing = false
        self.dailyGoalCell.action = { [weak self] in
            self?.setSaveButtonVisible(true)
            self?.goalButton.becomeFirstResponder()
        }
        self.dailyGoalCell.addSubview(self.goalButton)
        
        sessionTitleCell.textAction = {
            [weak self] text in
            guard let self = self else { return }
            
            if text != nil && text!.isEmpty == false {
                self.profile.defaultSessionTitle = text!
                DataManager.saveContext()
            }
            else {
                self.sessionTitleCell.detailText = self.profile.defaultSessionTitle
            }
            
        }
        
        mergeProfileCell.action = {
            [weak self] in
            guard let self = self else { return }
            
            if CDProfile.getAllProfiles().count == 1 {
                let alert = ActionTrayPopupViewController(
                    title: "You only have one profile!", description: "You can merge profiles to combine multiple profiles into one.", cancelText: "Got it")
                self.presentPopupViewController(alert)
                return
            }
            else {
                let vc = MergeProfilesViewController(self.profile)
                self.presentModal(vc, animated: true, completion: nil)
            }
            
        }
        
        resetDataCell.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.stopEditing()
            
            let alert = ActionTrayPopupViewController(
                title: "Are you sure?",
                description: "This will permanently delete all practice and journal data from this profile, across all devices."
            )
            
            alert.addAction("Clear Data", isDestructive: true) { [weak self] in
                self?.clearData()
            }
            
            self.presentPopupViewController(alert)
            
        }
        
        deleteCell.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.stopEditing()
            
            if CDProfile.getAllProfiles().count == 1 {
                let alert = ActionTrayPopupViewController(
                    title: "You have to have at least one profile!", description: "If you want to reset the profile, you can tap Clear Data to start from a clean slate.", cancelText: "Got it")
                self.presentPopupViewController(alert)
                return
            }
            
            let alert = ActionTrayPopupViewController(
                title: "Are you sure?",
                description: "This will permanently delete the profile across all devices"
            )
            
            alert.addAction("Delete Profile", isDestructive: true) { [weak self] in
                guard let self = self else { return }
                
                //reminders are deleted by profile monitor
                
                if let parent = self.parent as? SettingsViewController {
                    var profiles = CDProfile.getAllProfiles()
                    if let index = profiles.firstIndex(of: self.profile) {
                        profiles.remove(at: index)
                        
                        if User.getActiveProfile() == self.profile {
                            parent.changeProfile(to: profiles[0])
                        }
                        
                        self.cancellables.removeAll()
                        
                        let context = DataManager.backgroundContext
                        if let profile = try? context.existingObject(with: self.profile.objectID) {
                            context.delete(profile)
                            try? context.save()
                        }
                        
                        if User.getActiveProfile() == nil {
                            parent.changeProfile(to: nil)
                        }
                        
                        self.close()
                        
                    }

                }
            
            }
            
            self.presentPopupViewController(alert)
            
        }
        
    }
    
    override func didTapSave() {
        self.goalButton.resignFirstResponder()
    }
    
    func pickerViewDidEndEditing(_ view: UIView) {
        self.setSaveButtonVisible(false)
        self.profile.dailyGoal = Int64(goalButton.value)
        DataManager.saveContext()
        WidgetDataManager.writeData()
    }
    
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)
        
        self.stopEditing()
        
    }
    
    private func clearData() {
        let loadingAlert = CenterLoadingViewController(style: .indefinite)
        self.present(loadingAlert, animated: false, completion: nil)
        
        let context = DataManager.backgroundContext
        let profileID = self.profile.objectID
        
        DispatchQueue.global(qos: .background).async {
            Thread.sleep(forTimeInterval: 1)
                        
            if let profile = try? context.existingObject(with: profileID) as? CDProfile {
                profile.clearData(context: context)
                try? context.save()
            }
            
            DispatchQueue.main.async {
                loadingAlert.close(success: true)
            }
            
        }
        
    }
    
    private func stopEditing() {
        nameCell.stopEditing()
        sessionTitleCell.stopEditing()
        goalButton.resignFirstResponder()
    }
    
    override func close(animated: Bool = true, completion: (() -> Void)? = nil) {
        self.stopEditing()
        super.close(animated: animated, completion: completion)
    }
    
    override func viewDidBeginDragging() {
        super.viewDidBeginDragging()
        self.stopEditing()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.goalButton.sizeToFit()
        self.goalButton.center = CGPoint(x: self.dailyGoalCell.bounds.maxX - Constants.margin - self.goalButton.bounds.width/2, y: self.dailyGoalCell.bounds.midY)
        
    }
    
}
