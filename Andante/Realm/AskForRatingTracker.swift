////
////  AskForRatingTracker.swift
////  Andante
////
////  Created by Miles Vinson on 9/23/20.
////  Copyright © 2020 Miles Vinson. All rights reserved.
////
//
//import Foundation
//import RealmSwift
//
//class AskForRatingTracker: Object {
//
//    @objc dynamic var sessions = 0
//    @objc dynamic var didDisplay = false
//    @objc dynamic var requiredSessions = 10
//    let uniqueDays = List<Date>()
//    
//    public static func userDidInteractWithNotification() {
//        let instance = AskForRatingTracker.getInstance()
//
//        let realm = try! Realm()
//        try! realm.write {
//            instance.didDisplay = true
//        }
//    }
//
//    public static func logSession() {
//        let instance = AskForRatingTracker.getInstance()
//
//        let date = Day(date: Date()).date
//
//        let realm = try! Realm()
//
//        try! realm.write {
//            instance.sessions += 1
//
//            if instance.uniqueDays.contains(date) == false {
//                instance.uniqueDays.append(date)
//            }
//        }
//    }
//
//    public static var shouldAskForRating: Bool {
//        let instance = AskForRatingTracker.getInstance()
//
//        if instance.sessions >= instance.requiredSessions && instance.uniqueDays.count >= 3 {
//            let realm = try! Realm()
//            try! realm.write {
//                instance.requiredSessions += 30
//            }
//            return true
//        }
//        else {
//            return false
//        }
//    }
//
//    public static func getInstance() -> AskForRatingTracker {
//        let realm = try! Realm()
//        let savedInstance = realm.objects(AskForRatingTracker.self).first
//
//        if let instance = savedInstance {
//            return instance
//        }
//        else {
//            let newInstance = AskForRatingTracker()
//
//            try! realm.write {
//                realm.add(newInstance)
//            }
//
//            return newInstance
//        }
//    }
//
//}
