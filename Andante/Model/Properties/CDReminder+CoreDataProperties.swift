//
//  CDReminder+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 3/6/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDReminder {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDReminder> {
        return NSFetchRequest<CDReminder>(entityName: "CDReminder")
    }

    @NSManaged public var uuid: String?
    @NSManaged public var date: Date?
    @NSManaged public var isEnabled: Bool
    @NSManaged public var profileID: String?
    @NSManaged public var days: String?

}

extension CDReminder : Identifiable {

}
