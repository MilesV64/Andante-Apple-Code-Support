//
//  Settings.swift
//  Andante
//
//  Created by Miles Vinson on 8/7/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import Foundation

class Settings {
        
    @Setting(key: "Premium", defaultValue: false)
    static var isPremium: Bool
    
    @Setting(key: "includeNotesInExport", defaultValue: false)
    static var includeNotesInExport: Bool
    
    @Setting(key: "TunerTrial", defaultValue: false)
    static var didTryTuner: Bool
    
    @Setting(key: "PracticeTimer", defaultValue: 15)
    static var practiceTimerMinutes: Int
    
    @Setting(key: "MetronomeBPM", defaultValue: 80)
    static var metronomeBPM: Int

    @EnumSetting(JournalViewController.EntryLayout.self, key: "JournalLayout", defaultValue: .list)
    static var journalLayout: JournalViewController.EntryLayout

    
    // MARK: - Other
    
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
  
}

@propertyWrapper
public struct Setting<T> {
    private let defaultValue: T

    public let key: String

    public var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: key)
        }
    }

    public init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

@propertyWrapper
public struct EnumSetting<T : RawRepresentable> where T.RawValue == Int {
    private let defaultValue: T
    private let enumType: T.Type
    public let key: String

    public var wrappedValue: T {
        get {
            if
                let val = UserDefaults.standard.object(forKey: key) as? Int,
                let result = enumType.init(rawValue: val)
            {
                return result
            } else {
                return defaultValue
            }
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: key)
        }
    }

    public init(_ enumType: T.Type, key: String, defaultValue: T) {
        self.enumType = enumType
        self.key = key
        self.defaultValue = defaultValue
    }
}
