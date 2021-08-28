//
//  Settings.swift
//  Andante
//
//  Created by Miles Vinson on 8/7/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import Foundation

class Settings {
    
    fileprivate static let premiumID = "Premium"
    fileprivate static let darkModeID = "DarkMode"
    fileprivate static let reduceMotionID = "ReduceMotion"
    fileprivate static let standardTimeID = "StandardTime"
    fileprivate static let didShowOnboardID = "DidShowOnBoard"
    fileprivate static let showTipsID = "ShowTips"
    fileprivate static let practiceTimerID = "PracticeTimer"
    fileprivate static let showCountDownID = "ShowCountdown"
    fileprivate static let timerSoundID = "TimerSound"
    fileprivate static let weekStartID = "WeekStart"
    fileprivate static let appearanceID = "Appearance"
    fileprivate static let needsUpdateID = "NeedsUpdate"
    fileprivate static let journalLayoutID = "JournalLayout"
    fileprivate static let includeNotesInExportID = "IncludeNotes"
    
    fileprivate static let journalSortOptionID = "JournalSortOption"
    
    fileprivate static let defaultPracticeTitleID = "DefaultPracticeTitle"
    
    fileprivate static let tunerTrialID = "TunerTrial"
    
    class var includeNotesInExport: Bool {
        set {
            Settings.setSetting(id: Settings.includeNotesInExportID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.includeNotesInExportID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.includeNotesInExportID, value: false)
                return false
            }
        }
    }

    class var didTryTuner: Bool {
        set {
            Settings.setSetting(id: Settings.tunerTrialID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.tunerTrialID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.tunerTrialID, value: false)
                return false
            }
        }
    }
    
    class var darkMode: Bool {
        set {
            Settings.setSetting(id: Settings.darkModeID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.darkModeID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.darkModeID, value: false)
                return false
            }
        }
    }
    
    enum Appearance {
        case light, dark, system
    }
    
    class var appearance: Settings.Appearance {
        set {
            if newValue == .light {
                Settings.setSetting(id: Settings.appearanceID, value: 0)
            }
            else if newValue == .dark {
                Settings.setSetting(id: Settings.appearanceID, value: 1)
            }
            else {
                Settings.setSetting(id: Settings.appearanceID, value: 2)
            }
        }
        get {
            if let value = Settings.getSetting(id: Settings.appearanceID) as? Int {
                if value == 0 {
                    return .light
                }
                else if value == 1 {
                    return .dark
                }
                else {
                    return .system
                }
            }
            else {
                Settings.setSetting(id: Settings.appearanceID, value: 2)
                return .system
            }
        }
    }
    
    class var journalLayout: JournalViewController.EntryLayout {
        set {
            if newValue == .list {
                Settings.setSetting(id: Settings.journalLayoutID, value: 0)
            }
            else if newValue == .grid {
                Settings.setSetting(id: Settings.journalLayoutID, value: 1)
            }
        }
        get {
            if let value = Settings.getSetting(id: Settings.journalLayoutID) as? Int {
                if value == 0 {
                    return .list
                }
                else {
                    return .grid
                }
            }
            else {
                Settings.setSetting(id: Settings.journalLayoutID, value: 0)
                return .list
            }
        }
    }
    
    enum WeekStart {
        case monday, sunday
    }
    
    class var weekStart: Settings.WeekStart {
        set {
            if newValue == .monday {
                Settings.setSetting(id: Settings.weekStartID, value: 0)
            }
            else {
                Settings.setSetting(id: Settings.weekStartID, value: 1)
            }
        }
        get {
            if let value = Settings.getSetting(id: Settings.weekStartID) as? Int {
                if value == 0 {
                    return .monday
                }
                else {
                    return .sunday
                }
            }
            else {
                Settings.setSetting(id: Settings.weekStartID, value: 1)
                return .sunday
            }
        }
    }
    
    class var defaultPracticeTitle: String {
        set {
            Settings.setSetting(id: Settings.defaultPracticeTitleID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.defaultPracticeTitleID) {
                return value as! String
            }
            else {
                Settings.setSetting(id: Settings.darkModeID, value: "Practice")
                return "Practice"
            }
        }
    }
    
    class var timerSound: String {
        set {
            Settings.setSetting(id: Settings.timerSoundID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.timerSoundID) {
                return value as! String
            }
            else {
                Settings.setSetting(id: Settings.timerSoundID, value: TimerSounds.mallet.filename)
                return TimerSounds.mallet.filename
            }
        }
    }
    
    class var showCountDown: Bool {
        set {
            Settings.setSetting(id: Settings.showCountDownID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.showCountDownID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.showCountDownID, value: true)
                return true
            }
        }
    }
    
    class var needsUpdate: Bool {
        set {
            Settings.setSetting(id: Settings.needsUpdateID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.needsUpdateID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.needsUpdateID, value: true)
                return true
            }
        }
    }
    
    class var practiceTimerMinutes: Int {
        set {
            Settings.setSetting(id: Settings.practiceTimerID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.practiceTimerID) {
                return value as! Int
            }
            else {
                Settings.setSetting(id: Settings.practiceTimerID, value: 15)
                return 15
            }
        }
    }
    
    class var isPremium: Bool {
        set {
            Settings.setSetting(id: Settings.premiumID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.premiumID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.premiumID, value: false)
                return false
            }
        }
    }
    
    class var reduceMotion: Bool {
        set {
            Settings.setSetting(id: Settings.reduceMotionID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.reduceMotionID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.reduceMotionID, value: false)
                return false
            }
        }
    }
    
    /**
     Uses system setting.
     - True: 14:09
     - False: 2:09 PM
    */
    class var standardTime: Bool {
        get {
            let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!
            return dateFormat.firstIndex(of: "a") == nil
        }
    }
    
    class var didShowOnboard: Bool {
        set {
            Settings.setSetting(id: Settings.didShowOnboardID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.didShowOnboardID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.didShowOnboardID, value: false)
                return false
            }
        }
    }
    
    class var showTips: Bool {
        set {
            Settings.setSetting(id: Settings.showTipsID, value: newValue)
        }
        get {
            if let value = Settings.getSetting(id: Settings.showTipsID) {
                return value as! Bool
            }
            else {
                Settings.setSetting(id: Settings.showTipsID, value: false)
                return true
            }
        }
    }
    
    enum TimerSounds {
        case mallet
        
        var filename: String {
            switch self {
            case .mallet:
                return "Mallet Alert"
            }
        }
    }
    
    fileprivate class func setSetting(id: String, value: Any?) {
        UserDefaults.standard.set(value, forKey: id)
    }
    
    fileprivate class func getSetting(id: String) -> Any? {
        return UserDefaults.standard.object(forKey: id)
    }
  
}

func isSystem24Hour() -> Bool {
    let dateFormat = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: Locale.current)!

    return dateFormat.firstIndex(of: "a") == nil
}
