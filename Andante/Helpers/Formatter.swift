//
//  Formatter.swift
//  Timer
//
//  Created by Miles Vinson on 1/14/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import Foundation

class Formatter {
    /**
    1 hour, 1 min, 1 hour 1 min
     */
    class func formatMinutes(mins: Int) -> String {
        //128m -> 2h 8m
        let hours = mins / 60
        let min = mins - (hours*60)
        
        if hours == 0 && min == 0 {
            return "\(min) min"
        }
        else if hours != 0 && min == 0 {
            if hours > 1 {
                return "\(hours) hours"
            }
            else {
                return "\(hours) hour"
            }
        }
        else if hours == 0 && min != 0 {
            return "\(min) min"
        }
        else if hours != 0 && min != 0 {
            return "\(hours) hour\(hours != 1 ? "s" : "")" + " " + "\(min) min"
        }
        
        return ""
    }
    
    /**
    1 hour, 1 min, 1h 1m
     */
    class func formatMinutesShort(mins: Int) -> String {
        //128m -> 2h 8m
        let hours = mins / 60
        let min = mins - (hours*60)
        
        if hours == 0 && min == 0 {
            return "\(min) min"
        }
        else if hours != 0 && min == 0 {
            if hours > 1 {
                return "\(hours) hours"
            }
            else {
                return "\(hours) hour"
            }
        }
        else if hours == 0 && min != 0 {
            return "\(min) min"
        }
        else if hours != 0 && min != 0 {
            return "\(hours)h" + " " + "\(min)m"
        }
        
        return ""
    }
    
    /**
     1h, 1m, 1h 1m
     */
    class func formatMinutesShorter(mins: Int) -> String {
        //128m -> 2h 8m
        let hours = mins / 60
        let min = mins - (hours*60)
        
        let minStr = "\(min)m"
        let hourStr = "\(hours)h"
        

        if hours == 0 && min == 0 {
            return "\(min)m"
        }
        else if hours != 0 && min == 0 {
            return "\(hours)h"
        }
        else if hours == 0 && min != 0 {
            return "\(min)m"
        }
        else if hours != 0 && min != 0 {
            return hourStr + " " + minStr
        }
        
        return ""
    }
    
    /**67 -> 1h,
     1 -> 1m,
     119 -> 1h, 120 -> 2h
    */
    class func formatMinutesCondensed(_ mins: Int) -> String {
        let hours = mins / 60
        let min = mins - (hours*60)
        
        if hours != 0 {
            return "\(hours)h"
        }
        else {
            return "\(min)m"
        }
    }
    
    /**67 -> 1 hour,
     1 -> 1 min,
     119 -> 1h, 120 -> 2 hours
    */
    class func formatMinutesCondensedButAlsoLong(_ mins: Int) -> String {
        let hours = mins / 60
        let min = mins - (hours*60)
        
        if hours != 0 {
            if hours == 1 {
                return "\(hours) hour"
            }
            else {
                return "\(hours) hours"
            }
        }
        else {
            return "\(min) min"
        }
    }
    
    class func formatHourMins(hours: Int, minutes: Int) -> String {
        return formatMinutes(mins: hours*60 + minutes)
    }
    
    /**
     67 -> 1 hour  7 minutes
    */
    class func formatMinutesLong(mins: Int) -> String {
        //128m -> 2h 8m
        let hours = mins / 60
        let min = mins - (hours*60)
        
        
        let minStr = "\(min) min"
        var hourStr = "\(hours) hour"
        
        if hours != 1 {
            hourStr += "s"
        }
        
        if hours == 0 && min == 0 {
            return minStr
        }
        else if hours != 0 && min == 0 {
            return hourStr
        }
        else if hours == 0 && min != 0 {
            return minStr
        }
        else if hours != 0 && min != 0 {
            return hourStr + " " + minStr
        }
        
        return ""
    }
    
    class func formatDate(_ date: Date, includeDay: Bool = true, includeMonth: Bool = true, includeYear: Bool = true) -> String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let day = calendar.component(.day, from: date)
        
        let monthName = Formatter.monthName(for: date, short: false)
        
        return "\(includeMonth ? monthName + " " : "")\(includeDay ? "\(day)" + " " : "")\(includeYear ? "\(year)" : "")"
    }
    
    /**
     Returns string representing the date
     
     ex. January 14, 2019
     
     - parameter checksToday: If true, displays the current date as "Today". Set to false to display current date normally.
     
    */
    class func regularDate(date: Date, checksToday: Bool = true, shortMonth: Bool = false) -> String {
        //January 14, 2019
        
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let day = calendar.component(.day, from: date)
        
        let monthName = Formatter.monthName(for: date, short: shortMonth)
        
        if checksToday && date.isTheSameDay(as: Date()){
            return "Today"
        }
        
        return "\(monthName) \(day), \(year)"
    }
    
    /**
     Returns string representing the date, without the year
     
     ex. January 14
     
     - parameter checksToday: If true, displays the current date as "Today". Set to false to display current date normally.
     
     */
    class func shortDate(date: Date, checksToday: Bool = true, shortMonth: Bool = false) -> String {
        //January 14
        
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        
        let monthName = Formatter.monthName(for: date, short: shortMonth)
        
        if checksToday && date.isTheSameDay(as: Date()){
            return "Today"
        }
        
        return "\(monthName) \(day)"
    }
    
    class func weekdayString(_ date: Date) -> String {
        let weekdayNum = date.weekday()
        switch weekdayNum {
        case 0: return "Monday"
        case 1: return "Tuesday"
        case 2: return "Wednesday"
        case 3: return "Thursday"
        case 4: return "Friday"
        case 5: return "Saturday"
        case 6: return "Sunday"
        default: return ""
        }
    }
    
    class func weekdayString(_ i: Int) -> String {
        switch i {
        case 0: return "Monday"
        case 1: return "Tuesday"
        case 2: return "Wednesday"
        case 3: return "Thursday"
        case 4: return "Friday"
        case 5: return "Saturday"
        case 6: return "Sunday"
        default: return ""
        }
    }
    
    class func monthName(for date: Date, short: Bool = false) -> String {
        let calendar = Calendar.current
        let monthNum = calendar.component(.month, from: date)
        var month = ""
        
        if short {
            switch monthNum {
            case 1: month = "Jan"
            case 2: month = "Feb"
            case 3: month = "Mar"
            case 4: month = "Apr"
            case 5: month = "May"
            case 6: month = "Jun"
            case 7: month = "Jul"
            case 8: month = "Aug"
            case 9: month = "Sep"
            case 10: month = "Oct"
            case 11: month = "Nov"
            case 12: month = "Dec"
            default: month = ""
            }
        }
        else {
            switch monthNum {
            case 1: month = "January"
            case 2: month = "February"
            case 3: month = "March"
            case 4: month = "April"
            case 5: month = "May"
            case 6: month = "June"
            case 7: month = "July"
            case 8: month = "August"
            case 9: month = "September"
            case 10: month = "October"
            case 11: month = "November"
            case 12: month = "December"
            default: month = ""
            }
        }
        
        return month
    }
    
    class func weekString(for date: Date) -> String {
        let startDay = Calendar.current.component(.day, from: date.startOfWeek!)
        let startMonth = Calendar.current.component(.month, from: date.startOfWeek!)
        let endDay = Calendar.current.component(.day, from: date.endOfWeek!)
        let endMonth = Calendar.current.component(.month, from: date.endOfWeek!)

        return "\(startMonth)/\(startDay) - \(endMonth)/\(endDay)"
        
    }
    
    class func getMonthNum(fromString: String) -> Int {
        switch fromString {
        case "Jan": return 1
        case "Feb": return 2
        case "Mar": return 3
        case "Apr": return 4
        case "May": return 5
        case "June": return 6
        case "July": return 7
        case "Aug": return 8
        case "Sept": return 9
        case "Oct": return 10
        case "Nov": return 11
        case "Dec": return 12
        default: return 0
        }
    }
    
    /**
     2:45pm, 14:45
    */
    class func getTimeText(from date: Date, amString: String = " AM", pmString: String = " PM") -> String {
        var text = ""
        
        let hour = Calendar.current.component(.hour, from: date)
        let min = Calendar.current.component(.minute, from: date)
        var minStr = String(min)
        if min < 10 {
            minStr = "0\(min)"
        }
        
        var value = Int(hour)
        
        if Settings.standardTime == false { 
            if value > 12 {
                value -= 12
                text = "\(String(value)):\(minStr)\(pmString)"
            }
            else if value == 0 {
                text = "12:\(minStr)\(amString)"
            }
            else if value == 12 {
                text = "12:\(minStr)\(pmString)"
            }
            else {
                text = "\(String(value)):\(minStr)\(amString)"
            }
        }
        else {
            text = "\(value):\(minStr)"
        }
        
        
        return text
    }
    
    class func getTimeTextSplit(from date: Date) -> (time: String, suffix: String?) {
        var text = ""
        
        let hour = Calendar.current.component(.hour, from: date)
        let min = Calendar.current.component(.minute, from: date)
        var minStr = String(min)
        if min < 10 {
            minStr = "0\(min)"
        }
        
        var value = Int(hour)
        
        if Settings.standardTime == false {
            var suffix = ""
            if value > 12 {
                value -= 12
                text = "\(String(value)):\(minStr)"
                suffix = "PM"
            }
            else if value == 0 {
                text = "12:\(minStr)"
                suffix = "AM"
            }
            else if value == 12 {
                text = "12:\(minStr)"
                suffix = "PM"
            }
            else {
                text = "\(String(value)):\(minStr)"
                suffix = "AM"
            }
            return (time: text, suffix: suffix)
            
        }
        else {
            return (time: "\(value):\(minStr)", suffix: nil)
        }
        
    }
    
    /**
     Returns time text in format (1 PM, 13:00)
     - Parameter hour: hour as a number (0 or 24 == midnight)
     */
    class func getTimeText(from hour: Int, midnight: Int = 0) -> String {
        var text = ""
        var value = hour

        if midnight == 0 {
            if value < 0 {
                value += 24
            }
            else if value > 23 {
                value -= 24
            }
        }
        else if midnight == 24 {
            if value < 1 {
                value += 24
            }
            else if value > 24 {
                value -= 24
            }
        }
        
        if Settings.standardTime == false {
            if value == midnight {
                return "Midnight"
            }
            else if value > 12 {
                value -= 12
                text = "\(String(value)) PM"
            }
            else if value == 12 {
                text = "Noon"
            }
            else {
                text = "\(String(value)) AM"
            }
        }
        else {
            text = "\(String(value)):00"
        }
        
        
        return text
    }
    
    class func formatDecimals(num: Double, trim: Bool = false) -> String {
        if !trim {
            return String(format: "%.1f", num)
        }
        else {
            if num == floor(num) {
                return "\(Int(num))"
            }
            else {
                return String(format: "%.1f", num)
            }
        }
        
    }
}



extension Date {
    /**
     - Long: March 8, 2020
     - Medium: Mar 8, 2020
     - Short: 3/8/17
     */
    func string(dateStyle: DateFormatter.Style = .none) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = dateStyle
        return formatter.string(from: self)
    }
    
    /**
     - Long: 1:26:32 PM GMT
     - Medium: 1:26:32 PM
     - Short:  1:26 PM
     */
    func string(timeStyle: DateFormatter.Style) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = timeStyle
        return formatter.string(from: self)
    }
    
    /**
     "MMMM d" -> July 10
     
     [See format guide](http://cldr.unicode.org/translation/date-time-1/date-time)
     */
    func string(template: String) -> String {
        let format = DateFormatter.dateFormat(fromTemplate: template, options: 0, locale: .current)
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}
