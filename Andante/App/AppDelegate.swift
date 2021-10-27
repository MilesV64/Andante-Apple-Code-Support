//
//  AppDelegate.swift
//  Andante
//
//  Created by Miles Vinson on 7/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications
import Combine
import os.log
import CloudKit

public let storeVersionNumber = "2.1.5"

public let StartPracticeSessionNotification = "Start Practice Session"
public let ResumeSessionInProgressNotification = "Resume Practice Session"

class User {
    public static let shared = User()
    
    private var activeProfile: CDProfile?
    private var activeFolders: [CDProfile : CDJournalFolder] = [:]
    
    public var isForcingSync = false
    
    /*
     Needs to be reloaded if profile is added/removed
     */
    public static func reloadData() {
        let profiles = CDProfile.getAllProfiles()
        
        if let activeProfileId = UserDefaults.standard.object(forKey: "activeProfile") as? String {
            User.shared.activeProfile = profiles.first { $0.uuid == activeProfileId }
        } else {
            if let profile = profiles.first {
                UserDefaults.standard.set(profile.uuid, forKey: "activeProfile")
                User.shared.activeProfile = profile
            }
        }
        
        for profile in profiles {
            User.shared.activeFolders[profile] = profile.getJournalFolders().first
        }
    }
    
    public static func setActiveProfile(_ profile: CDProfile?) {
        User.shared.activeProfile = profile
        
        UserDefaults.standard.set(profile?.uuid ?? "", forKey: "activeProfile")
    }
    
    public static func getActiveProfile() -> CDProfile? {
        return User.shared.activeProfile
    }
    
    /*
     Defaults to the first journal in the order, does not persist
     */
    public static func getActiveFolder(for profile: CDProfile?) -> CDJournalFolder? {
        guard let profile = profile else { return nil }
        
        if let folder = User.shared.activeFolders[profile] {
            return folder
        } else {
            let folder = profile.getJournalFolders().first
            User.shared.activeFolders[profile] = folder
            return folder
        }
    }
    
    /*
     Uses folder's relationship to profile
     */
    public static func setActiveFolder(_ folder: CDJournalFolder?) {
        if let folder = folder, let profile = folder.profile {
            User.shared.activeFolders[profile] = folder
        }
    }
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UNUserNotificationCenter.current().delegate = self
        
        IAPHelper.shared.startObserving()
        IAPHelper.shared.fetchProducts()
        
        setupData()
                
        WidgetDataManager.writeData()
        
        clearTempDirectoryIfNeeded()
        
        logSession()
        
        handleVersionUpdates()
        
        ProfileMonitor.shared.monitorProfiles()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadWidget), name: ProfileMonitor.ProfilesDidChangeNotification, object: nil)
        
        CDReminder.updateReminders()
        
        present()
        
        return true
    }
    
    private func clearTempDirectoryIfNeeded() {
        var deleteCount = 0
        
        do {
            let directory = FileManager.default.temporaryDirectory
            
            for path in try FileManager.default.contentsOfDirectory(atPath: directory.path) {
                do {
                    let fileURL = directory.appendingPathComponent(path)
                    let fileExtension = fileURL.pathExtension
                    if ["png", "jpeg", "m4a", "mp4"].contains(fileExtension) {
                        try FileManager.default.removeItem(at: directory.appendingPathComponent(path))
                        deleteCount += 1
                    }
                } catch {
                    print(error)
                }
            }
        }
        catch {
            print(error)
        }
        
        if deleteCount > 0 {
            print("Deleted \(deleteCount) item(s) from the temporary directory.")
        }
    }
    
    @objc func reloadWidget() {
        WidgetDataManager.writeData()
    }
    
    private func setupData() {
        
        User.reloadData()
        
    }
    
    private func deleteStore() {
        //DANGER DANGER DANGER
        
        if let store = DataManager.shared.container.persistentStoreCoordinator.persistentStores.first {
            let url = DataManager.shared.container.persistentStoreCoordinator.url(for: store)
            do {
                try DataManager.shared.container.persistentStoreCoordinator.destroyPersistentStore(
                    at: url, ofType: store.type, options: nil)
            }
            catch {
                print(error)
            }
        }
    }
    
    private func present() {
        let launchView = LaunchView()
        window?.rootViewController?.view.addSubview(launchView)
        window?.makeKeyAndVisible()
        // avoiding: Unbalanced calls to begin/end appearance transitions.
        DispatchQueue.global().async {
            DispatchQueue.main.async {
                if CDProfile.getAllProfiles().count == 0 {
                    launchView.checkForCloudData { (foundData) in
                        if foundData {
                            User.reloadData()
                            UIView.animate(withDuration: 0.25, delay: 0.2, options: [], animations: {
                                launchView.alpha = 0
                                launchView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                            }) { (complete) in
                                if let vc = self.window?.rootViewController as? AndanteViewController {
                                    vc.didChangeProfile(User.getActiveProfile())
                                    vc.animate()
                                }
                                launchView.removeFromSuperview()
                            }
                        }
                        else {
                            //doesn't animate properly
                            let onboardingVC = OnboardingViewController()
                            self.window?.rootViewController?.present(onboardingVC, animated: false, completion: {
                                UIView.animate(withDuration: 0.45, delay: 0, options: [], animations: {
                                    onboardingVC.view.addSubview(launchView)
                                    launchView.alpha = 0
                                }) { (complete) in
                                    launchView.removeFromSuperview()
                                }
                            })
                        }
                    }
                }
                else {
                    UIView.animate(withDuration: 0.25, delay: 0.2, options: [], animations: {
                        launchView.alpha = 0
                        launchView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    }) { (complete) in
                        launchView.removeFromSuperview()
                        if let vc = self.window?.rootViewController as? AndanteViewController {
                            vc.animate()
                        }
                    }
                }
                
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        logSession()
        CDReminder.updateReminders()
    }
    
    private func logSession() {
        CDAskForRatingTracker.logSession()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let urlComponents = url.absoluteString.split(separator: ":")
        guard urlComponents.count == 2 else { return false }
        
        if urlComponents[0] == "AndanteWidget" {
            let profileID = urlComponents[1]
            if let profile = CDProfile.getAllProfiles().first(where: { (profile) -> Bool in
                return profileID == (profile.uuid ?? "")
            }) {
                if let container = app.windows.first?.rootViewController as? AndanteViewController {
                    container.changeProfileFromWidget(to: profile)
                }
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        if let profile = CDProfile.getAllProfiles().first(where: { (profile) -> Bool in
            return profile.uuid == userActivity.persistentIdentifier
        }) {
            
            guard
                let container = application.windows.first?.rootViewController as? AndanteViewController,
                container.isPracticing == false
            else { return true }
            
            showPlaceholderPracticeWindow()
            
            for window in application.windows {
                if let vc = window.rootViewController as? PopupMenuViewController {
                    vc.hide(animated: false)
                }
            }
            
            container.handleSiriStart(profile: profile) {
                self.hidePlaceholderPracticeWindow()
            }
            
            
        }
        
        return true
    }
    
    private var placeholderPracticeWindow: UIWindow?
    private func showPlaceholderPracticeWindow() {
        
        let vc = UIViewController()
        vc.view.backgroundColor = PracticeColors.background
        
        placeholderPracticeWindow = UIWindow(frame: window!.frame)
        placeholderPracticeWindow?.rootViewController = vc
        placeholderPracticeWindow?.windowLevel = .alert + 1
        placeholderPracticeWindow?.makeKeyAndVisible()
    }
    
    private func hidePlaceholderPracticeWindow() {
        placeholderPracticeWindow = nil
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        if notification.request.content.categoryIdentifier == "reminder" {
            completionHandler([.sound, .alert])
        } else {
            completionHandler([.sound, .alert])
        }
        
        CDReminder.updateReminders()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        IAPHelper.shared.stopObserving()
    }

    private func handleVersionUpdates() {
        
        if UserVersion.current != "0.0.0" {
//            if UserVersion.isOlderThan("2.0.0") {
//                UserVersion.shouldShowWhatsNew = true
//            }

            VersionUpdates.fixDefaultFoldersIfNeeded()
            
        }
    
        UserVersion.current = storeVersionNumber
        
    }

}


//MARK: - Monitor reminders/profiles
class ProfileMonitor: NSObject, NSFetchedResultsControllerDelegate {
    public static var shared = ProfileMonitor()
    
    public static let ProfilesDidChangeNotification = Notification.Name("ProfilesDidChange")
    public static let DidDeleteActiveProfileNotification = Notification.Name("DidDeleteProfile")
    
    private var controller: NSFetchedResultsController<CDProfile>!
    private var cancellables: [ String : Set<AnyCancellable> ] = [:]
    
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
            NotificationCenter.default.post(name: ProfileMonitor.ProfilesDidChangeNotification, object: nil)
            monitor(profile: profile)
        }
        else if type == .delete {
            guard let profile = anObject as? CDProfile, let uuid = profile.uuid else { return }
            cancellables[uuid]?.removeAll()
            self.deleteReminders(with: profile.uuid ?? "")
            
            NotificationCenter.default.post(name: ProfileMonitor.ProfilesDidChangeNotification, object: nil)
            
            if profile == User.getActiveProfile() {
                NotificationCenter.default.post(name: ProfileMonitor.DidDeleteActiveProfileNotification, object: nil)
            }
        }
    }
    
    /**
     Monitors profiles for changes/deletions and updates reminders accordingly
     */
    public func monitorProfiles() {
        
        try? controller.performFetch()
        
        guard let profiles = controller.fetchedObjects else { return }
        
        profiles.forEach { profile in
            self.monitor(profile: profile)
        }
        
    }
    
    private func monitor(profile: CDProfile) {
        guard let uuid = profile.uuid else { return }
        
        cancellables[uuid] = Set<AnyCancellable>()
        
        let originalName = profile.name
        profile.publisher(for: \.name, options: .new).sink { name in
            guard name != nil, name != originalName else { return }
            self.reloadReminders(with: profile.uuid ?? "")
            NotificationCenter.default.post(name: ProfileMonitor.ProfilesDidChangeNotification, object: nil)
        }.store(in: &cancellables[uuid]!)
        
        let originalIconName = profile.iconName
        profile.publisher(for: \.iconName, options: .new).sink { name in
            guard name != nil, name != originalIconName else { return }
            NotificationCenter.default.post(name: ProfileMonitor.ProfilesDidChangeNotification, object: nil)
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
