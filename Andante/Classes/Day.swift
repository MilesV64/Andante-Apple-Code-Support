//
//  File.swift
//  Timer
//
//  Created by Miles Vinson on 2/5/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import Foundation

class Day: NSObject
{
    public var day: Int = 0
    public var month: Int = 0
    public var year: Int = 0
    
    public var date: Date
    
    init(day: Int, month: Int, year: Int)
    {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar.current
        self.date = Calendar.current.date(from: components) ?? Date()
        
        let calendar = Calendar.current
        self.day = calendar.component(.day, from: date)
        self.month = calendar.component(.month, from: date)
        self.year = calendar.component(.year, from: date)
    }
    
    init(date: Date)
    {
        let calendar = Calendar.current
        self.day = calendar.component(.day, from: date)
        self.month = calendar.component(.month, from: date)
        self.year = calendar.component(.year, from: date)
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.calendar = Calendar.current
        self.date = Calendar.current.date(from: components) ?? Date()
    }
    
    convenience init(string: String) {
        let year = Int(string.substring(0, 4)) ?? 0
        let month = Int(string.substring(4, 2)) ?? 0
        let day = Int(string.substring(6, 2)) ?? 0
        self.init(day: day, month: month, year: year)
    }
    
    
    
    public override var description: String
    {
        return "Day: \(self.month)/\(self.day)/\(self.year)"
    }
    
    /**
     Converts to "mm/dd/yyyy"
     */
    func toString() -> String {
        let dayStr = String(format:"%02i", day)
        let monthStr = String(format:"%02i", month)
        return "\(year)\(monthStr)\(dayStr)"
    }
        
    override var hash: Int {
        get {
            return date.hashValue
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Day {
            return self == object
        }
        return false
    }
    
    public func previousDay() -> Day {
        var components = DateComponents()
        components.day = self.day
        components.month = self.month
        components.year = self.year
        
        let date = Calendar.current.date(from: components) ?? Date()
        let newDate = Calendar.current.date(byAdding: DateComponents(day: -1), to: date) ?? Date()
        
        return Day(date: newDate)
    }
    
    public func nextDay() -> Day {
        var components = DateComponents()
        components.day = self.day
        components.month = self.month
        components.year = self.year
        
        let date = Calendar.current.date(from: components) ?? Date()
        let newDate = Calendar.current.date(byAdding: DateComponents(day: 1), to: date) ?? Date()
        
        return Day(date: newDate)
    }
    
    public func addingDays(_ days: Int) -> Day {
        let date = Calendar.current.date(byAdding: .day, value: days, to: self.date)!
        return Day(date: date)
    }
    
    public func distance(to day: Day) -> Int {
        return Calendar.current.dateComponents([.day], from: self.date, to: day.date).day ?? 0
    }
    
    public func isBefore(_ day: Day) -> Bool {
        return date < day.date
    }
    
}

extension Day {
    
    static func ==(lhs: Day, rhs: Day) -> Bool {
        return (lhs.day == rhs.day)
            && (lhs.month == rhs.month)
            && (lhs.year == rhs.year)
    }
    
}

class Month: Day
{
    
    convenience init(of day: Day) {
        self.init(date: day.date)
    }
    
    override init(date: Date) {
        super.init(date: date)
        
        let calendar = Calendar.current
        self.day = 1
        self.month = calendar.component(.month, from: date)
        self.year = calendar.component(.year, from: date)
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.calendar = Calendar.current
        self.date = Calendar.current.date(from: components) ?? Date()
    }
    
    public override var description: String
    {
        return "Month: \(self.month)/\(self.year)"
    }
    
    /**
     Converts to "mm/yyyy"
     */
    override func toString() -> String {
        let monthStr = String(format:"%02i", month)
        let dateStr =  monthStr + "/" + String(year)
        return dateStr
    }
    
    override var hash: Int {
        get {
            return month + year
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? Month {
            return self == object
        }
        return false
    }
    
    public func numberOfDays() -> Int {
        return Calendar.current.range(of: .day, in: .month, for: date)?.count ?? 0
    }
    
    public func monthsBetween(_ month: Month) -> Int {
        return Calendar.current.dateComponents([.month], from: self.date, to: month.date).month ?? 0
    }
    
    public func addingMonths(_ months: Int) -> Month {
        return Month(date: Calendar.current.date(byAdding: .month, value: months, to: self.date) ?? Date())
    }
    
    public func previousMonth() -> Month {
        return Month(date: Calendar.current.date(byAdding: .month, value: -1, to: self.date) ?? Date())
    }
    
    public func nextMonth() -> Month {
        return Month(date: Calendar.current.date(byAdding: .month, value: 1, to: self.date) ?? Date())
    }
    
    class func firstMonthOfTheYear() -> Month {
        let date = Date()
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = calendar.component(.year, from: date)
        components.month = 1
        components.day = 1
        
        return Month(date: calendar.date(from: components) ?? Date())
    }
    
}

extension Month {
    
    static func ==(lhs: Month, rhs: Month) -> Bool {
        return (lhs.month == rhs.month) && (lhs.year == rhs.year)
    }
    
}


extension String {
    func substring(_ start: Int, _ length: Int) -> Substring {
        let lower = index(startIndex, offsetBy: start)
        let upper = index(lower, offsetBy: length)
        return self[lower..<upper]
    }
}
