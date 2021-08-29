//
//  CDAskForRatingTracker+CoreDataProperties.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDAskForRatingTracker {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAskForRatingTracker> {
        return NSFetchRequest<CDAskForRatingTracker>(entityName: "CDAskForRatingTracker")
    }

    @NSManaged public var sessions: Int64
    @NSManaged public var uniqueDays: Int64
    @NSManaged public var lastSessionDate: Date?

}
