//
//  ProfileManager.swift
//  Andante
//
//  Created by Miles on 10/26/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import Foundation
import CoreData
import Combine

@objc protocol ProfileObserver: AnyObject {
    @objc optional func profileManager(_ profileManager: ProfileManager, didAddProfile profile: CDProfile)
    @objc optional func profileManager(_ profileManager: ProfileManager, didDeleteProfile profile: CDProfile)
}

class ProfileManager: NSObject, NSFetchedResultsControllerDelegate {
    public static var shared = ProfileManager()
    
    private var controller: NSFetchedResultsController<CDProfile>!
    private var cancellables: [ String : Set<AnyCancellable> ] = [:]
    
    fileprivate class WeakProfileObserver {
        private(set) weak var value: ProfileObserver?
        
        init(value: ProfileObserver?) {
            self.value = value
        }
    }
    
    private var observers : [WeakProfileObserver] = []
    
    func addObserver(_ observer: ProfileObserver) {
        self.observers = self.observers.filter({ $0.value != nil }) // Trim
        self.observers.append( WeakProfileObserver(value: observer)  ) // Append
    }
    
    func removeObserver(_ observer: ProfileObserver) {
        self.observers = self.observers.filter({
            guard let value = $0.value else { return false }
            return !(value === observer)
        })
    }
    
    override init() {
        super.init()
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        let sort = NSSortDescriptor(key: #keyPath(CDProfile.creationDate), ascending: true)
        request.sortDescriptors = [sort]
        
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: nil, cacheName: nil)
        
        controller.delegate = self
        
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        if type == .insert {
            guard let profile = anObject as? CDProfile else { return }
            
            self.observers.forEach { $0.value?.profileManager?(self, didAddProfile: profile) }
            
            monitor(profile: profile)
        }
        else if type == .delete {
            guard let profile = anObject as? CDProfile, let uuid = profile.uuid else { return }
            
            self.cancellables[uuid]?.removeAll()
            self.deleteReminders(with: profile.uuid ?? "")
            
            self.observers.forEach { $0.value?.profileManager?(self, didDeleteProfile: profile) }
        }
    }
    
    /**
     Monitors profiles for changes/deletions and updates reminders accordingly
     */
    public func beginObserving() {
        
        try? controller.performFetch()
        
        guard let profiles = controller.fetchedObjects else { return }
        
        profiles.forEach { profile in
            self.monitor(profile: profile)
        }
        
    }
    
    private func monitor(profile: CDProfile) {
        guard let uuid = profile.uuid else { return }
        
        cancellables[uuid] = Set<AnyCancellable>()
        
        profile.publisher(for: \.name, options: .new).sink { name in
            guard name != nil else { return }
            self.reloadReminders(with: profile.uuid ?? "")
            WidgetDataManager.writeData()
        }.store(in: &cancellables[uuid]!)
        
        profile.publisher(for: \.iconName, options: .new).sink { iconName in
            guard iconName != nil else { return }
            WidgetDataManager.writeData()
        }.store(in: &cancellables[uuid]!)
    }
    
    private func reloadReminders(with profileID: String) {
        for reminder in CDReminder.getAllReminders() {
            if reminder.profileID == profileID {
                reminder.scheduleNotification()
            }
        }
    }
    
    private func deleteReminders(with profileID: String) {
        //Check existing IDs to see if the reminder should really be deleted, such as in the case of a force sync where profiles are deleted and replaced by duplicates.
        
        let existingProfileIDs = CDProfile.getAllProfiles().compactMap { $0.uuid }
        
        for reminder in CDReminder.getAllReminders() {
            if let reminderProfileID = reminder.profileID {
                if !existingProfileIDs.contains(reminderProfileID) {
                    reminder.unscheduleNotification()
                    DataManager.context.delete(reminder)
                }
            }
            else {
                reminder.unscheduleNotification()
                DataManager.context.delete(reminder)
            }
        }
        
        DataManager.saveContext()

    }
    
}

