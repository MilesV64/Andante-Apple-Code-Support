//
//  CDTextEditorEntry+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 4/12/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDTextEditorEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTextEditorEntry> {
        return NSFetchRequest<CDTextEditorEntry>(entityName: "CDTextEditorEntry")
    }

    @NSManaged public var blocks: NSSet?
    @NSManaged public var journalEntry: CDJournalEntry?
    @NSManaged public var session: CDSession?

}

// MARK: Generated accessors for blocks
extension CDTextEditorEntry {

    @objc(addBlocksObject:)
    @NSManaged public func addToBlocks(_ value: CDTextEditorBlock)

    @objc(removeBlocksObject:)
    @NSManaged public func removeFromBlocks(_ value: CDTextEditorBlock)

    @objc(addBlocks:)
    @NSManaged public func addToBlocks(_ values: NSSet)

    @objc(removeBlocks:)
    @NSManaged public func removeFromBlocks(_ values: NSSet)

}

extension CDTextEditorEntry : Identifiable {

}
