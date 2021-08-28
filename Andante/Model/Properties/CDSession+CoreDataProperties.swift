//
//  CDSession+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 4/12/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSession> {
        return NSFetchRequest<CDSession>(entityName: "CDSession")
    }

    @NSManaged public var d_focus: Int64
    @NSManaged public var d_mood: Int64
    @NSManaged public var d_practiceTime: Int64
    @NSManaged public var d_startTime: Date?
    @NSManaged public var end: Date?
    @NSManaged public var isFavorited: Bool
    @NSManaged public var notes: String?
    @NSManaged public var sectionName: String?
    @NSManaged public var title: String?
    @NSManaged public var totalTime: Int64
    @NSManaged public var attributes: CDSessionAttributes?
    @NSManaged public var profile: CDProfile?
    @NSManaged public var recordings: NSSet?
    @NSManaged public var textEditorEntry: CDTextEditorEntry?

}

// MARK: Generated accessors for recordings
extension CDSession {

    @objc(addRecordingsObject:)
    @NSManaged public func addToRecordings(_ value: CDRecording)

    @objc(removeRecordingsObject:)
    @NSManaged public func removeFromRecordings(_ value: CDRecording)

    @objc(addRecordings:)
    @NSManaged public func addToRecordings(_ values: NSSet)

    @objc(removeRecordings:)
    @NSManaged public func removeFromRecordings(_ values: NSSet)

}

extension CDSession : Identifiable {

}
