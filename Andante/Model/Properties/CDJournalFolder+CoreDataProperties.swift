//
//  CDJournalFolder+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDJournalFolder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDJournalFolder> {
        return NSFetchRequest<CDJournalFolder>(entityName: "CDJournalFolder")
    }

    @NSManaged public var index: Int64
    @NSManaged public var isDefaultFolder: Bool
    @NSManaged public var title: String?
    @NSManaged public var entries: NSSet?
    @NSManaged public var profile: CDProfile?

}

// MARK: Generated accessors for entries
extension CDJournalFolder {

    @objc(addEntriesObject:)
    @NSManaged public func addToEntries(_ value: CDJournalEntry)

    @objc(removeEntriesObject:)
    @NSManaged public func removeFromEntries(_ value: CDJournalEntry)

    @objc(addEntries:)
    @NSManaged public func addToEntries(_ values: NSSet)

    @objc(removeEntries:)
    @NSManaged public func removeFromEntries(_ values: NSSet)

}

extension CDJournalFolder : Identifiable {

}
