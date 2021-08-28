//
//  WidgetDataManager.swift
//  Andante
//
//  Created by Miles Vinson on 9/25/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Foundation
import CoreData
import WidgetKit

class WidgetDataManager {
    
    private static let shared = WidgetDataManager()
    
    private var operationQueue = OperationQueue()
    
    /*
     Write data to a shared file that the widget extension can read.
     Data should always be up to date with WidgetContent for each profile.
     */
    static func writeData() {
    
        if #available(iOS 14.0, *) {
            
            print("WidgetDataManager: Begin writing data")
            
            let manager = WidgetDataManager.shared
            manager.operationQueue.cancelAllOperations()
            manager.operationQueue.addOperation(WriteDataOperation())

        }
        
    }
    
}

fileprivate class WriteDataOperation: Operation {
    override func main() {
        super.main()
        
        let context = DataManager.backgroundContext
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        
        context.performAndWait {
            do {
                if isCancelled {
                    print("WidgetDataManager: Cancelled operation before start")
                    return
                }
                
                let profiles = try context.fetch(request)
                
                var contents: [WidgetContent] = []
                            
                var days: [Day] = []
                let today = Day(date: Date())
                for i in 0...6 {
                    days.append(today.addingDays(-6 + i))
                }
                let firstDate = days.first!
                
                for profile in profiles {
                    
                    var practiceTimes: [ Day : Int ] = [:]
                    let sessions = profile.getSessions()
                    
                    for i in 0..<sessions.count {
                        
                        let session = sessions[i]
                        let sessionDay = Day(date: session.startTime)
                        
                        if sessionDay.isBefore(firstDate) {
                            break
                        }
                        else {
                            if practiceTimes[sessionDay] == nil {
                                practiceTimes[sessionDay] = session.practiceTime
                            }
                            else {
                                practiceTimes[sessionDay]? += session.practiceTime
                            }
                        }
                    }
                                    
                    let dailyGoal = profile.dailyGoal
                    var progress: [Double] = []
                    var weekdays: [String] = []
                    
                    for day in days {
                        progress.append(Double(practiceTimes[day] ?? 0)/Double(dailyGoal))
                        weekdays.append(String(Formatter.weekdayString(day.date).prefix(1)))
                    }
                                       
                    contents.append(
                        WidgetContent(
                            profileID: profile.uuid ?? "",
                            profileName: profile.name ?? "",
                            profileIcon: (profile.iconName ?? "") + "-sm",
                            weekdays: weekdays,
                            progress: progress,
                            practiceToday: "\(practiceTimes[today] ?? 0) min"
                        )
                    )
                }
                
                let oldContents = WidgetFileManager.getContents()
                var isEqual = true
                if oldContents.count == contents.count {
                    for i in 0..<oldContents.count {
                        let c1 = oldContents[i]
                        let c2 = contents[i]
                        if c1.profileID != c2.profileID
                            || c1.profileName != c2.profileName
                            || c1.profileIcon != c2.profileIcon
                            || !c1.weekdays.elementsEqual(c2.weekdays)
                            || !c1.progress.elementsEqual(c2.progress)
                            || c1.practiceToday != c2.practiceToday
                        {
                            isEqual = false
                            break
                        }
                    }
                }
                else {
                    isEqual = false
                }
                
                if !self.isCancelled {
                    if !isEqual {
                        WidgetFileManager.writeContents(contents)
                        
                        DispatchQueue.main.async {
                            if #available(iOS 14.0, *) {
                                WidgetCenter.shared.reloadAllTimelines()
                            }
                            print("WidgetDataManager: Finished writing data")
                        }
                    }
                    else {
                        print("WidgetDataManager: Data was already up to date")
                    }
                }
                else {
                    print("WidgetDataManager: Cancelled operation")
                }
                
            }
            catch {
                print("Error fetching profiles for widget reload: \(error)")
            }
        }
        
    }
}
