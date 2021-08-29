//
//  SessionsViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/20/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import Combine
import CoreData

struct PracticeDay {
    var day: Day
    var sessions: [CDSession] = []
}

class SessionsViewController: MainViewController, SessionsSearchBarDelegate, CalendarScrollViewDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FetchedObjectControllerDelegate {
    
    var layout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    public let searchBarView = SessionsSearchBar()
    
    enum Filter {
        case recordings, notes, favorited
    }
    
    public var filters = Set<Filter>()
    
    public var searchQuery = ""
    
    public var didLoad = false
    
    private let filterInfoHeader = FilterInfoCell()
    
    private let sessionCalendarView = CalendarScrollView()
    private weak var sessionCalendarDetailViewController: CalendarDetailAlertController?
    private var shouldDisplaySessionCalendarView = false
            
    private let visibleDateView = VisibleDateView()
        
    private var isDisplayingStandardTime: Bool!
    
    private var emptyStateView: SessionsEmptyStateView?
    
    public var fetchedObjectController: FetchedObjectCollectionViewController<CDSession>!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Andante"
        
        view.backgroundColor = Colors.backgroundColor
        
        isDisplayingStandardTime = Settings.standardTime
        
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.vertical
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.showsHorizontalScrollIndicator = false
        
        contentView.addSubview(collectionView)
        self.scrollView = collectionView
        collectionView.contentInsetAdjustmentBehavior = .never
        
        setTopView(searchBarView)
           
        NotificationCenter.default.addObserver(self, selector: #selector(dismissDetailView), name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)

        collectionView.backgroundColor = .clear

        searchBarView.delegate = self

        collectionView.keyboardDismissMode = .onDrag
        collectionView.alwaysBounceVertical = true

        collectionView.register(PracticeSessionCollectionCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.register(PracticeDayCollectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
        
        collectionView.delegate = self
        
        collectionView.contentInset.left = Constants.xsMargin - 4
        collectionView.contentInset.right = Constants.xsMargin - 4
        
        sessionCalendarView.delegate = self
        collectionView.addSubview(sessionCalendarView)
        self.additionalTopInset = 124
        
        filterInfoHeader.bounds.size.height = 46
        
        filterInfoHeader.clearFiltersHandler = {
            self.clearFilters()
        }
        
        visibleDateView.alpha = 0
        collectionView.addSubview(visibleDateView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        didLoad = true
        
        collectionView.alpha = 0
        
        loadSavedData()
        
        if fetchedObjectController != nil {
            fetchedObjectController.performFetch()
        }
        
        
    }
    
    override func dayDidChange() {
        super.dayDidChange()
        
        sessionCalendarView.dayDidChange()
        
    }
    
    private func updateFetchRequest() {
        guard let profile = User.getActiveProfile() else { return }
        
        var predicates: [NSPredicate] = [NSPredicate(format: "profile == %@", profile)]
                
        if filters.contains(.favorited) {
            predicates.append(NSPredicate(format: "isFavorited == TRUE"))
        }
        
        if filters.contains(.notes) {
            predicates.append(NSPredicate(format: "notes != %@", ""))
        }
        
        if filters.contains(.recordings) {
            predicates.append(NSPredicate(format: "recordings.@count != 0"))
        }
        
        if searchQuery != "" {
            let queries = searchQuery.split(separator: " ")
            
            var queryPredicates: [NSPredicate] = []
            
            for query in queries {
                let matchString = NSString(format: ".*\\b%@.*", String(query))
                queryPredicates.append(NSCompoundPredicate(orPredicateWithSubpredicates: [
                    NSPredicate(format: "title MATCHES[c] %@", matchString),
                    NSPredicate(format: "notes MATCHES[c] %@", matchString)
                ]))
            }
            
            let searchPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: queryPredicates)
            predicates.append(searchPredicate)
        }
        
        let predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        
        fetchedObjectController.controller.fetchRequest.predicate = predicate
        fetchedObjectController.performFetch()
        
    }
    
    private func loadSavedData() {
        guard let profile = User.getActiveProfile() else { return }
        
        let request = CDSession.fetchRequest() as NSFetchRequest<CDSession>
        let sort = NSSortDescriptor(key: #keyPath(CDSession.d_startTime), ascending: false)
        request.sortDescriptors = [sort]
        request.fetchBatchSize = 20
        
        request.predicate = NSPredicate(format: "profile == %@", profile)
        
        fetchedObjectController = FetchedObjectCollectionViewController(
            collectionView: collectionView,
            fetchRequest: request,
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: #keyPath(CDSession.day))
        
        fetchedObjectController.delegate = self
                
        fetchedObjectController.cellProvider = {
            (collectionView, indexPath, session) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "cell",
                for: indexPath) as? PracticeSessionCollectionCell
            
            cell?.setSession(session)
            cell?.setSearchText(self.searchQuery)
            
            if let cell = cell {
                return cell
            } else {
                return UICollectionViewCell()
            }
            
        }
        
        fetchedObjectController.supplementaryViewProvider = {
            (collectionView, kind, indexPath) in
            
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! PracticeDayCollectionHeader
            
            let snapshot = self.fetchedObjectController.dataSource.snapshot()
            header.day = Day(string: snapshot.sectionIdentifiers[indexPath.section])
            
            return header
        }

        
    }
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        //shouldDisplaySessionCalendarView = isEmpty == false
                
        if isEmpty {
            let isFiltering = filters.count > 0 || searchQuery.isEmpty == false

            if let emptyStateView = emptyStateView {
                if isFiltering {
                    emptyStateView.setNoFilteredSessionsText()
                }
                else {
                    emptyStateView.setNoSessionsText()
                }
                
                emptyStateView.alpha = 1
                setCalendarHidden(true)
            }
            else {
                emptyStateView = SessionsEmptyStateView()
                emptyStateView?.alpha = 0
                view.insertSubview(emptyStateView!, at: 0)
                
                if isFiltering {
                    emptyStateView?.setNoFilteredSessionsText()
                }
                else {
                    emptyStateView?.setNoSessionsText()
                }
                
                UIView.animate(withDuration: 0.3) {
                    self.emptyStateView?.alpha = 1
                    self.setCalendarHidden(true)
                }
                
            }
            
            collectionView.isScrollEnabled = false
        }
        else {
            self.emptyStateView?.alpha = 0
            self.emptyStateView?.removeFromSuperview()
            self.collectionView.backgroundView = nil
            self.emptyStateView = nil
            
            setCalendarHidden(false)
            
            collectionView.isScrollEnabled = true
            
        }
    }
    
    func setCalendarHidden(_ hidden: Bool) {
        if hidden {
            guard additionalTopInset != 0 || sessionCalendarView.alpha != 0 else { return }
            sessionCalendarView.alpha = 0
            additionalTopInset = 0
            viewDidLayoutSubviews()
        }
        else {
            guard additionalTopInset != 124 || sessionCalendarView.alpha != 1 else { return }
            guard filters.count == 0 && !isBotViewFocused else { return }
            sessionCalendarView.alpha = 1
            additionalTopInset = 124
            viewDidLayoutSubviews()
        }
    }
    
    @objc func dismissDetailView() {
        sessionCalendarDetailViewController?.close()
    }

    private func reloadTimeFormat() {
        if Settings.standardTime != isDisplayingStandardTime {
            isDisplayingStandardTime = Settings.standardTime
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
    }
    
    @objc func willEnterForeground() {
        reloadTimeFormat()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        reloadTimeFormat()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        
    }
    
    private var bottomSafeArea: CGFloat {
        return containerViewController.isSidebarEnabled ? view.safeAreaInsets.bottom : 0
    }
    
    public func showTooltip(_ completion: (()->Void)?) {
        if ToolTips.didShowSessionsTooltip == false {
            let tutorialPopup = TutorialAlertController.SessionsTutorial()
            
            let frame = self.view.convert(self.view.bounds, to: self.view.window)
            tutorialPopup.relativePoint = CGPoint(
                x: frame.maxX - 43,
                y: frame.maxY - bottomSafeArea - 96)
            
            tutorialPopup.closeCompletion = {
                ToolTips.didShowSessionsTooltip = true
                completion?()
            }
            
            tutorialPopup.show(self)
        }
    }
    
    private func animateCollectionView() {
        let width = collectionView.bounds.inset(by: collectionView.contentInset).width
        
        let offset: CGFloat = (width/2 >= 355) ? 0 : 20
        var currentOffset: CGFloat = 40
                    
        for indexPath in collectionView.indexPathsForVisibleItems.sorted() {
            currentOffset += offset
            
            if indexPath.row == 0 {
                collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath)?.transform = CGAffineTransform(translationX: 0, y: currentOffset)
                currentOffset += offset
            }
            
            collectionView.cellForItem(at: indexPath)?
                .transform = CGAffineTransform(translationX: 0, y: currentOffset)
            
        }
        
        UIView.animateWithCurve(duration: 0.7, delay: 0, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
            self.collectionView.alpha = 1
            for indexPath in self.collectionView.indexPathsForVisibleItems {
                if indexPath.row == 0 {
                    self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: indexPath)?.transform = .identity
                }
                self.collectionView.cellForItem(at: indexPath)?
                    .transform = .identity
            }
        }, completion: nil)
    }
    
    public func animate(_ delayTooltip: Bool = false) {
        
        if delayTooltip == false && ToolTips.didShowSessionsTooltip == false {
            showTooltip {
                [weak self] in
                guard let self = self else { return }
                self.collectionView.alpha = 0
                self.collectionView.isHidden = false
                UIView.animate(withDuration: 0.6) {
                    self.collectionView.alpha = 1
                }
            }
        }
        else {
            animateCollectionView()
        }
                    
    }
    
    func didSelectCalendarCell(_ day: Day, sourceView: UIView?) {
        let popup = CalendarDetailAlertController(day: day)
        
        popup.sessionHandler = { session in
            let detailVC = SessionDetailViewController()
            detailVC.session = session
            self.present(detailVC, animated: false, completion: nil)
        }
        
        popup.newSessionHandler = {
            popup.closeCompletion = {
                [weak self] in
                guard let self = self else { return }
                let vc = ManualSessionViewController()
                vc.calendarPicker.setInitialDay(day)
                self.containerViewController?.present(vc, animated: true, completion: nil)
            }
            popup.close()
            self.sessionCalendarDetailViewController = nil
        }
        
        self.sessionCalendarDetailViewController = popup
        let sourceRect = sourceView?.bounds.offsetBy(dx: 0, dy: 4)
        self.presentAlert(
            popup,
            sourceView: sourceView,
            sourceRect: sourceRect,
            arrowDirection: .up)
    }
    
    @objc func reloadAttributes() {
        
    }
    
    @objc func reloadAllData() {
        
    }
    
    private func addFilter(_ filter: SessionsViewController.Filter) {
        filters.insert(filter)
        filterInfoHeader.filterCount = filters.count
        
        if filters.count == 1 {
            setNavAccessoryView(filterInfoHeader)
        }
        
        updateFilterUI()
        updateFetchRequest()
    }
    
    private func removeFilter(_ filter: SessionsViewController.Filter) {
        filters.remove(filter)
        filterInfoHeader.filterCount = filters.count
        
        if filters.count == 0 {
            removeNavAccessoryView()
        }
        
        updateFilterUI()
        updateFetchRequest()
    }
    
    private func clearFilters() {
        filters.removeAll()
        
        removeNavAccessoryView()
        
        updateFilterUI()
        updateFetchRequest()
    }
    
    private func updateFilterUI() {
        if filters.count == 0 && searchQuery == "" {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.setCalendarHidden(false)
            }, completion: nil)
            
        }
        else {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.setCalendarHidden(true)
            }, completion: nil)
        }
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if containerViewController.isSidebarEnabled {
            collectionView.contentInset.bottom = 62 + 28
        }
        else {
            collectionView.contentInset.bottom = 56 + 28
        }
        
        collectionView.frame = view.bounds
        emptyStateView?.frame = view.bounds
        
        sessionCalendarView.frame = CGRect(
            x: -collectionView.contentInset.left,
            y: 28 - 124,
            width: self.view.bounds.width,
            height: 76)
        
        visibleDateView.bounds.size.width = self.view.bounds.width
        visibleDateView.center.x = self.view.bounds.midX
        
        let width = collectionView.bounds.inset(by: collectionView.contentInset).width
        
        if width/3 >= 355 {
            layout.itemSize = CGSize(width: width/3, height: 88)
        } else if width/2 >= 355 {
            layout.itemSize = CGSize(width: width/2, height: 88)
        } else {
            layout.itemSize = CGSize(width: width, height: 88)
        }
        
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll(scrollView: scrollView)
        
        if scrollView.contentSize.height == 0 || scrollView.contentSize.height < self.view.bounds.height*2 {
            visibleDateView.setDay(nil)
            return
        }
        
        let totalContentHeight: CGFloat = scrollView.contentSize.height + scrollView.contentInset.top + scrollView.contentInset.bottom
        
        let safeAreaBottom: CGFloat = containerViewController.isSidebarEnabled ? view.safeAreaInsets.bottom : 0
        
        let margin: CGFloat = 2 //space above and below the scroll indicator
        let visibleHeight: CGFloat =
            scrollView.bounds.height
            - (scrollView.contentInset.top - additionalTopInset)
            - margin*2
            - safeAreaBottom
        
        let offset = scrollView.contentOffset.y + scrollView.contentInset.top
        let scrollPercent = offset / totalContentHeight
        
        let scrollBarPosition = margin + (offset - additionalTopInset) + scrollPercent * visibleHeight
        
        let indicatorHeight = (scrollView.bounds.height / totalContentHeight) * visibleHeight
        
        let diff: CGFloat = max(0, 38 - indicatorHeight)
        visibleDateView.bounds.size.height = max(38, indicatorHeight)
        visibleDateView.center.y = scrollBarPosition + visibleDateView.bounds.height/2 - (diff*scrollPercent)
        
        var foundSection = false
        
        for section in collectionView.visibleSections() {
            let rect = collectionView.rect(for: section)
            let dateY = visibleDateView.center.offset(dx: 0, dy: -15).y
            
            if rect.minY <= dateY && rect.maxY >= dateY {
                foundSection = true
                let snapshot = fetchedObjectController.dataSource.snapshot()
                let day = Day(string: snapshot.sectionIdentifiers[section])
                visibleDateView.setDay(day)
                break
            }
        }
        
        if !foundSection {
            visibleDateView.setDay(nil)
        }
        
        
        collectionView.bringSubviewToFront(visibleDateView)

    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.4, delay: 0.3, options: [.curveEaseInOut], animations: {
            self.visibleDateView.alpha = 0
        }, completion: nil)
    }
        
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewWillDrag()
        UIView.animate(withDuration: 0.15) {
            self.visibleDateView.alpha = 1
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        willEndScroll(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
        
        if velocity.y == 0 {
            self.scrollViewDidEndDecelerating(collectionView)
        }
    }
    
    override func pageReselected() {
        scrollToTop(scrollView: self.collectionView)
    }
    
    public var lastAddedSessionIndexPath: IndexPath?
        
    override func didAddSession(session: CDSession) {
        
    }
    
    override func didChangeProfile(profile: CDProfile) {
        if !didLoad {
            return
        }
        
        if fetchedObjectController != nil {
            updateFetchRequest()
        } else {
            loadSavedData()
            fetchedObjectController.performFetch()
        }
              
    }
    
    func didTapFilterButton() {
        let menu = PopupMenuViewController()
        menu.width = 208
        menu.relativePoint = self.view.convert(CGPoint(x: headerFrame.maxX - 50, y: headerFrame.maxY - 20), to: self.view.window!)
        
        menu.setScrollview(collectionView)
        
        menu.addTitleItem(title: "Filters")
        
        menu.addSwitchItem(title: "Favorites", isOn: filters.contains(.favorited)) { (isOn) in
            if isOn {
                self.addFilter(.favorited)
            }
            else {
                self.removeFilter(.favorited)
            }
        }
                
        menu.addSwitchItem(title: "Recordings", isOn: filters.contains(.recordings)) { (isOn) in
            if isOn {
                self.addFilter(.recordings)
            }
            else {
                self.removeFilter(.recordings)
            }
        }
        
        menu.addSwitchItem(title: "Notes", isOn: filters.contains(.notes)) { (isOn) in
            if isOn {
                self.addFilter(.notes)
            }
            else {
                self.removeFilter(.notes)
            }
        }
        
        menu.addSpacer(height: 8)
        menu.addTitleItem(title: "Sessions")
        menu.addItem(title: "Add a session", icon: nil, handler: {
            let vc = ManualSessionViewController()
            self.containerViewController?.present(vc, animated: true, completion: nil)
        })
       
        menu.show(self)
    }
    
    func searchDidUpdate(searchText: String) {
        searchQuery = searchText
        
        updateFetchRequest()
        
        collectionView.visibleCells.forEach { (cell) in
            (cell as? PracticeSessionCollectionCell)?.setSearchText(searchText)
        }
    }
    
    func searchDidBecomeFirstResponder() {
        if !isBotViewFocused {
            setBotViewFocused(true)
            searchBarView.setSearching(true)
            
            
            UIView.animateWithCurve(duration: 0.3, curve: UIView.CustomAnimationCurve.cubic.easeOut) {
                self.setCalendarHidden(true)
            } completion: { }
        }
    }
    
    func searchDidCancel() {
        self.additionalTopInset = 124
        self.sessionCalendarView.alpha = 1
        setBotViewFocused(false)
        searchBarView.setSearching(false)
    }
    
    func searchDidResignFirstResponder() {
        
    }
    
}

//MARK: Delegates
extension SessionsViewController {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let baseHeight: CGFloat = view.traitCollection.horizontalSizeClass == .compact ? 52 : 62
        return CGSize(
            width: collectionView.bounds.inset(by: collectionView.contentInset).width,
            height: baseHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        searchBarView.stopEditing()
        
        if let session = fetchedObjectController.object(at: indexPath) {
            let vc = SessionDetailViewController()
            
            vc.indexPath = indexPath
            vc.session = session
            
            self.present(vc, animated: false, completion: nil)
        }
        
    }
    
    
}



//MARK: Search bar
protocol SessionsSearchBarDelegate: AnyObject {
    func didTapFilterButton()
    func searchDidUpdate(searchText: String)
    func searchDidBecomeFirstResponder()
    func searchDidResignFirstResponder()
    func searchDidCancel()
}

class SessionsSearchBar: HeaderAccessoryView, UITextFieldDelegate {
    
    public weak var delegate: SessionsSearchBarDelegate?
    
    private let textField = UITextField()
    private let searchIcon = UIImageView()
    private let clearButton = UIButton(type: .system)
    private let filterButton = PushButton()
    private let contentView = UIView() //for alpha purposes
    private let bgView = HighlightButton()
    
    public let cancelButton = UIButton(type: .system)
    
    private var isSearching = false
    
    private let tapFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        super.init(frame: .zero)
                        
        self.addSubview(bgView)
        bgView.backgroundColor = Colors.searchBarColor
        bgView.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = false
        bgView.addSubview(contentView)
        
        searchIcon.image = UIImage(named: "SearchIcon")
        searchIcon.setImageColor(color: Colors.lightText)
        contentView.addSubview(searchIcon)
        
        clearButton.setImage(UIImage(name: "xmark.circle.fill", pointSize: 14, weight: .semibold), for: .normal)
        clearButton.tintColor = Colors.extraLightText
        clearButton.addTarget(self, action: #selector(didTapClear), for: .touchUpInside)
        clearButton.isHidden = true
        self.addSubview(clearButton)
        
        filterButton.image = UIImage(named: "filter")
        filterButton.imageColor = Colors.white
        filterButton.backgroundColor = Colors.orange
        filterButton.tintColor = Colors.lightText
        
        if traitCollection.userInterfaceStyle == .dark {
            filterButton.buttonView.setShadow(radius: 5, yOffset: 2, opacity: 0.02)
        }
        else {
            filterButton.buttonView.setShadow(radius: 5, yOffset: 2, opacity: 0.14)
        }
        
        filterButton.action = {
            [weak self] in
            self?.didTapFilterButton()
        }
        self.addSubview(filterButton)
                
        textField.tintColor = Colors.orange
        textField.attributedPlaceholder = NSAttributedString(string: "Search", attributes: [
            NSAttributedString.Key.font : Fonts.medium.withSize(17),
            NSAttributedString.Key.foregroundColor : Colors.lightText
        ])
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
        textField.font = Fonts.medium.withSize(17)
        textField.textColor = Colors.text
        textField.returnKeyType = .done
        textField.delegate = self
        contentView.addSubview(textField)
        
        tapFeedback.prepare()
        
        cancelButton.setTitle("Cancel", color: Colors.orange, font: Fonts.medium.withSize(17))
        cancelButton.isHidden = true
        cancelButton.addTarget(self, action: #selector(didTapCancel), for: .touchUpInside)
        self.addSubview(cancelButton)
    }
    
    @objc func didTapCancel() {
        delegate?.searchDidCancel()
    }
    
    @objc func textChanged() {
        delegate?.searchDidUpdate(searchText: textField.text ?? "")

        clearButton.isHidden = textField.text == ""
        searchIcon.isHidden = textField.text != ""
    }
    
    @objc func didTapFilterButton() {
        tapFeedback.impactOccurred()
        self.delegate?.didTapFilterButton()
    }
    
    @objc func didTap() {
        contentView.isUserInteractionEnabled = true
        textField.becomeFirstResponder()
        delegate?.searchDidBecomeFirstResponder()
    }
    
    @objc func didTapClear() {
        textField.text = ""
        textChanged()
    }
    
    public func stopEditing() {
        textField.resignFirstResponder()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        contentView.isUserInteractionEnabled = false
        delegate?.searchDidResignFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func setHideProgress(_ progress: CGFloat) {
        let alpha = 1 - (progress*4)
        
        contentView.alpha = alpha
        filterButton.alpha = alpha
        clearButton.alpha = alpha
        
        if progress > 0.3 {
            self.alpha = 1 - (progress - 0.3)*4
        }
        else {
            self.alpha = 1
        }
    }
    
    public func setSearching(_ searching: Bool) {
        if !searching {
            textField.resignFirstResponder()
            textField.text = ""
            textChanged()
        }
        
        self.isSearching = searching
        self.cancelButton.alpha = searching ? 0 : 1
        self.cancelButton.isHidden = false
        
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.95, initialSpringVelocity: 0, options: .curveEaseOut) {
            self.cancelButton.alpha = searching ? 1 : 0
            self.layoutSubviews()
        } completion: { complete in
            self.cancelButton.isHidden = searching ? false : true
        }

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = max(0, HeaderView.accessoryHeight - 28)
        let barWidth: CGFloat
        
        if isSearching {
            let width = cancelButton.titleLabel!.sizeThatFits(self.bounds.size).width
            cancelButton.frame = CGRect(
                x: self.bounds.maxX - Constants.smallMargin - width, y: bounds.midY - height/2 - 4,
                width: width, height: height)
            barWidth = self.bounds.width - width - Constants.smallMargin*2 - 10
        } else {
            let width = cancelButton.titleLabel!.sizeThatFits(self.bounds.size).width
            cancelButton.frame = CGRect(
                x: self.bounds.maxX - Constants.smallMargin, y: bounds.midY - height/2 - 2,
                width: width, height: height)
            barWidth = self.bounds.width - Constants.smallMargin*2
        }
        
        if isSidebarLayout {
            setHideProgress(0)
            
            bgView.frame = CGRect(
                x: Constants.smallMargin,
                y: bounds.midY - height/2 - 2,
                width: barWidth,
                height: height)

        }
        else {
            setHideProgress(1 - (self.bounds.height / HeaderView.accessoryHeight))
            
            bgView.frame = CGRect(
                x: Constants.smallMargin,
                y: 10,
                width: barWidth,
                height: max(0, self.bounds.height - 28))
        }
        
        
        
        if bgView.bounds.height < height {
            bgView.roundCorners(min(bgView.bounds.height/2, 12))
        }
        else {
            bgView.roundCorners(12)
        }
                        
        contentView.frame = bgView.bounds
        
        let frame = CGRect(x: 6, y: bgView.bounds.midY - height/2 - 1, width: height, height: height)
        searchIcon.bounds.size = frame.size
        searchIcon.center = frame.center
                
        clearButton.frame = CGRect(
            x: bgView.frame.minX + 6,
            y: bgView.frame.midY - bgView.bounds.height/2,
            width: 44,
            height: bgView.bounds.height)

        filterButton.inset = UIEdgeInsets(6)
        filterButton.frame = CGRect(
            x: bgView.frame.maxX - 44 - 12,
            y: bgView.frame.midY - bgView.bounds.height/2,
            width: 44 + 12,
            height: bgView.bounds.height)
        
        filterButton.cornerRadius = 8
        
        textField.frame = CGRect(from: CGPoint(x: searchIcon.center.x + height/2 + 2,
                                               y: 0),
                                 to: CGPoint(x: filterButton.frame.minX - 2,
                                             y: bgView.bounds.height))
        
    }
    
    @objc override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.userInterfaceStyle == .dark {
            filterButton.buttonView.setShadow(radius: 5, yOffset: 2, opacity: 0.02)
        }
        else {
            filterButton.buttonView.setShadow(radius: 5, yOffset: 2, opacity: 0.14)
        }
    }
    
}

class HighlightButton: UIButton {
    private let dimView = UIView()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        dimView.isUserInteractionEnabled = false
        
        if traitCollection.userInterfaceStyle == .dark {
            dimView.backgroundColor = UIColor.white.withAlphaComponent(0.025)
        }
        else {
            dimView.backgroundColor = UIColor.black.withAlphaComponent(0.025)
        }
        
        dimView.alpha = 0
        
        self.addSubview(dimView)
        self.clipsToBounds = true
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if traitCollection.userInterfaceStyle == .dark {
            dimView.backgroundColor = UIColor.white.withAlphaComponent(0.025)
        }
        else {
            dimView.backgroundColor = UIColor.black.withAlphaComponent(0.025)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dimView.frame = self.bounds
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                UIView.animate(withDuration: 0.25) {
                    self.dimView.alpha = 1
                }
            }
            else {
                UIView.animate(withDuration: 0.3) {
                    self.dimView.alpha = 0
                }
            }
        }
    }
}

fileprivate class PracticeDayCollectionHeader: UICollectionReusableView {
    
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        label.textColor = Colors.text
        self.addSubview(label)
        
    }
    
    public var day: Day? {
        didSet {
            if let day = day {
                var text = ""
                if day.date.isTheSameDay(as: Date()) {
                    text = "Today"
                }
                else {
                    text = day.date.string(template: "MMM d")
                }
                label.text = text
                
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if traitCollection.horizontalSizeClass == .compact {
            label.font = Fonts.semibold.withSize(16)
        } else {
            label.font = Fonts.bold.withSize(16)
        }
        
        label.sizeToFit()
        label.frame = CGRect(
            x: Constants.margin/2,
            y: bounds.maxY - label.bounds.height - 7,
            width: self.bounds.width - Constants.margin,
            height: label.bounds.height)
        
        
    }
}

fileprivate class FilterCell: UIView {
    
    private let label = UILabel()
    private let button = UISwitch()
    
    public var switchHandler: ((_: Bool)->Void)?
    
    public var isOn: Bool {
        get {
            return button.isOn
        }
        set {
            button.setOn(newValue, animated: false)
        }
    }
    
    init(_ filterText: String) {
        super.init(frame: .zero)
        
        self.backgroundColor = .clear
        
        label.text = filterText
        label.font = Fonts.regular.withSize(16)
        label.textColor = Colors.text
        label.textAlignment = .center
        self.addSubview(label)
        
        button.onTintColor = Colors.green
        button.addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
        self.addSubview(button)
        
        
    }
    
    @objc func valueDidChange() {
        switchHandler?(button.isOn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds
        button.sizeToFit()
        button.frame.origin = CGPoint(x: self.bounds.maxX - 20 - button.bounds.width,
                                      y: self.bounds.midY - button.bounds.height/2)
        
    }
}

fileprivate class FilterInfoCell: UIView {
        
    public var filterCount: Int = 0 {
        didSet {
            if filterCount > 0 {
                label.text = "\(filterCount) filter\(filterCount == 1 ? "" : "s")"
            }
        }
    }
    
    public var clearFiltersHandler: (()->Void)?
    
    private var label = UILabel()
    private var button = UIButton(type: .system)
    
    private let separator = Separator(position: .top)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(separator)
        
        label.font = Fonts.semibold.withSize(16)
        label.textColor = Colors.text
        self.addSubview(label)
        
        button.setTitle("Clear filters", for: .normal)
        button.setTitleColor(Colors.orange, for: .normal)
        button.titleLabel?.font = Fonts.semibold.withSize(15)
        button.contentHorizontalAlignment = .right
        button.titleEdgeInsets.right = Constants.margin + 2
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        self.addSubview(button)
        
        
        
    }
    
    @objc func didTapButton() {
        self.clearFiltersHandler?()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        separator.frame = self.bounds
        
        label.frame = self.bounds.inset(by: UIEdgeInsets(top: 0, left: Constants.margin, bottom: 0, right: Constants.margin))
        
        button.frame = CGRect(x: self.bounds.maxX - 120,
                              y: 0,
                              width: 120, height: self.bounds.height)
                
    }
}

extension UITableView {
    func visibleSections() -> [Int] {
        var sections = Set<Int>()
        for indexPath in self.indexPathsForVisibleRows ?? [] {
            sections.insert(indexPath.section)
        }
        return Array(sections)
    }
}

extension UICollectionView {
    func visibleSections() -> [Int] {
        var sections = Set<Int>()
        for indexPath in self.indexPathsForVisibleItems {
            sections.insert(indexPath.section)
        }
        return Array(sections)
    }
    
    func rect(for section: Int) -> CGRect {
        
        let rows = self.numberOfItems(inSection: section)

        let firstFrame = self.layoutAttributesForItem(at: IndexPath(row: 0, section: section))?.frame ?? .zero
        let lastFrame = self.layoutAttributesForItem(at: IndexPath(row: rows-1, section: section))?.frame ?? .zero

        let headerHeight: CGFloat = traitCollection.horizontalSizeClass == .compact ? 52 : 62
        
        return CGRect(
            from: CGPoint(x: 0, y: firstFrame.minY - headerHeight),
            to: CGPoint(x: lastFrame.maxX, y: lastFrame.maxY))
        
    }
    
}

fileprivate class VisibleDateView: UIView {
    
    private let bgLabel = BackgroundLabel()
    
    private var currentDay: Day? = nil {
        didSet {
            if let day = currentDay {
                bgLabel.label.text = day.date.string(template: "MMM yyyy")
            }
            else {
                bgLabel.label.text = ""
            }
            
            setNeedsLayout()
        }
    }
    
    private var visibleDay: Day? {
        didSet {
            if visibleDay != self.currentDay {
                if currentDay == nil {
                    UIView.animate(withDuration: 0.2) {
                        self.bgLabel.alpha = 1
                    }
                    currentDay = visibleDay
                }
                else if visibleDay == nil {
                    UIView.animate(withDuration: 0.2, animations: {
                        self.bgLabel.alpha = 0
                    }) { (complete) in
                        self.currentDay = nil
                    }
                }
                else {
                    currentDay = visibleDay
                }
                                
            }
        }
    }
    
    public func setDay(_ day: Day?) {
        
        if day != visibleDay {
            self.visibleDay = day
        }
        
    }
    
    init() {
        super.init(frame: .zero)
        
        bgLabel.backgroundColor = Colors.dynamicColor(light: UIColor("#627784"), dark: UIColor("#E1E6EA"))
        bgLabel.setShadow(radius: 7, yOffset: 2, opacity: 0.16)
        bgLabel.inset = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        
        bgLabel.label.font = Fonts.medium.withSize(14)
        bgLabel.label.textColor = Colors.dynamicColor(light: Colors.white, dark: Colors.backgroundColor)
        
        bgLabel.alpha = 0
        self.addSubview(bgLabel)
        
        self.isUserInteractionEnabled = false
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgLabel.sizeToFit()
        bgLabel.center = CGPoint(x: self.bounds.maxX - bgLabel.bounds.width/2 - 9 - Constants.margin/2, y: self.bounds.midY)
        bgLabel.roundCorners()
        
    }
}

fileprivate class SessionsEmptyStateView: UIView {
    
    private let iconView = UIImageView()
    private let label = UILabel()
    
    private var isUsingSystemImage = false
    
    init() {
        super.init(frame: .zero)
        
        iconView.image = UIImage(named: "HomeFill")?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = Colors.dynamicColor(light: Colors.text.withAlphaComponent(0.075), dark: Colors.lightColor)
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)
        
        label.font = Fonts.regular.withSize(16)
        label.numberOfLines = 2
        label.textColor = Colors.lightText
        label.textAlignment = .center
        label.alpha = 0.7
        addSubview(label)
    }
    
    public func setNoSessionsText() {
        iconView.image = UIImage(named: "HomeFill")?.withRenderingMode(.alwaysTemplate)
        isUsingSystemImage = false
        label.text = "Your sessions will\nappear here as you practice."
        setNeedsLayout()
    }
    
    public func setNoFilteredSessionsText() {
        iconView.image = UIImage(name: "magnifyingglass", pointSize: 120, weight: .regular)
        isUsingSystemImage = true
        label.text = "Couldn't find any sessions\nthat match your current filters."
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize: CGSize
        if isUsingSystemImage {
            iconSize = iconView.image?.size ?? CGSize.zero
        } else {
            iconSize = CGSize(min(160, bounds.width * 0.4))
        }
        
        label.bounds.size = label.sizeThatFits(self.bounds.size)
        
        let minY = bounds.midY - (label.bounds.height + 20 + iconSize.height)/2 + 40
        
        iconView.bounds.size = iconSize
        iconView.frame.origin = CGPoint(
            x: bounds.midX - iconSize.width/2, y: minY)
        
        label.frame.origin = CGPoint(
            x: bounds.midX - label.bounds.width/2,
            y: iconView.frame.maxY + 20)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
}
