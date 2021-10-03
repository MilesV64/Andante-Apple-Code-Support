//
//  CDAskForRatingTracker+CoreDataClass.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData
import StoreKit

@objc(CDAskForRatingTracker)
public class CDAskForRatingTracker: NSManagedObject {
    
    private static let MinimumSessionsToAsk:Int64 = 10
    private static let MinimumDaysToAsk:Int64 = 3
    
    private static func getInstance() -> CDAskForRatingTracker? {
        let context = DataManager.context
        let request = CDAskForRatingTracker.fetchRequest() as NSFetchRequest<CDAskForRatingTracker>
       
        do {
            let instance = try context.fetch(request).first
            
            if instance == nil {
                let newInstance = CDAskForRatingTracker(context: context)
                DataManager.saveContext()
                return newInstance
            }
            else {
                return instance
            }
            
        } catch {
            print(error)
            return nil
        }
    }
    
    public static func logSession() {
        if let instance = Self.getInstance() {
            
            print()
            print("AskForRatingTracker: Logging session. Sessions: \(instance.sessions), Unique Days: \(instance.uniqueDays)")
            
            // No need to update if it's already past the threshold
            guard instance.sessions < Self.MinimumSessionsToAsk || instance.uniqueDays < Self.MinimumDaysToAsk else { return }
            
            instance.sessions += 1
            
            print("New Sessions: \(instance.sessions)")
            
            if let lastSessionDate = instance.lastSessionDate {
                let today = Date()
                if today.isTheSameDay(as: lastSessionDate) == false {
                    instance.lastSessionDate = today
                    instance.uniqueDays += 1
                    print("New Unique Days: \(instance.uniqueDays).")
                }
                else {
                    print("Same day as lastSessionDate; not incrementing uniqueDays.")
                }
            }
            else {
                instance.lastSessionDate = Date()
                instance.uniqueDays += 1
                print("New Unique Days: \(instance.uniqueDays). uniqueDays was previously nil.")
            }
            
            print("AskForRatingTracker: Done logging session.\n")
            
            DataManager.saveContext()
            
        }
    }
    
    private static func shouldAskForRating() -> Bool {
        guard let instance = Self.getInstance() else { return false }
        
        if instance.sessions >= Self.MinimumSessionsToAsk, instance.uniqueDays >= Self.MinimumDaysToAsk {
            
            instance.sessions = 0 // Don't ask again for 10 more sessions
            instance.uniqueDays = 1 // Don't ask again for 2 more days
            instance.lastSessionDate = Date()
            
            DataManager.saveContext()
            
            return true
            
        }
        else {
            return false
        }
        
    }
    
    public static func askForRating() {
        if Self.shouldAskForRating() {
            SKStoreReviewController.requestReview()
        }
    }

}
