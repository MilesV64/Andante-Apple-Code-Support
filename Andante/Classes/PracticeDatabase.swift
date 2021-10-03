
import UIKit
import CoreData

enum Stat {
    case practice, sessions, mood, focus, time
    
    var color: UIColor {
        switch self {
        case .practice: return Colors.practiceTimeColor
        case .sessions: return Colors.sessionsColor
        case .mood:     return Colors.moodColor
        case .focus:    return Colors.focusColor
        case .time:     return Colors.sessionsColor
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .practice: return UIImage(named: "feather.stopwatch")
        case .sessions: return UIImage(named: "feather.sessions")
        case .mood:     return UIImage(named: "feather.smile")
        case .focus:    return UIImage(named: "feather.bolt")
        case .time:    return UIImage(named: "feather.clock")
        }
    }
}

protocol PracticeDatabaseObserver: AnyObject {
    
    /// The practice database has changed
    func practiceDatabaseDidUpdate(_ practiceDatabase: PracticeDatabase)
    
    /// The practice database for the given profile has changed
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, didChangeFor profile: CDProfile)
    
    /// The streak for the given profile has changed
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, streakDidChangeFor profile: CDProfile, streak: Int)
    
    /// The total streak has changed
    func practiceDatabase(_ practiceDatabase: PracticeDatabase, didChangeTotalStreak streak: Int)
    
}

class PracticeDatabase: NSObject {
    
    public static var PracticeDatabaseDidChangeNotification =
        NSNotification.Name("PracticeDatabaseDidChangeNotification")
    
    public static var PracticeDatabaseStreakDidChangeNotification = NSNotification.Name("PracticeDatabaseStreakDidChangeNotification")
    
    //MARK: - Public attributes
    
    public static var shared = PracticeDatabase()
    
    
    //MARK: - Private attributes
    
    private let controller: NSFetchedResultsController<CDSessionAttributes>
    
    private var sectionDictionary: [ Day : Int ] = [:]
    private var streaks: [CDProfile : Int] = [:]
    private var totalStreak: Int = 0
    
    override init() {
        let request = CDSessionAttributes.fetchRequest() as NSFetchRequest<CDSessionAttributes>
        
        let sort = NSSortDescriptor(key: #keyPath(CDSessionAttributes.startTime), ascending: false)
        request.sortDescriptors = [sort]
        
        controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: #keyPath(CDSessionAttributes.session.day),
            cacheName: nil)
        
        super.init()
        
        controller.delegate = self
        try? controller.performFetch()
        self.generateSectionDictionary()
        
    }
    
    fileprivate class WeakDatabaseOberver {
        private(set) weak var value: PracticeDatabaseObserver?
        
        init(value: PracticeDatabaseObserver?) {
            self.value = value
        }
    }
    
    private var observers : [WeakDatabaseOberver] = []
    
    func addObserver(_ observer: PracticeDatabaseObserver) {
        self.observers = self.observers.filter({ $0.value != nil }) // Trim
        self.observers.append( WeakDatabaseOberver(value: observer)  ) // Append
    }
    
    func removeObserver(_ observer: PracticeDatabaseObserver) {
        self.observers = self.observers.filter({
            guard let value = $0.value else { return false }
            return !(value === observer)
        })
    }
    
}

//MARK: - Public API
extension PracticeDatabase {
    
    public func sessions(for day: Day) -> [CDSessionAttributes]? {
        if let section = sectionDictionary[day] {
            if let sessions = controller.sections?[section].objects as? [CDSessionAttributes] {
                return sessions.isEmpty ? nil : sessions
            }
        }
        return nil
    }
    
    public func sessions(for day: Day, profile: CDProfile?) -> [CDSessionAttributes]? {
        if let section = sectionDictionary[day] {
            if let sessions = controller.sections?[section].objects as? [CDSessionAttributes], !sessions.isEmpty {
                if let profile = profile {
                    return sessions.filter { $0.session?.profile == profile }
                }
                else {
                    return sessions
                }
            }
        }
        return nil
    }
    
    public func sessionExists(for day: Day) -> Bool {
        return sectionDictionary[day] != nil
    }
    
    public func sessionExists(for day: Day, profile: CDProfile) -> Bool {
        if let section = sectionDictionary[day] {
            if let sessions = controller.sections?[section].objects as? [CDSessionAttributes], !sessions.isEmpty {
                for session in sessions {
                    if session.session?.profile == profile {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }
    
    public func sessions() -> [CDSessionAttributes] {
        return controller.fetchedObjects ?? []
    }
    
    public func streak(for profile: CDProfile?) -> Int {
        if let profile = profile {
            return self.streaks[profile] ?? 0
        }
        return self.totalStreak
    }
    
    public func reloadStreak() {
        print("reloading")
        func getStreak(for profile: CDProfile?) -> Int {
            var streak = 0
            var day = Day(date: Date())
            
            func sessionExists(_ day: Day) -> Bool {
                if let profile = profile {
                    return self.sessionExists(for: day, profile: profile)
                }
                else {
                    return self.sessionExists(for: day)
                }
            }
            
            //streak doesnt reset if you havent practiced yet today, but it does increase if you have
            if sessionExists(day) {
                streak = 1
            }
            
            day = day.previousDay()
            
            while sessionExists(day) {
                streak += 1
                
                day = day.previousDay()
            }
            
            return streak
        }
        
        let totalStreak = getStreak(for: nil)
        if self.totalStreak != totalStreak {
            self.totalStreak = totalStreak
            self.observers.forEach { $0.value?.practiceDatabase(self, didChangeTotalStreak: totalStreak) }
        }
        
        for profile in CDProfile.getAllProfiles(context: DataManager.context) {
            let streak = getStreak(for: profile)
            
            if streak != self.streaks[profile] {
                self.streaks[profile] = streak
                self.observers.forEach { $0.value?.practiceDatabase(self, streakDidChangeFor: profile, streak: streak) }
            }
        }
        
    }
    
}

//MARK: - Private API
extension PracticeDatabase {
    
    private func generateSectionDictionary() {
        sectionDictionary = [:]
        
        if let sections = controller.sections {
            for (i, section) in sections.enumerated() {
                if section.name.isEmpty == false {
                    sectionDictionary[Day(string: section.name)] = i
                }
            }
        }
        
        reloadStreak()
        
    }
    
}

extension PracticeDatabase: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        WidgetDataManager.writeData()
        self.generateSectionDictionary()
        
        self.observers.forEach { $0.value?.practiceDatabaseDidUpdate(self) }
        
        NotificationCenter.default.post(
            name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
    }
    
    
}
