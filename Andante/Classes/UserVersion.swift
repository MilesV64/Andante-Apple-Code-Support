//
//  UserVersion.swift
//  Andante
//
//  Created by Miles Vinson on 11/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//


import Foundation

class UserVersion {
    
    fileprivate static let id = "UserVersion"
    fileprivate static let showWhatsNewID = "ShowWhatsNew"
    
    class var current: String {
        set {
            UserDefaults.standard.set(newValue, forKey: id)
        }
        get {
            if let value = UserDefaults.standard.object(forKey: id) {
                return value as! String
            }
            else {
                UserDefaults.standard.set("0.0.0", forKey: id)
                return "0.0.0"
            }
        }
    }
    
    class var shouldShowWhatsNew: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: showWhatsNewID)
        }
        get {
            if let value = UserDefaults.standard.object(forKey: showWhatsNewID) {
                return value as! Bool
            }
            else {
                UserDefaults.standard.set(false, forKey: showWhatsNewID)
                return false
            }
        }
    }
    
    class func isOlderThan(_ version: String) -> Bool {
        let currentNumbers = UserVersion.current.split(separator: ".").map { Int($0)! }
        let compareNumbers = version.split(separator: ".").map { Int($0)! }
        
        if currentNumbers[0] > compareNumbers[0] {
            return false
        } else if currentNumbers[0] < compareNumbers[0] {
            return true
        } else {
            if currentNumbers[1] > compareNumbers[1] {
                return false
            } else if currentNumbers[1] < compareNumbers[1] {
                return true
            } else {
                if currentNumbers[2] > compareNumbers[2] {
                    return false
                } else if currentNumbers[2] < compareNumbers[2] {
                    return true
                } else {
                    return false
                }
            }
        }
    }
    
}

class VersionUpdates {
    
    private static func IsUpdateNeeded(id: String) -> Bool {
        return UserDefaults.standard.value(forKey: id) as? Bool ?? true
    }
    
    private static func SetDidUpdate(id: String) {
        UserDefaults.standard.setValue(false, forKey: id)
    }
    
    /*
     Bug that happened during the iCloud update that caused some users to have a duplicated default folder that they can't edit/delete.
     */
    static func fixDefaultFoldersIfNeeded() {
        let id = "FixDuplicateDefaultFolders"
        
        guard IsUpdateNeeded(id: id) else { return }
        
        let context = DataManager.backgroundContext
        for profile in CDProfile.getAllProfiles(context: context) {
            
            let folders = profile.getJournalFolders()
            
            var defaultFolders: [CDJournalFolder] = []
            for folder in folders {
                if folder.isDefaultFolder {
                    defaultFolders.append(folder)
                }
            }
            
            if defaultFolders.count > 1 {
                let first = defaultFolders[0]
                var entries = first.getEntries()
                for i in 1..<defaultFolders.count {
                    for entry in defaultFolders[i].getEntries() {
                        let duplicate = entry.duplicate(context: context)
                        entries.append(duplicate)
                        first.addToEntries(duplicate)
                    }
                    profile.removeFromJournalFolders(defaultFolders[i])
                    context.delete(defaultFolders[i])
                }
                first.updateEntryOrder(toMatch: entries)
            }
        }
        
        if context.hasChanges {
            try? context.save()
        }
        
        SetDidUpdate(id: id)
            
    }
}
