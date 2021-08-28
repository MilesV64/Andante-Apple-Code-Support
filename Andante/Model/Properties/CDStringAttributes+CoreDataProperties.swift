//
//  CDStringAttributes+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDStringAttributes {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStringAttributes> {
        return NSFetchRequest<CDStringAttributes>(entityName: "CDStringAttributes")
    }

    @NSManaged public var length: Int64
    @NSManaged public var location: Int64
    @NSManaged public var value: Int64
    @NSManaged public var entry: CDJournalEntry?

}

extension CDStringAttributes : Identifiable {

}
