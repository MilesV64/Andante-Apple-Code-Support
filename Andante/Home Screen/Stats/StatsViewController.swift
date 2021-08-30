//
//  StatsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/15/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine

class StatsViewController: MainViewController {
    
    public static var compactBreakpoint: CGFloat = 700
    
    private let headerView = StatsHeaderView()
    
    var lastReload: Day?
    
    private let totalsView = TotalsStatView()
    private let activityView = ActivityStatView()
    private let practicedView = PracticeTimeStatView()
    private let moodView = MoodFocusStatView(.mood)
    private let focusView = MoodFocusStatView(.focus)
    
    private let operationQueue = OperationQueue()
    
    private var needsReload = true
    
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Stats"
        
        self.scrollView = CancelTouchScrollView()
        
        scrollView!.alwaysBounceVertical = true
        scrollView!.contentInsetAdjustmentBehavior = .never
        scrollView!.backgroundColor = Colors.backgroundColor
        scrollView!.delegate = self
        contentView.addSubview(scrollView!)
        
        setTopView(headerView)
        
        headerView.button.action = {
            let vc = GoalDetailViewController()
            vc.popoverPresentationController?.sourceView = self.headerView
            vc.popoverPresentationController?.sourceRect = CGRect(
                x: self.headerView.bounds.midX - 4, y: self.headerView.bounds.midY + 20,
                width: 8, height: 8)
            self.present(vc, animated: true, completion: nil)
        }
        
        scrollView!.addSubview(totalsView)
        
        scrollView!.addSubview(activityView)
        
        practicedView.delegate = self
        scrollView!.addSubview(practicedView)
        
        moodView.delegate = self
        scrollView!.addSubview(moodView)
        
        focusView.delegate = self
        scrollView!.addSubview(focusView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleNeedsReloadNotification), name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
                
        
        monitorDailyGoal()
        
    }
    
    private func monitorDailyGoal() {
        cancellables.removeAll()
        User.getActiveProfile()?.publisher(for: \.dailyGoal, options: .new).sink {
            [weak self] goal in
            guard let self = self else { return }
            self.activityView.reloadData()
            self.headerView.reloadData()
        }.store(in: &cancellables)
    }
    
    @objc func handleNeedsReloadNotification() {
        print("did change")
        reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if needsReload {
            reloadData()
            needsReload = false
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !ToolTips.didShowGoalTooltip {
            let tutorialPopup = TutorialAlertController.GoalTutorial()
            
            tutorialPopup.position = .topMiddle
            
            let rect = headerView.convert(headerView.bounds, to: self.view.window)
            
            tutorialPopup.relativePoint = CGPoint(
                x: rect.center.x,
                y: rect.center.y + 40)
            
            tutorialPopup.closeCompletion = {
                ToolTips.didShowGoalTooltip = true
            }
            
            tutorialPopup.show(self)
        }
        
        
    }
    
    override func dayDidChange() {
        super.dayDidChange()
        reloadData()
    }
    
    private func reloadData() {
        operationQueue.cancelAllOperations()
        
        guard let profile = User.getActiveProfile() else { return }
        
        let context = DataManager.backgroundContext
        let reloadOperation = StatsReloadOperation(context, profileID: profile.objectID)
        
        let dataSources: [StatDataSource] = [totalsView, practicedView, moodView, focusView, activityView]
        dataSources.forEach { reloadOperation.addReloadBlock($0.reloadBlock()) }
        
        operationQueue.addOperation(reloadOperation)
        
        headerView.profile = profile

    }
    
    typealias ReloadBlock = (([CDSessionAttributes])->(()->())?)?
    
    class StatsReloadOperation: Operation {
        
        private let context: NSManagedObjectContext
        private let profileID: NSManagedObjectID
        
        private var reloadBlocks: [ReloadBlock] = []
        
        public func addReloadBlock(_ block: ReloadBlock) {
            reloadBlocks.append(block)
        }
        
        init(_ context: NSManagedObjectContext, profileID: NSManagedObjectID) {
            self.context = context
            self.profileID = profileID
            super.init()

        }
        
        override func main() {
            guard !isCancelled else { return }
            
            guard let profile = try? context.existingObject(with: profileID) else { return }
            let request = CDSessionAttributes.fetchRequest() as NSFetchRequest<CDSessionAttributes>
            request.predicate = NSPredicate(format: "session.profile == %@", profile)
            
            context.performAndWait {
                if let sessions = try? context.fetch(request) {
                    reloadBlocks.forEach { (reloadBlock) in
                        let reloadCompletion = reloadBlock?(sessions)
                        if !isCancelled {
                            reloadCompletion?()
                        }
                    }
                }
            }
            
        }
        
    }
    
        
    override func didAddSession(session: CDSession) {
        
    }
    
    override func didDeleteSession(session: CDSession) {
        
    }
    
    override func didChangeProfile(profile: CDProfile) {
        super.didChangeProfile(profile: profile)
        
        setNeedsReload()
        monitorDailyGoal()
    }
    
    func setNeedsReload() {
        if (self.isViewLoaded && self.view.window != nil) {
            reloadData()
            needsReload = false
        }
        else {
            needsReload = true
        }
    }
    
    override func pageReselected() {
        scrollToTop(scrollView: self.scrollView!)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView!.frame = self.view.bounds
        scrollView?.contentSize.width = self.view.bounds.width
        
        if self.view.bounds.width > StatsViewController.compactBreakpoint {
            layoutRegular()
            totalsView.setCompact(false)
        }
        else {
            layoutCompact()
            totalsView.setCompact(true)
        }
        
    }
    
    private func layoutCompact() {
        totalsView.frame = CGRect(
            x: 0, y: 11,
            width: self.view.bounds.width,
            height: 274)
        
        activityView.frame = CGRect(
            x: Constants.xsMargin, y: totalsView.frame.maxY + 4,
            width: self.view.bounds.width - Constants.xsMargin*2,
            height: ActivityStatView.height)
        
        let height = BaseStatView.height
        
        practicedView.frame = CGRect(
            x: Constants.xsMargin, y: activityView.frame.maxY + 8,
            width: self.view.bounds.width - Constants.xsMargin*2,
            height: height)
        
        moodView.frame = CGRect(
            x: Constants.xsMargin, y: practicedView.frame.maxY + 8,
            width: self.view.bounds.width - Constants.xsMargin*2,
            height: height)
        
        focusView.frame = CGRect(
            x: Constants.xsMargin, y: moodView.frame.maxY + 8,
            width: self.view.bounds.width - Constants.xsMargin*2,
            height: height)
        
        let safeAreaBottom: CGFloat = containerViewController.isSidebarEnabled ? view.safeAreaInsets.bottom : 0
        scrollView!.contentSize.height = focusView.frame.maxY + 16 + safeAreaBottom
    }
    
    private func layoutRegular() {
        
        let width = (self.view.bounds.width - Constants.xsMargin*2 - 8)/2
        
        totalsView.frame = CGRect(
            x: 0, y: 11,
            width: width + Constants.xsMargin*2,
            height: BaseStatView.height + 8)
        
        activityView.frame = CGRect(
            x: Constants.xsMargin, y: totalsView.frame.maxY + 4,
            width: self.view.bounds.width - Constants.xsMargin*2,
            height: ActivityStatView.height)
        
        let height = BaseStatView.height
        
        practicedView.frame = CGRect(
            x: self.view.bounds.midX + 4, y: 15,
            width: width,
            height: height)
        
        moodView.frame = CGRect(
            x: Constants.xsMargin, y: activityView.frame.maxY + 8,
            width: width,
            height: height)
        
        focusView.frame = CGRect(
            x: moodView.frame.maxX + 8, y: moodView.frame.minY,
            width: width,
            height: height)
         
        let safeAreaBottom: CGFloat = containerViewController.isSidebarEnabled ? view.safeAreaInsets.bottom : 0
        let totalHeight = focusView.frame.maxY + 16 + safeAreaBottom
        
        if totalHeight < scrollView!.bounds.height {
            scrollView!.contentSize.height = scrollView!.bounds.height
        } else {
            scrollView!.contentSize.height = totalHeight
        }
        
        
    }
        
}





//MARK: - SrollView
extension StatsViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        didScroll(scrollView: scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewWillDrag()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        willEndScroll(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
}





//MARK: - StatsHeaderView
class StatsHeaderView: HeaderAccessoryView {
    
    private var circles: [ProgressRing] = []
    private var labels: [UILabel] = []
    public let button = CustomButton()
    
    public var profile: CDProfile? {
        didSet {
            reloadData()
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(button)
        button.highlightAction = { isHighlighted in
            if isHighlighted {
                self.circles.forEach { (circle) in
                    circle.alpha = 0.3
                }
            }
            else {
                UIView.animate(withDuration: 0.2) {
                    self.circles.forEach { (circle) in
                        circle.alpha = 1
                    }
                }
            }
        }
        
        for i in 0..<7 {
            let circle = ProgressRing()
            circles.append(circle)
            self.addSubview(circle)
            circle.isUserInteractionEnabled = false
            
            let label = UILabel()
            label.textAlignment = .center
            
            let today = Day(date: Date())
            label.text = String(Formatter.weekdayString(today.addingDays(i - 6).date).prefix(1))
            
            if i == 6 {
                label.font = Fonts.semibold.withSize(15)
                label.textColor = Colors.orange
            }
            else {
                label.font = Fonts.medium.withSize(15)
                label.textColor = Colors.text.withAlphaComponent(0.9)
            }
            labels.append(label)
            circle.addSubview(label)
        }
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
        
    func reloadData() {
        guard let profile = self.profile else { return }
        
        for i in 0..<circles.count {
            let day = Day(date: Date()).addingDays(-6+i)
            if let sessions = PracticeDatabase.shared.sessions(for: day) {
                let practiceTime = sessions.reduce(into: 0) { $0 += ($1.practiceTime) }
                circles[i].animateTo(CGFloat(practiceTime) / CGFloat(profile.dailyGoal))
            }
            else {
                circles[i].animateTo(0)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        let width: CGFloat = min(self.bounds.width - Constants.smallMargin*2, 400)
        let margin = (self.bounds.width - width)/2
        
        let itemSize = (HeaderView.accessoryHeight) - (bounds.width < 360 ? 39 : 36)
        let padding = (width - itemSize*7)/6
        
        let hideProgress: CGFloat
        if isSidebarLayout {
            hideProgress = 0
        } else {
            hideProgress = 1 - (self.bounds.height / (HeaderView.accessoryHeight))
        }
        
        for i in 0..<circles.count {
            let circle = circles[i]
            let frame = CGRect(
                x: margin + CGFloat(i)*(itemSize+padding),
                y: isSidebarLayout ? (bounds.midY - itemSize/2 - 2) : 14,
                width: itemSize, height: itemSize)
            
            circle.bounds.size = frame.size
            circle.center = frame.center
            
            labels[i].frame = circle.bounds
            
            circle.alpha = 1 - hideProgress*1.6
            circle.transform = CGAffineTransform(scaleX: 1 - hideProgress/3, y: 1 - hideProgress/3).concatenating(CGAffineTransform(translationX: 0, y: -itemSize*hideProgress))
            
        }
        
        button.frame = CGRect(
            x: margin/2,
            y: 4,
            width: self.bounds.width - margin,
            height: itemSize + 20)
        
    }
    
}
