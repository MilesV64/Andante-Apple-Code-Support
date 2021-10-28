//
//  CDProfile+CoreDataClass.swift
//  
//
//  Created by Miles Vinson on 2/7/21.
//
//

import Foundation
import CoreData

@objc(CDProfile)
public class CDProfile: NSManagedObject {
    
    class func getAllProfiles(context: NSManagedObjectContext? = nil) -> [CDProfile] {
        let ctx = context ?? DataManager.context
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        request.sortDescriptors = [sort]
        
        do {
            return try ctx.fetch(request)
        } catch {
            print(error)
            return []
        }
    }
    
    class func saveProfile(_ profile: CDProfile) {
        
        profile.dailyGoal = 15
        profile.creationDate = Date()
        
        profile.uuid = UUID().uuidString
        
        let defaultFolder = CDJournalFolder(context: DataManager.context)
        DataManager.obtainPermanentID(for: defaultFolder)
        defaultFolder.title = "Entries"
        defaultFolder.isDefaultFolder = true
        profile.addToJournalFolders(defaultFolder)
                
    }
    
    func clearData(context: NSManagedObjectContext) {
        (journalFolders as? Set<CDJournalFolder>)?.forEach({ (folder) in
            if folder.isDefaultFolder == false {
                removeFromJournalFolders(folder)
                context.delete(folder)
            } else {
                (folder.entries as? Set<CDJournalEntry>)?.forEach({ (entry) in
                    folder.removeFromEntries(entry)
                    context.delete(entry)
                })
                folder.index = 0
            }
        })
                
        (sessions as? Set<CDSession>)?.forEach({ (session) in
            removeFromSessions(session)
            context.delete(session)
        })
        
    }
    
    /// Returns the sum of each profile's daily goal
    class func getTotalDailyGoal() -> Int {
        return CDProfile.getAllProfiles().reduce(0, { $0 + Int($1.dailyGoal) })
    }
    
    /// Returns the earliest creation date of all profiles
    class func getEarliestCreationDate() -> Date {
        var date = Date()
        CDProfile.getAllProfiles().forEach {
            if let profileDate = $0.creationDate, profileDate < date {
                date = profileDate
            }
        }
        return date
    }
    
    public func getSiriActivity() -> NSUserActivity {
        let actionIdentifier = "\(self.uuid ?? "")"
        let activity = NSUserActivity(activityType: actionIdentifier)
        activity.title = "Start Practicing \(self.name ?? "")"
        activity.suggestedInvocationPhrase = "Start practicing \((self.name ?? "").lowercased())"
        activity.userInfo = ["speech":"\(actionIdentifier)"]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        activity.persistentIdentifier = NSUserActivityPersistentIdentifier(actionIdentifier)
        return activity
    }
    
    public func duplicate(context: NSManagedObjectContext? = nil) -> CDProfile {
        let profile = CDProfile(context: context ?? DataManager.context)
        if context != nil {
            DataManager.obtainPermanentID(for: profile)
        }
        
        profile.uuid = self.uuid
        profile.name = self.name
        profile.iconName = self.iconName
        profile.dailyGoal = self.dailyGoal
        profile.creationDate = self.creationDate
        profile.defaultSessionTitle = self.defaultSessionTitle
        
        for session in self.sessions as? Set<CDSession> ?? [] {
            profile.addToSessions(session.duplicate(context: context))
        }
        
        for folder in self.journalFolders as? Set<CDJournalFolder> ?? [] {
            profile.addToJournalFolders(folder.duplicate(context: context))
        }
        
        return profile
        
    }
    
    
    
    
}

//MARK: - Sessions
extension CDProfile {
    
    func getSessions() -> [CDSession] {
        guard let sessions = sessions as? Set<CDSession> else { return [] }
        return Array(sessions.sorted(by: { (f1, f2) -> Bool in
            return f1.startTime > f2.startTime
        }))
    }
    
    
}


//MARK: - Journal
extension CDProfile {
    
    func getDefaultFolder() -> CDJournalFolder? {
        guard let folders = journalFolders as? Set<CDJournalFolder> else { return nil }
        return folders.first(where: { $0.isDefaultFolder })
    }
    
    func getJournalFolders() -> [CDJournalFolder] {
        guard let folders = journalFolders as? Set<CDJournalFolder> else { return [] }
        return Array(folders.sorted(by: { (f1, f2) -> Bool in
            return f1.index < f2.index
        }))
    }
    
    func addJournalFolder(_ folder: CDJournalFolder) {
        var folders = getJournalFolders()
        folders.append(folder)
        updateFolderOrder(toMatch: folders)
        addToJournalFolders(folder)
    }
    
    /**
     Updates the indexes of the saved folders to match the order of the given array. Does not add or remove indexes
     */
    func updateFolderOrder(toMatch folders: [CDJournalFolder]) {
        for (i, folder) in folders.enumerated() {
            folder.index = Int64(i)
        }
    }
    
}

func firstIndex(of session: CDSession, in sessions: [CDSession]?) -> Int? {
    guard let sessions = sessions else { return nil }
    var lo = 0
    var hi = sessions.count - 1
    while lo <= hi {
        let mid = (lo + hi)/2
        if sessions[mid].startTime > session.startTime {
            lo = mid + 1
        }
        else if sessions[mid].startTime < session.startTime {
            hi = mid - 1
        }
        else {
            //found position at mid, check if equal
            if session == sessions[mid] {
                return mid
            }
            
            //need to now check if there are duplicate dates, and find the correct id
            
            lo = mid - 1
            while lo >= 0 && sessions[lo].startTime == session.startTime {
                if session == sessions[lo] {
                    return lo
                }
                lo -= 1
            }
            
            hi = mid + 1
            while hi < sessions.count && sessions[hi].startTime == session.startTime {
                if session == sessions[hi] {
                    return hi
                }
                hi += 1
            }
            
            return nil // this is probably impossible
        }
    }
    return nil
}

func insertionIndex(of session: CDSession, in sessionList: [CDSession]) -> Int {
    var lo = 0
    var hi = sessionList.count - 1
    while lo <= hi {
        let mid = (lo + hi)/2
        if sessionList[mid].startTime > session.startTime {
            lo = mid + 1
        }
        else if sessionList[mid].startTime < session.startTime {
            hi = mid - 1
        }
        else {
            return mid // found at position mid
        }
    }
    return lo
}

extension Array {
    func firstIndex(of elem: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int? {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], elem) {
                lo = mid + 1
            } else if isOrderedBefore(elem, self[mid]) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return nil
    }
    
}

extension PracticeDay {
    
    static func index(of day: Day, in practiceDays: [PracticeDay]) -> Int? {
        var lo = 0
        var hi = practiceDays.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if day.isBefore(practiceDays[mid].day) {
                lo = mid + 1
            } else if practiceDays[mid].day.isBefore(day) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return nil
    }
    
    static func insertionIndex(of day: Day, in practiceDays: [PracticeDay]) -> Int {
        var lo = 0
        var hi = practiceDays.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if day.isBefore(practiceDays[mid].day) {
                lo = mid + 1
            } else if practiceDays[mid].day.isBefore(day) {
                hi = mid - 1
            } else {
                return mid // found at position mid
            }
        }
        return lo
    }
    
}
