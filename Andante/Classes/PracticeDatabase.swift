
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

class PracticeDatabase: NSObject {
    
    public static var PracticeDatabaseDidChangeNotification =
        NSNotification.Name("PracticeDatabaseDidChangeNotification")
    
    public static var PracticeDatabaseStreakDidChangeNotification = NSNotification.Name("PracticeDatabaseStreakDidChangeNotification")
    
    //MARK: - Public attributes
    
    public static var shared = PracticeDatabase()
    
    public var currentProfile: CDProfile? { get {
        return profile
    }}
    
    //MARK: - Private attributes
    
    private var profile: CDProfile?
    private var controller: NSFetchedResultsController<CDSessionAttributes>?
    
    private var sectionDictionary: [ Day : Int ] = [:]
    private var streak = 0
    
    private var widgetController: NSFetchedResultsController<CDSessionAttributes>?
        
    override init() {
        super.init()
        
        let request = CDSessionAttributes.fetchRequest() as NSFetchRequest<CDSessionAttributes>
        
        let sort = NSSortDescriptor(key: #keyPath(CDSessionAttributes.startTime), ascending: false)
        request.sortDescriptors = [sort]
        
        widgetController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: nil, cacheName: nil)
        
        widgetController?.delegate = self
        
        try? widgetController?.performFetch()
        
    }
    
}

//MARK: - Public API
extension PracticeDatabase {
    
    func setProfile(_ profile: CDProfile?) {
        guard profile != nil, profile != self.profile else { return }
        
        self.profile = profile
        updateFetchRequest()
    }
    
    public func sessions(for day: Day) -> [CDSessionAttributes]? {
        if let section = sectionDictionary[day] {
            if let sessions = controller?.sections?[section].objects as? [CDSessionAttributes] {
                return sessions.isEmpty ? nil : sessions
            }
        }
        return nil
    }
    
    public func sessions() -> [CDSessionAttributes] {
        return controller?.fetchedObjects ?? []
    }
    
    public func currentStreak() -> Int {
        return self.streak
    }
    
    public func reloadStreak() {
        var day = Day(date: Date())
        var streak = 0
        
        //streak doesnt reset if you havent practiced yet today, but it does increase if you have
        if sectionDictionary[day] != nil {
            streak += 1
        }
        
        day = day.previousDay()
        while sectionDictionary[day] != nil {
            streak += 1
            day = day.previousDay()
        }
        
        if streak != self.streak {
            self.streak = streak
            NotificationCenter.default.post(
                name: PracticeDatabase.PracticeDatabaseStreakDidChangeNotification, object: nil)
        }
        
    }
    
}

//MARK: - Private API
private extension PracticeDatabase {
    
    func fetchRequest(for profile: CDProfile) -> NSFetchRequest<CDSessionAttributes> {
        let request = CDSessionAttributes.fetchRequest() as NSFetchRequest<CDSessionAttributes>
        
        let sort = NSSortDescriptor(key: #keyPath(CDSessionAttributes.startTime), ascending: false)
        request.sortDescriptors = [sort]
        
        let predicate = NSPredicate(format: "session.profile == %@", profile)
        request.predicate = predicate
        
        return request
    }
    
    func performFetch() {
        do {
            try controller?.performFetch()
        } catch {
            print("PracticeDatabaseFetchController failed to perform fetch: \(error)")
        }
    }
    
    func createFetchedResultsController() {
        guard let profile = self.profile else { return }
        
        self.controller = NSFetchedResultsController(
            fetchRequest: self.fetchRequest(for: profile),
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: #keyPath(CDSessionAttributes.session.day),
            cacheName: nil)
        
        controller?.delegate = self

    }
    
    func updateFetchRequest() {
        guard let profile = self.profile else { return }
        
        if let controller = self.controller {
            controller.fetchRequest.predicate = NSPredicate(format: "session.profile == %@", profile)
        }
        else {
            createFetchedResultsController()
        }
                
        performFetch()
        
        generateSectionDictionary()
        
        NotificationCenter.default.post(
            name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
        
    }
    
    func generateSectionDictionary() {
        sectionDictionary = [:]
        
        if let sections = controller?.sections {
            for (i, section) in sections.enumerated() {
                sectionDictionary[Day(string: section.name)] = i
            }
        }
        
        reloadStreak()
        
    }
    
}

extension PracticeDatabase: NSFetchedResultsControllerDelegate {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == widgetController {
            WidgetDataManager.writeData()
        }
        else {
            self.generateSectionDictionary()
            
            NotificationCenter.default.post(
                name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
        }
        
    }
    
    
}
