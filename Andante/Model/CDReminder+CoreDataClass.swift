//
//  CDReminder+CoreDataClass.swift
//  Andante
//
//  Created by Miles Vinson on 3/6/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData
import UserNotifications

@objc(CDReminder)
public class CDReminder: NSManagedObject {
    
    public func getDays() -> Array<Int> {
        if let days = self.days {
            return days.split(separator: ",").compactMap { Int($0) }
        } else {
            return []
        }
    }
    
    public func setDays(_ days: Array<Int>) {
        self.days = days.map { String($0) }
            .joined(separator: ",")
    }

}

extension CDReminder {
    
    public func setEnabled(_ enabled: Bool) {
        self.isEnabled = enabled
        DataManager.saveContext()
        
        if isEnabled {
            scheduleNotification()
        } else {
            unscheduleNotification()
        }
        
    }
    
    public func scheduleNotification(context: NSManagedObjectContext? = nil) {
        guard isEnabled else { return }
            
        let ctx = context ?? DataManager.context
            
        //unschedule the reminder's existing notifications and reset the unique id for the case where the reminder is being edited
        
        unscheduleNotification()
        
        guard let profile = CDProfile.getAllProfiles(context: ctx)
                .first(where: { $0.uuid == profileID }) else { return }
        
        self.uuid = UUID().uuidString
        try? ctx.save()
        
        let center = UNUserNotificationCenter.current()
        
        let days = getDays()
        let date = self.date ?? Date()
        
        //if no repeating days, just schedule one notification
        if days.count == 0 {
            let content = UNMutableNotificationContent()
            let name = profile.name ?? ""
            content.title = "Practice \(name)"
            content.categoryIdentifier = "reminder"
            content.sound = UNNotificationSound.default

            var dateComponents = DateComponents()
            dateComponents.hour = Calendar.current.component(.hour, from: date)
            dateComponents.minute = Calendar.current.component(.minute, from: date)
            dateComponents.second = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

            let request = UNNotificationRequest(identifier: id(for: nil), content: content, trigger: trigger)
                        
            center.add(request)
        }
        else {
            for day in days {
                
                let content = UNMutableNotificationContent()
                let name = profile.name ?? ""
                content.title = "Practice \(name)"
                content.categoryIdentifier = "reminder"
                content.sound = UNNotificationSound.default
                
                var dateComponents = DateComponents()
                dateComponents.weekday = convertWeekday(day)
                dateComponents.hour = Calendar.current.component(.hour, from: date)
                dateComponents.minute = Calendar.current.component(.minute, from: date)
                dateComponents.second = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                
                let request = UNNotificationRequest(identifier: id(for: day), content: content, trigger: trigger)
                center.add(request) { (error) in
                    if let error = error {
                        print(error)
                    }
                }
                
            }
        }

    }
    
    public func unscheduleNotification() {
        var ids: [String] = []
        getDays().forEach { ids.append(self.id(for: $0)) }
        ids.append(id(for: nil))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
    
    public func id(for day: Int?) -> String {
        //unique id for each notification based on the reminder's unique id
        
        if let day = day {
            return "com.milesvinson.andante." + "\(day)" + (self.uuid ?? "")
        } else {
            return "com.milesvinson.andante." + (self.uuid ?? "")
        }
        
    }
    
    private func convertWeekday(_ day: Int) -> Int {
        //from 0 = monday to 1 = sunday
        var newDay = day + 2
        if newDay == 8 {
            newDay = 1
        }
        
        return newDay
    }
    
}

extension CDReminder {
    
    public static func getAllReminders(context: NSManagedObjectContext? = nil) -> [CDReminder] {
        let ctx = context ?? DataManager.context
        let reminders = try? ctx.fetch(self.fetchRequest() as NSFetchRequest<CDReminder>)
        return Array(reminders ?? [])
    }
        
    
    public static func rescheduleAllNotifications() {
        for reminder in CDReminder.getAllReminders() {
            reminder.scheduleNotification()
        }
    }
    
    //this is called in the AppDelegate's userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) delegate method
    public static func updateReminders() {
        let context = DataManager.backgroundContext
        let request = self.fetchRequest() as NSFetchRequest<CDReminder>
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            
            if notifications.count == 0 {
                return
            }
            
            context.performAndWait {
                if let reminders = try? context.fetch(request) {
                    for reminder in reminders {
                        
                        //if reminder is not repeating, disable the reminder after the notification
                        if reminder.getDays().count == 0 {
                            if (notifications.first(where: { (notification) -> Bool in
                                notification.request.identifier == reminder.uuid
                            }) != nil) {
                                reminder.isEnabled = false
                            }
                        }
                    }
                    
                    if context.hasChanges {
                        do {
                            try context.save()
                        } catch {
                            print("Error saving background context: \(error)")
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            }
            
            
        }
        
    }
    
    public static var ReloadRemindersNotification = "ShouldReloadReminders"
    
}
