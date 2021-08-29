//
//  CDOngoingSession+CoreDataClass.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CDOngoingSession)
public class CDOngoingSession: NSManagedObject {
    
    var recordings : [String] {
        get {
            guard let recordingURLs = self.recordingURLs else { return [] }
            let data = Data(recordingURLs.utf8)
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            if
                let data = try? JSONEncoder().encode(newValue),
                let string = String(data: data, encoding: .utf8)
            {
                self.recordingURLs = string
            }
            else {
                self.recordingURLs = ""
            }
        }
    }
    
    static var ongoingSession: CDOngoingSession? {
        let context = DataManager.context
        let request = CDOngoingSession.fetchRequest() as NSFetchRequest<CDOngoingSession>
       
        do {
            let all = try context.fetch(request)
            print("OngoingSession count: \(all.count)")
            return all.first
        } catch {
            print(error)
            return nil
        }
    }
    
    @discardableResult
    static func createOngoingSession() -> CDOngoingSession {
        Self.deleteOngoingSession()
        
        let context = DataManager.context
        let session = CDOngoingSession(context: context)
        
        DataManager.saveContext()
        
        return session
        
    }
    
    static func deleteOngoingSession() {
        let context = DataManager.context
        
        let fetchRequest = CDOngoingSession.fetchRequest() as NSFetchRequest<NSFetchRequestResult>
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try DataManager.shared.container.persistentStoreCoordinator.execute(deleteRequest, with: context)
        } catch {
            print(error)
        }
        
        DataManager.saveContext()
        
    }
    
    public func update(updates: ((CDOngoingSession)->())?) {
        updates?(self)
        DataManager.saveContext()
    }
    
}
