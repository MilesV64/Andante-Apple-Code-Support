//
//  JournalViewController.swift
//  Andante
//
//  Created by Miles Vinson on 2/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine

class JournalViewController: MainViewController, JournalHeaderDelegate, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FetchedObjectControllerDelegate {
    
    var listLayout: UICollectionViewFlowLayout!
    var gridLayout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    enum EntryLayout: Int {
        case grid, list
    }
    
    var entryLayout: EntryLayout = .list
    
    private var firstAppear = true
    
    private let headerView = JournalHeaderView()
    private var folder: CDJournalFolder?
    
    private var didLoad = false
        
    private var emptyStateView: JournalEmptyStateView?
    
    private var folderOptionsButton: UIButton?
    
    public var fetchedObjectController: FetchedObjectCollectionViewController<CDJournalEntry>!
    
    public func reloadJournalHeaderView() {
        headerView.activeFolder = headerView.activeFolder
    }
    
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Journal"
        
        entryLayout = Settings.journalLayout
        
        listLayout = UICollectionViewFlowLayout()
        listLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        listLayout.minimumInteritemSpacing = 0
        listLayout.minimumLineSpacing = 0
        
        gridLayout = UICollectionViewFlowLayout()
        gridLayout.scrollDirection = UICollectionView.ScrollDirection.vertical
        gridLayout.minimumInteritemSpacing = 0
        gridLayout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: entryLayout == .list ? listLayout : gridLayout)
        collectionView.backgroundColor = Colors.backgroundColor
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        
        self.additionalTopInset = 12
                                
        collectionView.alwaysBounceVertical = true

        collectionView.register(JournalCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.delegate = self
        
        collectionView.contentInset.left = Constants.xsMargin - 4
        collectionView.contentInset.right = Constants.xsMargin - 4
                
        collectionView.dragInteractionEnabled = true
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        
        self.scrollView = collectionView
        contentView.addSubview(collectionView)
        
        headerView.delegate = self
        self.setTopView(headerView)
                
        self.folder = User.getActiveFolder(for: User.getActiveProfile())
        
        didLoad = true
         
        loadSavedData()
        
        reloadData()
        
    }
    
    private func updateFetchRequest() {
        guard let folder = self.folder else { return }
        
        let predicate = NSPredicate(format: "folder == %@", folder)
        
        fetchedObjectController.controller.fetchRequest.predicate = predicate
        fetchedObjectController.performFetch()
        
    }
    
    private func loadSavedData() {
        guard let folder = self.folder else { return }
        
        let request = CDJournalEntry.fetchRequest() as NSFetchRequest<CDJournalEntry>
        let sort = NSSortDescriptor(key: "index", ascending: true)
        request.sortDescriptors = [sort]
        
        request.predicate = NSPredicate(format: "folder == %@", folder)
        
        fetchedObjectController = FetchedObjectCollectionViewController(
            collectionView: collectionView,
            fetchRequest: request,
            managedObjectContext: DataManager.context,
            sectionNameKeyPath: nil)
        
        fetchedObjectController.delegate = self
                
        fetchedObjectController.cellProvider = {
            (collectionView, indexPath, entry) -> UICollectionViewCell? in
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "cell",
                for: indexPath) as? JournalCell
            
            cell?.layout = self.entryLayout
            cell?.entry = entry
            
            if let cell = cell {
                return cell
            } else {
                return UICollectionViewCell()
            }
            
        }
        
    }
    
    public func reloadData() {
        if !didLoad {
            return
        }
                        
        guard let folder = User.getActiveFolder(for: User.getActiveProfile()) else { return }
        
        self.folder = folder
        
        cancellables.removeAll()

        folder.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            
            if folder.isDeleted {
                guard
                    let profile = User.getActiveProfile(),
                    let newFolder = profile.getJournalFolders().first
                else { return }
                User.setActiveFolder(newFolder)
                self.reloadData()
                self.containerViewController.didDeleteFolder(wasActive: true)
            }
            
        }.store(in: &cancellables)
        
        folder.publisher(for: \.title).sink {
            [weak self] title in
            guard let self = self else { return }
            
            if self.containerViewController.isSidebarEnabled {
                self.title = title
            } else {
                self.title = "Journal"
            }
            
            self.headerView.activeFolder = folder
            
        }.store(in: &cancellables)
        
        if fetchedObjectController != nil {
            updateFetchRequest()
        }
                
    }
    
    var lastUpdateFolder: CDJournalFolder?
    func fetchedObjectControllerShouldAnimateUpdate(snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, oldSnapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>) -> Bool {
        if let lastFolder = lastUpdateFolder {
            self.lastUpdateFolder = self.folder
            return lastFolder == self.folder
        } else {
            self.lastUpdateFolder = self.folder
            return false
        }
    }
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        if isEmpty {
            emptyStateView = JournalEmptyStateView()
            collectionView.backgroundView = emptyStateView
            collectionView.isScrollEnabled = false
        }
        else {
            emptyStateView?.removeFromSuperview()
            collectionView.backgroundView = nil
            emptyStateView = nil
            collectionView.isScrollEnabled = true
        }
    }
    
    public func setActiveFolder() {
        reloadData()
    }
    
    func presentEntry(_ entry: CDJournalEntry?, openKeyboard: Bool = false) {
        
        let vc = EntryViewController(entry: entry)
        vc.delegate = self
        vc.shouldOpenKeyboard = openKeyboard
        self.present(vc, animated: false, completion: nil)
        
    }
    
    func journalHeader(didReceiveCellAt indexPath: IndexPath) {
        
    }
    
    func didTapJournalHeader() {
        let foldersVC = JournalFoldersViewController()
        foldersVC.modalPresentationStyle = .formSheet
        foldersVC.action = { folder in
            User.setActiveFolder(folder)
            self.reloadData()
        }
        self.presentModal(foldersVC, animated: true, completion: nil)
    }
    
    func journalHeaderDidTapOptions() {
        guard let folder = self.folder else { return }
        
        let optionsVC = JournalFolderOptionsViewController()
        optionsVC.sourceView = headerView.optionsButton
        optionsVC.optionsEnabled = folder.isDefaultFolder == false
        
        optionsVC.folder = folder
        
        optionsVC.askForDeletePredicate = {
            return folder.entries?.count ?? 0 > 0
        }
        
        optionsVC.deleteHandler = {
            [weak self] in
            guard let self = self else { return }
            self.deleteCurrentFolder()
        }
        
        optionsVC.renameHandler = {
            [weak self] in
            guard let self = self else { return }
            
            let newFolderAlert = RenameFolderAlertController(folder)
            
            newFolderAlert.confirmAction = {
                if let title = newFolderAlert.textField.text {
                    folder.title = title
                    DataManager.saveContext()
                }
            }
            
            self.present(newFolderAlert, animated: false, completion: nil)
            
        }
        
        optionsVC.selectedLayoutOption = self.entryLayout
        optionsVC.layoutHandler = {
            [weak self] layout in
            guard let self = self else { return }
            self.entryLayout = layout
            Settings.journalLayout = layout
            
            for cell in self.collectionView.visibleCells {
                if let cell = cell as? JournalCell {
                    cell.layout = layout
                    cell.reload(animated: true)
                }
            }
            
            self.collectionView.setCollectionViewLayout(layout == .list ? self.listLayout : self.gridLayout, animated: true)
            
        }
        
        self.presentPopupViewController(optionsVC)
    }
    
    @objc public func newEntry() {
        
        let entry = CDJournalEntry(context: DataManager.context)
        
        folder?.addToEntries(entry)
        
        if let fetchedEntries = fetchedObjectController.controller.fetchedObjects {
            var allEntries = [entry]
            allEntries.append(contentsOf: fetchedEntries)
            folder?.updateEntryOrder(toMatch: allEntries)
        }
        
        DataManager.saveNewObject(entry)

        presentEntry(entry, openKeyboard: true)
                
    }
    
    private func renameCurrentFolder() {
        guard let profile = User.getActiveProfile(),
              let folder = User.getActiveFolder(for: profile) else {
            return
        }
        
        let vc = RenameFolderAlertController(folder)
        vc.confirmAction = {
            folder.title = vc.textField.text ?? folder.title
            DataManager.saveContext()
        }
        self.present(vc, animated: false)
        
    }
    
    private func deleteCurrentFolder() {
        guard let profile = User.getActiveProfile(),
              let folder = self.folder
        else { return }
    
        let wasActive = folder == User.getActiveFolder(for: profile)
        profile.removeFromJournalFolders(folder)
        User.setActiveFolder(profile.getJournalFolders().first)
        self.setActiveFolder()
        
        DataManager.context.delete(folder)
        DataManager.saveContext()
        
        containerViewController.didDeleteFolder(wasActive: wasActive)
        
    }
    
    override func pageReselected() {
        scrollToTop(scrollView: self.collectionView)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll(scrollView: scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        scrollViewWillDrag()
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        willEndScroll(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    override func didChangeProfile(profile: CDProfile?) {
        super.didChangeProfile(profile: profile)
        
        reloadData()
    }
        
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if containerViewController.isSidebarEnabled {
            collectionView.contentInset.bottom = 62 + 28
        }
        else {
            collectionView.contentInset.bottom = 56 + 28
        }
        
        headerView.isSidebarLayout = containerViewController.isSidebarEnabled
        
        collectionView.frame = contentView.bounds
        
        let width = collectionView.bounds.inset(by: collectionView.contentInset).width
        
        listLayout.itemSize = CGSize(width: width, height: 150)
        
        if width/3 >= 260 {
            gridLayout.itemSize = CGSize(width: width/3, height: (width/3)*0.75)
        } else {
            gridLayout.itemSize = CGSize(width: width/2, height: (width/2)*1.25)
        }
        
    }
    
}

//MARK: Collectionview delegate
extension JournalViewController: EntryViewControllerDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        presentEntry(fetchedObjectController.controller.object(at: indexPath))
    }
    
    func entryViewControllerWillDissapear(_ viewController: EntryViewController, entry: CDJournalEntry?, attributedText: NSAttributedString) {
        
        if viewController.lastEdit != nil {
            entry?.saveAttrText(attributedText)
            DataManager.saveContext()
        }
        
    }
    
    func entryViewControllerDidDissapear(_ viewController: EntryViewController, entry: CDJournalEntry?, hasText: Bool) {
        //remove empty cells
        if !hasText {
            if let entry = entry {
                entry.folder?.removeFromEntries(entry)
                DataManager.context.delete(entry)
                DataManager.saveContext()
            }
        }
                
    }
    
    func entryViewControllerDidAddFolder() {
        containerViewController.sidebarNeedsReload()
    }
    
    func entryViewControllerDidSelectDelete(entry: CDJournalEntry?) {
        
        guard let entry = entry else { return }
       
        entry.folder?.removeFromEntries(entry)
        DataManager.context.delete(entry)
        DataManager.saveContext()
        
    }
    
    func didDragEntry(_ entryIndex: Int, from oldFolderIndex: Int, to newFolderIndex: Int) {
        if oldFolderIndex == newFolderIndex { return }
        
        let profile = User.getActiveProfile()
        
        guard let folders = profile?.getJournalFolders() else { return }

        let oldFolder = folders[oldFolderIndex]
        let newFolder = folders[newFolderIndex]
        
        if oldFolder == self.folder {
            
            let entry = fetchedObjectController.controller.object(at: IndexPath(row: entryIndex, section: 0))
            oldFolder.removeFromEntries(entry)
            
            var newFolderEntries = newFolder.getEntries()
            newFolderEntries.insert(entry, at: 0)
            newFolder.addToEntries(entry)
            newFolder.updateEntryOrder(toMatch: newFolderEntries)
            
            DataManager.saveContext()
                
        }
        
    }
    
    func entryViewControllerDidSelectMove(entry: CDJournalEntry?, to newFolder: CDJournalFolder) {
        //note - willDissapear is not called in this case so it can be handled accordingly
        
        guard let entry = entry else { return }
        
        entry.folder?.removeFromEntries(entry)
        
        var newFolderEntries = newFolder.getEntries()
        newFolderEntries.insert(entry, at: 0)
        newFolder.addToEntries(entry)
        newFolder.updateEntryOrder(toMatch: newFolderEntries)
        
        DataManager.saveContext()
        
    }
    
    func getActiveFolderIndex() -> Int {
        if let activeFolder = headerView.activeFolder {
            return User.getActiveProfile()?.getJournalFolders().firstIndex(of: activeFolder) ?? 0
        }
        
        return 0
    }
    
}

extension JournalViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath
    ) -> [UIDragItem] {
        
        let folderIndex = getActiveFolderIndex()
                
        let provider = NSItemProvider(
            object: EntryDragData(entryIndex: indexPath.row, folderIndex: folderIndex))
        
        let item = UIDragItem(itemProvider: provider)
        item.localObject = indexPath
        
        return [item]
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard
            let item = coordinator.items.first,
            let sourceIndexPath = item.sourceIndexPath,
            let destinationIndexPath = coordinator.destinationIndexPath
        else { return }
        
        if coordinator.proposal.intent == .insertAtDestinationIndexPath {
            
            if let objects = fetchedObjectController.controller.fetchedObjects {
                var allEntries = Array(objects)
                let entry = allEntries.remove(at: sourceIndexPath.row)
                allEntries.insert(entry, at: destinationIndexPath.row)
                headerView.activeFolder?.updateEntryOrder(toMatch: allEntries)
                DataManager.saveContext()
            }
            
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            
        }
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        
        let proposal = UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        
        return proposal
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: EntryDragData.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dragPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            previewParameters.visiblePath = UIBezierPath(roundedRect: cell.bounds.insetBy(dx: 4, dy: 4), cornerRadius: 10)
        }
        
        return previewParameters
        
    }
    
    func collectionView(_ collectionView: UICollectionView, dropPreviewParametersForItemAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            previewParameters.visiblePath = UIBezierPath(roundedRect: cell.bounds.insetBy(dx: 4, dy: 4), cornerRadius: 10)
        }
        
        return previewParameters
        
    }
    
}



protocol JournalCellDelegate: class {
    func journalCellDidTapOptions(journalCell: JournalCell, indexPath: IndexPath, relativePoint: CGPoint)
}

//MARK: Cell
class JournalCell: UICollectionViewCell {
    
    public weak var delegate: JournalCellDelegate?
    public var indexPath: IndexPath!
    
    public let bgView = MaskedShadowView()
    
    private let textView = UITextView()
    
    private let gradient = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .clear
        
        self.addSubview(bgView)
        
        self.clipsToBounds = false
            
        textView.font = Fonts.regular.withSize(16)
        textView.textColor = Colors.text
        textView.textContainerInset.left = Constants.smallMargin - 4
        textView.textContainerInset.right = Constants.smallMargin - 4
        textView.isEditable = false
        textView.textContainer.maximumNumberOfLines = 25
        textView.isScrollEnabled = false
        textView.isUserInteractionEnabled = false
        textView.backgroundColor = .clear
        bgView.addSubview(textView)
        
        gradient.colors = [Colors.foregroundColor.withAlphaComponent(0).cgColor, Colors.foregroundColor.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 0.95)
        bgView.fgView.layer.addSublayer(gradient)
        
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        gradient.colors = [Colors.foregroundColor.withAlphaComponent(0).cgColor, Colors.foregroundColor.cgColor]
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public var layout: JournalViewController.EntryLayout = .list
    
    public var entry: CDJournalEntry? {
        didSet {
            if let entry = entry, entry != oldValue {
                cancellables.removeAll()

                self.textView.attributedText = entry.attributedText(layout: self.layout)
                
                entry.objectWillChange.sink {
                    [weak self] _ in
                    guard let self = self else { return }
                    self.textView.attributedText = entry.attributedText(layout: self.layout)
                }.store(in: &cancellables)
                
            }
        }
    }
    
    public func reload(animated: Bool = false) {
        if let entry = entry {
            if animated {
                UIView.transition(with: self.textView, duration: 0.2, options: .transitionCrossDissolve, animations: {
                    self.textView.attributedText = entry.attributedText(layout: self.layout)
                }, completion: nil)
            } else {
                textView.attributedText = entry.attributedText(layout: self.layout)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: 4, dy: 4)
        
        textView.frame = bgView.bounds.inset(by: UIEdgeInsets(top: 6, left: 0, bottom: 6, right: 0))
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                bgView.pushDown()
            } else {
                bgView.pushUp()
            }
        }
    }
    
}

fileprivate protocol JournalHeaderDelegate: AnyObject {
    func didTapJournalHeader()
    func journalHeaderDidTapOptions()
    func journalHeader(didReceiveCellAt indexPath: IndexPath)
}

fileprivate class JournalHeaderView: HeaderAccessoryView {
        
    private let label = UILabel()
    private let folderIcon = UIImageView()
    public let optionsButton = Button("ellipsis")
    private let contentView = UIView() //for alpha purposes
    private let bgView = HighlightButton()
    
    override var isSidebarLayout: Bool {
        didSet {
            bgView.isHidden = isSidebarLayout
            if isSidebarLayout {
                optionsButton.tintColor = Colors.text
            } else {
                optionsButton.tintColor = Colors.text.withAlphaComponent(0.8)
            }
        }
    }
    
    public weak var delegate: JournalHeaderDelegate?
    
    public var activeFolder: CDJournalFolder? {
        didSet {
            label.text = activeFolder?.title ?? "No Folder Selected"
        }
    }
    
    public func setTitle(_ title: String) {
        label.text = title
    }
    
    
    init() {
        super.init(frame: .zero)
                        
        self.addSubview(bgView)
        bgView.backgroundColor = Colors.searchBarColor
        bgView.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        
        contentView.backgroundColor = .clear
        contentView.isUserInteractionEnabled = false
        bgView.addSubview(contentView)
        
        folderIcon.image = UIImage(name: "folder.fill", pointSize: 17, weight: .medium)
        folderIcon.setImageColor(color: Colors.lightText)
        contentView.addSubview(folderIcon)
        
        optionsButton.tintColor = Colors.text.withAlphaComponent(0.8)
        optionsButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.journalHeaderDidTapOptions()
        }
        self.addSubview(optionsButton)
          
        label.font = Fonts.medium.withSize(17)
        label.textColor = Colors.lightText
        contentView.addSubview(label)
        
    }
    
    @objc func didTap() {
        delegate?.didTapJournalHeader()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    public func setHideProgress(_ progress: CGFloat) {
        if isSidebarLayout { return }
        
        let alpha = 1 - (progress*4)
        
        contentView.alpha = alpha
        optionsButton.alpha = alpha
        
        if progress > 0.3 {
            self.alpha = 1 - (progress - 0.3)*4
        }
        else {
            self.alpha = 1
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = max(0, HeaderView.accessoryHeight - 28)

        if isSidebarLayout {
            setHideProgress(0)
            
            bgView.frame = CGRect(
                x: Constants.smallMargin,
                y: bounds.midY - height/2 - 2,
                width: self.bounds.width - Constants.smallMargin*2,
                height: height)
            
            optionsButton.frame = CGRect(
                x: bgView.frame.maxX - 44 - 12,
                y: bgView.frame.midY - bgView.bounds.height/2,
                width: 44 + 12,
                height: bgView.bounds.height)
        }
        else {
            setHideProgress(1 - (self.bounds.height / HeaderView.accessoryHeight))
            
            
            bgView.frame = CGRect(x: Constants.smallMargin,
                                  y: 10,
                                  width: self.bounds.width - Constants.smallMargin*2,
                                  height: max(0, self.bounds.height - 28))
            
            if bgView.bounds.height < height {
                bgView.roundCorners(min(bgView.bounds.height/2, 12))
            }
            else {
                bgView.roundCorners(12)
            }
                    
            contentView.frame = bgView.bounds
                    
            let frame = CGRect(x: 6, y: bgView.bounds.midY - height/2 - 1, width: height, height: height)
            folderIcon.sizeToFit()
            folderIcon.center = frame.center
                
            optionsButton.frame = CGRect(
                x: bgView.frame.maxX - 44 - 12,
                y: bgView.frame.midY - bgView.bounds.height/2,
                width: 44 + 12,
                height: bgView.bounds.height)
            
            label.frame = CGRect(
                from: CGPoint(x: folderIcon.center.x + height/2 + 2, y: 0),
                to: CGPoint(x: optionsButton.frame.minX, y: bgView.bounds.height))
        }
        
        
    }
    
}

fileprivate class JournalEmptyStateView: UIView {
    
    private let iconView = UIImageView()
    private let label = UILabel()
        
    init() {
        super.init(frame: .zero)
        
        iconView.image = UIImage(named: "JournalFill")?.withRenderingMode(.alwaysTemplate)
        iconView.tintColor = Colors.dynamicColor(light: Colors.text.withAlphaComponent(0.075), dark: Colors.lightColor)
        iconView.isUserInteractionEnabled = false
        addSubview(iconView)
        
        label.font = Fonts.regular.withSize(16)
        label.numberOfLines = 2
        label.textColor = Colors.lightText
        label.textAlignment = .center
        label.alpha = 0.7
        label.text = "Your journal entries will\nappear here."
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let iconSize = CGSize(min(160, bounds.width * 0.4))
       
        label.sizeToFit()
        
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




class EntryDragData: NSObject, NSItemProviderWriting, NSItemProviderReading, Codable {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return ["com.andante.entry"]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler:@escaping (Data?, Error?) -> Void) -> Progress? {
    
        let progress = Progress(totalUnitCount: 100)
        do {
            let data = try JSONEncoder().encode(self)
            progress.completedUnitCount = 100
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        
        return progress
    }
    
    static var readableTypeIdentifiersForItemProvider: [String] {
        return ["com.andante.entry"]
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
            let entry = try decoder.decode(EntryDragData.self, from: data)
            return self.init(
                entryIndex: entry.entryIndex,
                folderIndex: entry.folderIndex)
        } catch {
            throw error
        }
    }
    
    required init(entryIndex: Int, folderIndex: Int) {
        self.entryIndex = entryIndex
        self.folderIndex = folderIndex
        super.init()
    }
    
    public var entryIndex: Int!
    public var folderIndex: Int!
            
}
