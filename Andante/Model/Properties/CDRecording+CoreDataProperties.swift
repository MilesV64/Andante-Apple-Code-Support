//
//  CDRecording+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDRecording {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRecording> {
        return NSFetchRequest<CDRecording>(entityName: "CDRecording")
    }

    @NSManaged public var index: Int64
    @NSManaged public var recordingData: Data?
    @NSManaged public var session: CDSession?

}

extension CDRecording : Identifiable {

}
