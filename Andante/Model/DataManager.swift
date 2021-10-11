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
        
        // Local data
        let localStoreDescription: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: directory.appendingPathComponent("Local.sqlite"))
            description.configuration = "Local"
            return description
        }()
        
        // Cloud synced data
        let cloudStoreDescription: NSPersistentStoreDescription = {
            let description = NSPersistentStoreDescription(url: directory.appendingPathComponent("Cloud.sqlite"))
            description.configuration = "Cloud"
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.milesvinson.andante")
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            return description
        }()
        
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
        container.viewContext.transactionAuthor = "Andante"
        container.viewContext.stalenessInterval = 0
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(self.storeRemoteChange(_:)),
            name: .NSPersistentStoreRemoteChange, object: container)
        
        return container
    }()
    
    // MARK: - History tracking
    // Track the last history token processed for a store, and write its value to file.
    // The historyQueue reads the token when executing operations, and updates it after processing is complete.
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                  let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true)
            else {
                return
            }

            do {
                try data.write(to: tokenFile)
            } catch {
                print("Failed to write token data. Error = \(error)")
            }
        }
    }

    // The file URL for persisting the persistent history token.
    private lazy var tokenFile: URL = {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.milesvinson.Andante")!.appendingPathComponent("CoreDataHistory", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create persistent container URL. Error = \(error)")
            }
        }
        
        let bundleId = Bundle.main.bundleIdentifier!
        let tokenURL = url.appendingPathComponent(bundleId + ".token.data", isDirectory: false)
        print("tokenURL: ", tokenURL)

        return tokenURL
    }()


    // An operation queue for handling history processing tasks: watching changes and triggering UI updates if needed.
    private lazy var historyQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        return queue
    }()

    init() {
        if let tokenData = try? Data(contentsOf: tokenFile) {
           do {
               lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
           } catch {
               print("Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
           }
       }
   }
    
}

// MARK: - Handle Persistent History

extension DataManager {
    
    @objc func storeRemoteChange(_ notification: Notification) {
        // Process persistent history to merge changes from other coordinators.
        historyQueue.addOperation {
            self.processPersistentHistory()
        }
    }
    
    func processPersistentHistory() {
        let taskContext = self.container.newBackgroundContext()
        taskContext.performAndWait {

            // Fetch history received from outside the app since the last token
            let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
            historyFetchRequest.predicate = NSPredicate(format: "author != %@", "Andante")
            let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
            request.fetchRequest = historyFetchRequest

            let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
            guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
                  !transactions.isEmpty
            else { return }

            transactions.forEach { transaction in
                guard let userInfo = transaction.objectIDNotification().userInfo else { return }
                print("transaction userInfo: ", userInfo)
                let viewContext = self.container.viewContext
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [viewContext])
            }

            // Update the history token using the last transaction.
            lastHistoryToken = transactions.last!.token
        }
    }
    
}


// MARK: - Helpers

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
