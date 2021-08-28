//
//  CDProfile+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDProfile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDProfile> {
        return NSFetchRequest<CDProfile>(entityName: "CDProfile")
    }

    @NSManaged public var creationDate: Date?
    @NSManaged public var dailyGoal: Int64
    @NSManaged public var defaultSessionTitle: String?
    @NSManaged public var iconName: String?
    @NSManaged public var name: String?
    @NSManaged public var uuid: String?
    @NSManaged public var journalFolders: NSSet?
    @NSManaged public var sessions: NSSet?

}

// MARK: Generated accessors for journalFolders
extension CDProfile {

    @objc(addJournalFoldersObject:)
    @NSManaged public func addToJournalFolders(_ value: CDJournalFolder)

    @objc(removeJournalFoldersObject:)
    @NSManaged public func removeFromJournalFolders(_ value: CDJournalFolder)

    @objc(addJournalFolders:)
    @NSManaged public func addToJournalFolders(_ values: NSSet)

    @objc(removeJournalFolders:)
    @NSManaged public func removeFromJournalFolders(_ values: NSSet)

}

// MARK: Generated accessors for sessions
extension CDProfile {

    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: CDSession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: CDSession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)

}

extension CDProfile : Identifiable {

}
