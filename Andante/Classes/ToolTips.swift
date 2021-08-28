//
//  ToolTips.swift
//  Andante
//
//  Created by Miles Vinson on 8/13/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Foundation

class ToolTips {
    
    fileprivate static let notesID = "Notes"
    fileprivate static let sessionsID = "Sessions"
    fileprivate static let goalID = "Goal"
    
    class var didShowNotesTooltip: Bool {
        set {
            ToolTips.setTooltip(id: ToolTips.notesID, value: newValue)
        }
        get {
            if let value = ToolTips.getTooltip(id: ToolTips.notesID) {
                return value as! Bool
            }
            else {
                ToolTips.setTooltip(id: ToolTips.notesID, value: false)
                return false
            }
        }
    }
    
    class var didShowSessionsTooltip: Bool {
        set {
            ToolTips.setTooltip(id: ToolTips.sessionsID, value: newValue)
        }
        get {
            if let value = ToolTips.getTooltip(id: ToolTips.sessionsID) {
                return value as! Bool
            }
            else {
                ToolTips.setTooltip(id: ToolTips.sessionsID, value: false)
                return false
            }
        }
    }
    
    class var didShowGoalTooltip: Bool {
        set {
            ToolTips.setTooltip(id: ToolTips.goalID, value: newValue)
        }
        get {
            if let value = ToolTips.getTooltip(id: ToolTips.goalID) {
                return value as! Bool
            }
            else {
                ToolTips.setTooltip(id: ToolTips.goalID, value: false)
                return false
            }
        }
    }
    
    fileprivate class func setTooltip(id: String, value: Any?) {
        UserDefaults.standard.set(value, forKey: id)
    }
    
    fileprivate class func getTooltip(id: String) -> Any? {
        return UserDefaults.standard.object(forKey: id)
    }
    
}
