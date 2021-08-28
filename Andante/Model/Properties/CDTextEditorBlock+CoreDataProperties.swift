//
//  CDTextEditorBlock+CoreDataProperties.swift
//  Andante
//
//  Created by Miles Vinson on 4/12/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData


extension CDTextEditorBlock {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDTextEditorBlock> {
        return NSFetchRequest<CDTextEditorBlock>(entityName: "CDTextEditorBlock")
    }

    @NSManaged public var index: Int64
    @NSManaged public var text: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var videoData: Data?
    @NSManaged public var textStyle: Int64
    @NSManaged public var aspectRatio: Float
    @NSManaged public var textEditorEntry: CDTextEditorEntry?

}

extension CDTextEditorBlock : Identifiable {

}
