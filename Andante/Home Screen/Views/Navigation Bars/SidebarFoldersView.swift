//
//  SidebarFoldersView.swift
//  Andante
//
//  Created by Miles Vinson on 11/4/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import MobileCoreServices
import Combine

protocol SidebarFoldersDelegate: class {
    func didSelectFolder(_ folder: CDJournalFolder, at index: Int)
    func didSelectNewFolder()
    func needsLayoutUpdate()
    func presentationViewController() -> UIViewController?
    func foldersDidUpdate(_ activeFolderIndex: Int?, firstUpdate: Bool)
}

class SidebarFoldersView: UIView, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate, FetchedObjectControllerDelegate {
    
    public weak var delegate: SidebarFoldersDelegate?
    
    private let tableView = UITableView()
    private let newFolderButton = NewFolderButton()
    
    private var fetchedObjectController: FetchedObjectTableViewController<CDJournalFolder>?
    
    private var profile: CDProfile?
    
    init() {
        super.init(frame: .zero)
        
        tableView.delaysContentTouches = false
        
        tableView.separatorColor = .clear
        tableView.backgroundColor = .clear
        
        tableView.rowHeight = 56
        tableView.estimatedRowHeight = 56
        
        tableView.register(FolderCell.self, forCellReuseIdentifier: "folderCell")
        
        tableView.delegate = self
                
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        self.addSubview(tableView)
        
        newFolderButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.delegate?.didSelectNewFolder()
        }
        self.addSubview(newFolderButton)
        
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let cellHeight: CGFloat = 56
        let rows = CGFloat(fetchedObjectController?.controller.fetchedObjects?.count ?? 0)
        return CGSize(width: size.width, height: cellHeight*rows + 46)
    }
    
    public func setProfile(_ profile: CDProfile, selectedIndex: Int) {
        self.profile = profile
        
        if let controller = self.fetchedObjectController {
            controller.controller.fetchRequest.predicate = NSPredicate(format: "profile = %@", profile)
        }
        else {
            createFetchController()
        }
        
        fetchedObjectController?.performFetch()
        
        if selectedIndex >= 0 {
            tableView.selectRow(
                at: IndexPath(row: selectedIndex, section: 0), animated: false, scrollPosition: .none)
        }
        
    }
    
    private func createFetchController() {
        guard let profile = self.profile else { return }
        
        let request = CDJournalFolder.fetchRequest() as NSFetchRequest<CDJournalFolder>
        
        let sort = NSSortDescriptor(key: "index", ascending: true)
        request.sortDescriptors = [sort]
        
        let predicate = NSPredicate(format: "profile = %@", profile)
        request.predicate = predicate
                
        fetchedObjectController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        fetchedObjectController?.delegate = self
        
        fetchedObjectController?.cellProvider = {
            (tableView, indexPath, folder) in
            let cell = tableView.dequeueReusableCell(withIdentifier: "folderCell", for: indexPath) as! FolderCell
            cell.folder = folder
            return cell
        }
        
    }
    
    public func setSelectedFolder(index: Int?) {
        if let index = index {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
        
        for indexPath in tableView.indexPathsForSelectedRows ?? [] {
            if indexPath.row != index {
                tableView.deselectRow(at: indexPath, animated: false)
            }
        }
    }
    
    func fetchedObjectControllerShouldAnimateUpdate(snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>, oldSnapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>) -> Bool {
        
        //animate reorder but not add/delete
        if snapshot.numberOfItems == oldSnapshot.numberOfItems {
            return true
        }
        else {
            return false
        }
        
    }
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        if let activeFolder = User.getActiveFolder(for: User.getActiveProfile()),
           let index = fetchedObjectController?.controller.fetchedObjects?.firstIndex(of: activeFolder)
        {
            delegate?.foldersDidUpdate(index, firstUpdate: firstUpdate)
        }
        else {
            delegate?.foldersDidUpdate(nil, firstUpdate: firstUpdate)
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let folder = fetchedObjectController?.controller.object(at: indexPath) {
            delegate?.didSelectFolder(folder, at: indexPath.row)
        }
        
    }
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let provider = NSItemProvider(object: FolderDragData())
        let item = UIDragItem(itemProvider: provider)
        item.localObject = indexPath
        
        return [item]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        
        if coordinator.session.canLoadObjects(ofClass: EntryDragData.self) {
            moveEntry(coordinator)
            return
        }
        
        guard
            let item = coordinator.items.first,
            let sourceIndexPath = item.sourceIndexPath,
            let fetchedObjectController = self.fetchedObjectController,
            let profile = self.profile
        else { return }
        
        //updateCells(for: .unspecified, at: nil)
        
        var destination: IndexPath?
        
        if let indexPath = coordinator.destinationIndexPath {
            destination = indexPath
        }
        
        guard let destinationIndexPath = destination else { return }
        
        if coordinator.proposal.intent == .insertAtDestinationIndexPath {
            
            if let fetchedFolders = fetchedObjectController.controller.fetchedObjects {
                var folders = Array(fetchedFolders)
                let folder = folders.remove(at: sourceIndexPath.row)
                folders.insert(folder, at: destinationIndexPath.row)
                self.profile?.updateFolderOrder(toMatch: folders)
                DataManager.saveContext()
                
                coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)

            }
            
        }
        else {
            guard let fetchedFolders = fetchedObjectController.controller.fetchedObjects else { return }
            let folders = Array(fetchedFolders)
            
            let sourceFolder = folders[sourceIndexPath.row]
            let destinationFolder = folders[destinationIndexPath.row]
            
            let action = {
                [weak self] in
                guard let self = self else { return }
                
                if sourceFolder.isDefaultFolder == false {
                    
                    var destinationEntries = destinationFolder.getEntries()
                    let sourceEntries = sourceFolder.getEntries()
                    
                    sourceFolder.removeFromEntries(sourceFolder.entries ?? [])
                    destinationFolder.addToEntries(NSSet(array: sourceEntries))
                    
                    destinationEntries.append(contentsOf: sourceEntries)
                    destinationFolder.updateEntryOrder(toMatch: destinationEntries)
                    
                    profile.removeFromJournalFolders(sourceFolder)
                    DataManager.context.delete(sourceFolder)
                    DataManager.saveContext()
                    
                    let activeFolder = User.getActiveFolder(for: profile)
                    if sourceFolder == activeFolder || destinationFolder == activeFolder {
                        self.delegate?.didSelectFolder(destinationFolder, at: destinationIndexPath.row)
                    }

                    self.delegate?.needsLayoutUpdate()
                    
                    
                }
                else {
                    //move entries but don't delete the default folder

                    var destinationEntries = destinationFolder.getEntries()
                    let sourceEntries = sourceFolder.getEntries()
                    
                    sourceFolder.removeFromEntries(sourceFolder.entries ?? [])
                    destinationFolder.addToEntries(NSSet(array: sourceEntries))
                    
                    destinationEntries.append(contentsOf: sourceEntries)
                    destinationFolder.updateEntryOrder(toMatch: destinationEntries)
                    
                    let activeFolder = User.getActiveFolder(for: profile)

                    if sourceFolder == activeFolder {
                        self.delegate?.didSelectFolder(sourceFolder, at: sourceIndexPath.row)
                    }
                    else if destinationFolder == activeFolder {
                        self.delegate?.didSelectFolder(destinationFolder, at: destinationIndexPath.row)
                    }
                    else {
                        self.delegate?.needsLayoutUpdate()
                    }
                    
                    DataManager.saveContext()
                }
            }
            
            let sourceTitle = sourceFolder.title ?? ""
            let destinationTitle = destinationFolder.title ?? ""
            
            let alert = ActionTrayPopupViewController(
                title: "Move Entries?",
                description: "This will move all entries from \"\(sourceTitle)\" into \"\(destinationTitle)\""
            )
                
            alert.addAction("Move Entries", handler: action)
            
            delegate?.presentationViewController()?.presentPopupViewController(alert)

        }
        
    }

    private func moveEntry(_ coordinator: UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.session.loadObjects(ofClass: EntryDragData.self) {
            [weak self] objects in
            guard let self = self else { return }
            
            if let data = objects.first as? EntryDragData {
                if let container = self.delegate?.presentationViewController() as? AndanteViewController {
                    container.journalViewController.didDragEntry(
                        data.entryIndex, from: data.folderIndex, to: destinationIndexPath.row)
                }
            }
        }
        
        if let cell = self.tableView.cellForRow(at: destinationIndexPath) {
            coordinator.drop(
                coordinator.items.first!.dragItem,
                intoRowAt: destinationIndexPath,
                rect: CGRect(center: cell.bounds.center.offset(dx: -96, dy: 0), size: CGSize(0)))
        }
        
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        if session.canLoadObjects(ofClass: FolderDragData.self) {
            return UITableViewDropProposal(operation: .move, intent: .automatic)
        } else if session.canLoadObjects(ofClass: EntryDragData.self) {
            return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
        } else {
            return UITableViewDropProposal(operation: .forbidden)
        }
        
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        
        if let cell = tableView.cellForRow(at: indexPath) {
            previewParameters.backgroundColor = Colors.foregroundColor
            previewParameters.visiblePath = UIBezierPath(roundedRect: cell.bounds.insetBy(dx: Constants.smallMargin, dy: 4), cornerRadius: 12)
            
        }
        
        return previewParameters
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let previewParameters = UIDragPreviewParameters()
        
        if let cell = tableView.cellForRow(at: indexPath) {
            previewParameters.backgroundColor = .clear
            previewParameters.visiblePath = UIBezierPath(roundedRect: cell.bounds.insetBy(dx: Constants.smallMargin, dy: 4), cornerRadius: 12)
            
        }
        
        return previewParameters
    }
        
    func tableView(_ tableView: UITableView, canHandle session: UIDropSession) -> Bool {
        return session.canLoadObjects(ofClass: FolderDragData.self) || session.canLoadObjects(ofClass: EntryDragData.self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.frame = self.bounds.inset(by: UIEdgeInsets(top: 0, left: 0, bottom: 46, right: 0))
        newFolderButton.frame = CGRect(x: 0, y: self.bounds.maxY - 46, width: self.bounds.width, height: 46)
        
    }
}

fileprivate class FolderCell: UITableViewCell, UIDropInteractionDelegate {
    
    private let bgView = UIView()
    
    private var cancellables = Set<AnyCancellable>()
    public var folder: CDJournalFolder? {
        didSet {
            cancellables.removeAll()
            folder?.publisher(for: \.title).sink {
                [weak self] title in
                guard let self = self else { return }
                self.label.text = title
            }.store(in: &cancellables)
            
        }
    }
    
    private let imgView = UIImageView()
    private let label = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        addSubview(bgView)
        bgView.backgroundColor = .clear
        bgView.roundCorners(12)

        imgView.image = UIImage(name: "folder.fill", pointSize: 19, weight: .medium)
        imgView.setImageColor(color: Colors.orange)
        bgView.addSubview(imgView)

        label.textColor = Colors.text
        label.font = Fonts.medium.withSize(17)
        bgView.addSubview(label)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted && !isSelected {
            bgView.backgroundColor = Colors.lightColor
        } else if !isSelected {
            UIView.animate(withDuration: 0.3) {
                self.bgView.backgroundColor = .clear
            }
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: false)
        
        if selected {
            UIView.animate(withDuration: 0) {
                self.bgView.backgroundColor = Colors.orange
            }
            label.textColor = Colors.white
            imgView.tintColor = Colors.white
            imgView.tintAdjustmentMode = .normal
        } else {
            self.bgView.backgroundColor = .clear
            label.textColor = Colors.text
            imgView.tintColor = Colors.orange
            imgView.tintAdjustmentMode = .automatic
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 4)
        
        imgView.sizeToFit()
        imgView.center = CGPoint(x: 28, y: bgView.bounds.midY)
        
        label.frame = CGRect(
            from: CGPoint(x: 52, y: 0),
            to: CGPoint(x: bgView.bounds.maxX - 8, y: bgView.bounds.maxY))
        
    }
}

fileprivate class NewFolderButton: CustomButton {
        
    override init() {
        super.init()
                
        self.setImage(UIImage(name: "plus", pointSize: 19, weight: .medium)?.withRenderingMode(.alwaysTemplate), for: .normal)
        contentEdgeInsets.left = 17 + Constants.smallMargin
        imageEdgeInsets.bottom = 2
        titleEdgeInsets.left = 14
        contentEdgeInsets.bottom = 4
        tintColor = Colors.orange
        self.adjustsImageWhenHighlighted = false
    
        self.setTitle("New folder", for: .normal)
        setTitleColor(Colors.orange, for: .normal)
        titleLabel?.font = Fonts.medium.withSize(17)
        
        contentHorizontalAlignment = .left
        
        self.highlightAction = {
            [weak self] highlighted in
            guard let self = self else { return }
            if highlighted {
                self.alpha = 0.25
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.alpha = 1
                }
            }
        }
    }
    
    override func tintColorDidChange() {
        if self.tintAdjustmentMode == .dimmed {
            self.setTitleColor(Colors.lightText, for: .normal)
        }
        else {
            self.setTitleColor(Colors.orange, for: .normal)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }
}

class FolderDragData: NSObject, NSItemProviderWriting, NSItemProviderReading, Codable {
    static var writableTypeIdentifiersForItemProvider: [String] {
        return ["com.andante.folder"]
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
        return ["com.andante.folder"]
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        let decoder = JSONDecoder()
        do {
            let folder = try decoder.decode(FolderDragData.self, from: data)
            return self.init()
        } catch {
            throw error
        }
    }
    
    required override init() {
        super.init()
    }
            
}
