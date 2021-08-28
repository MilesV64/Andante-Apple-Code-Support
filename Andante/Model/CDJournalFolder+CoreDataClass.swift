//
//  CDJournalFolder+CoreDataClass.swift
//  
//
//  Created by Miles Vinson on 2/7/21.
//
//

import Foundation
import CoreData

@objc(CDJournalFolder)
public class CDJournalFolder: NSManagedObject {
    
    func getEntries() -> [CDJournalEntry] {
        guard let entries = entries as? Set<CDJournalEntry> else { return [] }
        return Array(entries.sorted(by: { (f1, f2) -> Bool in
            return f1.index < f2.index
        }))
    }

    /**
     Updates the indexes of the saved entries to match the order of the given array. Does not add or remove indexes
     */
    func updateEntryOrder(toMatch entries: [CDJournalEntry]) {
        for (i, entry) in entries.enumerated() {
            entry.index = Int64(i)
        }
    }
    
    func duplicate(context: NSManagedObjectContext? = nil) -> CDJournalFolder {
        
        let newFolder = CDJournalFolder(context: context ?? DataManager.context)
        if context != nil {
            DataManager.obtainPermanentID(for: newFolder)
        }
        
        newFolder.title = title
        newFolder.index = index
        newFolder.isDefaultFolder = isDefaultFolder
        
        for entry in self.entries as? Set<CDJournalEntry> ?? [] {
            let newEntry = entry.duplicate(context: context)
            newFolder.addToEntries(newEntry)
        }
        
        return newFolder
    }
    
}
