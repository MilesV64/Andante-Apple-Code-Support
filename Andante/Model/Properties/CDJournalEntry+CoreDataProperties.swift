//
//  CDJournalEntry+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 4/12/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDJournalEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDJournalEntry> {
        return NSFetchRequest<CDJournalEntry>(entityName: "CDJournalEntry")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var editDate: Date?
    @NSManaged public var index: Int64
    @NSManaged public var string: String?
    @NSManaged public var attributes: NSSet?
    @NSManaged public var folder: CDJournalFolder?
    @NSManaged public var textEditorEntry: CDTextEditorEntry?

}

// MARK: Generated accessors for attributes
extension CDJournalEntry {

    @objc(addAttributesObject:)
    @NSManaged public func addToAttributes(_ value: CDStringAttributes)

    @objc(removeAttributesObject:)
    @NSManaged public func removeFromAttributes(_ value: CDStringAttributes)

    @objc(addAttributes:)
    @NSManaged public func addToAttributes(_ values: NSSet)

    @objc(removeAttributes:)
    @NSManaged public func removeFromAttributes(_ values: NSSet)

}

extension CDJournalEntry : Identifiable {

}
