
//class OngoingSession: Object {
//
//    @objc dynamic var start = Date()
//    @objc dynamic var practiceTimeSeconds = 0
//    @objc dynamic var notes = ""
//    @objc dynamic var recordingFilename = ""
//    @objc dynamic var lastSave = Date()
//    @objc dynamic var isPaused = false
//
//    var recordingFilenames = List<String>()
//
//    class var ongoingSession: OngoingSession? {
//        get {
//            let realm = try! Realm()
//            return realm.objects(OngoingSession.self).first
//        }
//    }
//
//    @discardableResult
//    class func createOngoingSession() -> OngoingSession {
//        let obj = OngoingSession()
//
//        let realm = try! Realm()
//        try! realm.write {
//            realm.objects(OngoingSession.self).forEach(realm.delete(_:))
//            realm.add(obj)
//        }
//
//        return obj
//    }
//
//    class func deleteOngoingSession() {
//        let realm = try! Realm()
//        try! realm.write {
//            realm.objects(OngoingSession.self).forEach(realm.delete(_:))
//        }
//    }
//
//    public func update(updates: ((_:OngoingSession)->Void)?) {
//        let realm = try! Realm()
//        try! realm.write {
//            updates?(self)
//        }
//    }
//
//}
