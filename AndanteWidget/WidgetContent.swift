//
//  WidgetContent.swift
//  Andante
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import WidgetKit

struct WidgetContent: Codable, TimelineEntry {
    var date = Date()
    
    let profileID: String
    let profileName: String
    let profileIcon: String
    let weekdays: [String]
    let progress: [Double]
    let practiceToday: String
    
}
