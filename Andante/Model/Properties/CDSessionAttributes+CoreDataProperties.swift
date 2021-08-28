//
//  CDSessionAttributes+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDSessionAttributes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDSessionAttributes> {
        return NSFetchRequest<CDSessionAttributes>(entityName: "CDSessionAttributes")
    }

    @NSManaged public var startTime: Date?
    @NSManaged public var practiceTime: Int64
    @NSManaged public var mood: Int64
    @NSManaged public var focus: Int64
    @NSManaged public var session: CDSession?

}

extension CDSessionAttributes : Identifiable {

}
