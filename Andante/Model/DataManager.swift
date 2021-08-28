//
//  DataManager.swift
//  CoreDataDemo
//
//  Created by Miles Vinson on 2/5/21.
//

import UIKit
import CoreData
import Combine

extension Notification.Name {
    static let DidReceiveRemoteDataUpdate = Notification.Name("DidReceiveRemoteDataUpdate")
}

class DataManager {
        
    static let shared = DataManager()
    
    static var context: NSManagedObjectContext {
        return DataManager.shared.container.viewContext
    }
    
    static var backgroundContext: NSManagedObjectContext {
        return DataManager.shared.container.newBackgroundContext()
    }
    
    lazy var container: NSPersistentContainer = {
                
        let container = NSPersistentCloudKitContainer(name: "Andante")
        
        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        //Local data
        let localStoreDescription = NSPersistentStoreDescription(url: directory.appendingPathComponent("Local.sqlite"))
        localStoreDescription.configuration = "Local"
        
        //Cloud synced data
        let cloudStoreDescription = NSPersistentStoreDescription(
            url: directory.appendingPathComponent("Cloud.sqlite"))
        cloudStoreDescription.configuration = "Cloud"
        cloudStoreDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.milesvinson.andante")
        
        container.persistentStoreDescriptions = [
            cloudStoreDescription,
            localStoreDescription
        ]
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
}

extension DataManager {
    
    class func obtainPermanentID(for object: NSManagedObject) {
        do {
            try DataManager.context.obtainPermanentIDs(for: [object])
        }
        catch {
            print("Error obtaining permanent ID: \(error)")
        }
    }
    
    class func saveNewObject(_ object: NSManagedObject) {
        DataManager.obtainPermanentID(for: object)
        DataManager.saveContext()
    }
    
    class func saveContext(completion: ((Error?) -> ())? = nil) {
        if DataManager.context.hasChanges {
            do {
                try DataManager.context.save()
                completion?(nil)
            } catch {
                print(error)
                completion?(nil)
            }
        } else {
            completion?(nil)
        }
        
    }
    
}
