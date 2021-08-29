//
//  CDOngoingSession+CoreDataProperties.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDOngoingSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDOngoingSession> {
        return NSFetchRequest<CDOngoingSession>(entityName: "CDOngoingSession")
    }

    @NSManaged public var start: Date?
    @NSManaged public var lastSave: Date?
    @NSManaged public var practiceTimeSeconds: Int64
    @NSManaged public var notes: String?
    @NSManaged public var recordingURLs: String?
    @NSManaged public var isPaused: Bool

}

extension CDOngoingSession : Identifiable {

}
