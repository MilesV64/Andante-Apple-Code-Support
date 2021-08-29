//
//  StatDataSource.swift
//  Andante
//
//  Created by Miles Vinson on 8/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Foundation
import CoreData

protocol StatDataSource {
    
    func reloadBlock() -> StatsViewController.ReloadBlock
    
}
