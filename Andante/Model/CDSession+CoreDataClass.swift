//
//  CDSession+CoreDataClass.swift
//  
//
//  Created by Miles Vinson on 2/7/21.
//
//

import Foundation
import CoreData

@objc(CDSession)
public class CDSession: NSManagedObject {
        
    func createSession(
        begin: Date,
        end: Date,
        practiceTime: Int,
        mood: Int,
        focus: Int,
        notes: String?,
        title: String?
    ) {
        
        self.mood = mood
        self.focus = focus
        self.notes = notes
        self.title = title
        self.practiceTime = practiceTime
        self.startTime = begin
        self.end = end
    }
    
    /**
     Note that copies delete the original recordings, and do not establish any relationship
     */
    func duplicate(context: NSManagedObjectContext? = nil) -> CDSession {
        let session = CDSession(context: context ?? DataManager.context)
        if context != nil {
            DataManager.obtainPermanentID(for: session)
        }
        session.createSession(
            begin: self.startTime,
            end: self.getEndTime(),
            practiceTime: self.practiceTime,
            mood: self.mood,
            focus: self.focus,
            notes: self.notes,
            title: self.title)
        
        for recording in Array(self.recordings as? Set<CDRecording> ?? []) {
            let rec = CDRecording(context: context ?? DataManager.context)
            if context != nil {
                DataManager.obtainPermanentID(for: rec)
            }
            rec.index = recording.index
            rec.recordingData = recording.recordingData
            session.addToRecordings(rec)
            
            self.removeFromRecordings(recording)
            (context ?? DataManager.context).delete(recording)
        }
        
        return session
    }
    
    override public func awakeFromInsert() {
        super.awakeFromInsert()
        guard let context = self.managedObjectContext else { return }
        let attributes = CDSessionAttributes(context: context)
        DataManager.obtainPermanentID(for: attributes)
        self.attributes = attributes
        
    }
    
    public var practiceTime: Int {
        get {
            return Int(self.d_practiceTime)
        }
        set {
            attributes?.practiceTime = Int64(newValue)
            self.d_practiceTime = Int64(newValue)
        }
    }
    
    public var mood: Int {
        get {
            return Int(self.d_mood)
        }
        set {
            attributes?.mood = Int64(newValue)
            self.d_mood = Int64(newValue)
        }
    }
    
    public var focus: Int {
        get {
            return Int(self.d_focus)
        }
        set {
            attributes?.focus = Int64(newValue)
            self.d_focus = Int64(newValue)
        }
    }
    
    public var startTime: Date {
        get {
            return  self.d_startTime ?? Date()
        }
        set {
            attributes?.startTime = newValue
            self.d_startTime = newValue
        }
    }
    
    public func getTitle() -> String {
        return title ?? ""
    }
    
    @objc var day: String { get {
        return Day(date: startTime).toString()
    }}
    
    public func getEndTime() -> Date {
        return end ?? Date()
    }
    
    @objc var hasNotes: Bool { get {
        return self.notes != nil && self.notes != ""
    }}
    
    @objc var hasRecording: Bool { get {
        return self.recordings?.count ?? 0 > 0
    }}
    
    func getRecordings() -> [CDRecording] {
        guard let recordings = recordings as? Set<CDRecording> else { return [] }
        return Array(recordings.sorted(by: { (f1, f2) -> Bool in
            return f1.index > f2.index
        }))
    }
    
    public func move(to profile: CDProfile) {
        //Need to do new attributes to update FRC that monitors attributes
        
        let attributes = CDSessionAttributes(context: DataManager.context)
        attributes.focus = Int64(self.focus)
        attributes.mood = Int64(self.mood)
        attributes.practiceTime = Int64(self.practiceTime)
        attributes.startTime = self.startTime
        
        if let currentAttributes = self.attributes {
            DataManager.context.delete(currentAttributes)
            self.attributes = nil
        }
        
        self.profile?.removeFromSessions(self)
        
        self.attributes = attributes
        profile.addToSessions(self)
    }
    
}
