//
//  JournalFoldersViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class JournalFoldersViewController: UIViewController {
        
    public let header = ModalViewHeader(title: "Folders")
    
    public let tableView = UITableView()
    
    private var profile: CDProfile!
    
    public var action: ((CDJournalFolder)->Void)?
    public var didAddFolder: (()->Void)?
    
    private let newFolderButton = BottomActionButton(title: "New Folder")
    
    public var showEntryCount = true
    
    private var fetchedObjectController: FetchedObjectTableViewController<CDJournalFolder>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let profile = User.getActiveProfile()!
        self.profile = User.getActiveProfile()

        self.view.backgroundColor = Colors.backgroundColor
                
        tableView.separatorInset = .zero
        tableView.separatorColor = .clear
        tableView.backgroundColor = Colors.backgroundColor
        tableView.register(JournalFolderCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        
        tableView.rowHeight = 68
                
        tableView.delegate = self
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 8))
        
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        self.view.addSubview(tableView)
        
        header.showsHandle = true
        header.showsSeparator = false
        header.backgroundColor = Colors.backgroundColor
        
        self.view.addSubview(header)
        
        newFolderButton.action = {
            [weak self] in
            guard let self = self else { return }
            
            self.newFolder()
        }
        newFolderButton.style = .floating
                
        self.view.addSubview(newFolderButton)
        
        
        let request = CDJournalFolder.fetchRequest() as NSFetchRequest<CDJournalFolder>
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        request.predicate = NSPredicate(format: "profile == %@", profile)
        
        fetchedObjectController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        fetchedObjectController.cellProvider = {
            (tableView, indexPath, folder) in
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JournalFolderCell
            cell.folder = folder
            cell.isActive = folder == User.getActiveFolder(for: profile)
            return cell
            
        }
        
        fetchedObjectController.performFetch()
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.layoutMargins.left = Constants.smallMargin
        self.tableView.layoutMargins.right = Constants.smallMargin
        
        header.sizeToFit()
        newFolderButton.sizeToFit()
        
        header.bounds.size.width = self.view.bounds.width
        
        header.frame.origin = CGPoint(x: 0, y: 0)
        
        newFolderButton.bounds.size.width = self.view.bounds.width
        newFolderButton.frame.origin.x = 0
        newFolderButton.frame.origin.y = self.view.bounds.maxY - newFolderButton.bounds.height
        
        tableView.frame = self.view.bounds.inset(
            by: UIEdgeInsets(
                top: header.frame.maxY, left: 0,
                bottom: newFolderButton.bounds.height, right: 0))
        
    }
    
    private func newFolder() {
        if Settings.isPremium {
            let newFolderAlert = NewFolderCenterAlertController(animateWithKeyboard: true)
            newFolderAlert.confirmAction = {
                [weak self] in
                guard let self = self else { return }

                if let title = newFolderAlert.textField.text {
                    let folder = CDJournalFolder(context: DataManager.context)
                    folder.title = title
                    self.profile.addJournalFolder(folder)
                    DataManager.saveNewObject(folder)
                }
            }

            self.present(newFolderAlert, animated: false, completion: nil)
        }
        else {
            self.present(AndanteProViewController(), animated: true, completion: nil)
        }

    }
    
}

extension JournalFoldersViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = fetchedObjectController.controller.object(at: indexPath)
        self.action?(folder)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        return nil
        
//        let folder = fetchedObjectController.controller.object(at: indexPath)
//
//        if folder.isDefaultFolder {
//            return nil
//        }
//
//        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, handler) in
//            self.deleteFolder(at: indexPath, handler: handler)
//        }
//
//        let edit = UIContextualAction(style: .normal, title: "Rename") { (action, view, handler) in
//            self.renameFolder(at: indexPath)
//            handler(true)
//        }
//
//        delete.backgroundColor = Colors.red
//        edit.backgroundColor = Colors.purple
//
//        return UISwipeActionsConfiguration(actions: [delete, edit])
        
    }
    
}

extension JournalFoldersViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        
        let provider = NSItemProvider(object: "\(indexPath.row)" as NSString)
        let item = UIDragItem(itemProvider: provider)
        item.localObject = indexPath
        
        return [item]
    }
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard let item = coordinator.items.first, let sourceIndexPath = item.sourceIndexPath else { return }
        
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
                profile.updateFolderOrder(toMatch: folders)
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
                    
                    self.profile.removeFromJournalFolders(sourceFolder)
                    DataManager.context.delete(sourceFolder)
                    DataManager.saveContext()
                    
                    let activeFolder = User.getActiveFolder(for: self.profile)
                    if sourceFolder == activeFolder || destinationFolder == activeFolder {
                        self.action?(destinationFolder)
                    }
                    
                    var snapshot = self.fetchedObjectController.dataSource.snapshot()
                    snapshot.reloadItems(snapshot.itemIdentifiers)
                    self.fetchedObjectController.dataSource.apply(snapshot)
                    
                }
                else {
                    //move entries but don't delete the default folder

                    var destinationEntries = destinationFolder.getEntries()
                    let sourceEntries = sourceFolder.getEntries()
                    
                    sourceFolder.removeFromEntries(sourceFolder.entries ?? [])
                    destinationFolder.addToEntries(NSSet(array: sourceEntries))
                    
                    destinationEntries.append(contentsOf: sourceEntries)
                    destinationFolder.updateEntryOrder(toMatch: destinationEntries)
                    
                    let activeFolder = User.getActiveFolder(for: self.profile)
                    if sourceFolder == activeFolder {
                        self.action?(sourceFolder)
                    }
                    else if destinationFolder == activeFolder {
                        self.action?(destinationFolder)
                    }
                    
                    DataManager.saveContext()
                }
            }
            
            let sourceTitle = sourceFolder.title ?? ""
            let destinationTitle = destinationFolder.title ?? ""
            
            let alert = AreYouSurePopupViewController(
                isDistructive: false,
                title: "Move Entries?",
                description: "This will move all entries from \"\(sourceTitle)\" into \"\(destinationTitle)\"",
                destructiveText: "Move Entries", cancelText: "Cancel") {
                    action()
            }
            
            self.presentPopupViewController(alert)
            

        }
        
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        
        return UITableViewDropProposal(operation: .move, intent: .automatic)
        
//        let locationRect = CGRect(center: session.location(in: tableView), size: CGSize(width: 10, height: 10))
//
//        if let indexPath = destinationIndexPath {
//            let frame = tableView.rectForRow(at: indexPath)
//
//            if frame.contains(locationRect) {
//                updateCells(for: .insertIntoDestinationIndexPath, at: indexPath)
//                return UITableViewDropProposal(operation: .move, intent: .insertIntoDestinationIndexPath)
//            }
//        }
//
//        updateCells(for: .insertAtDestinationIndexPath, at: destinationIndexPath)
//        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        
    }
    
    func updateCells(for intent: UITableViewDropProposal.Intent, at indexPath: IndexPath?) {
        for index in 0..<fetchedObjectController.dataSource.snapshot().numberOfItems {
            if intent == .insertIntoDestinationIndexPath && index == indexPath?.row {
                //tableView.cellForRow(at: IndexPath(row: index, section: 0))?.backgroundColor = Colors.lightColor
            }
            else {
                //tableView.cellForRow(at: IndexPath(row: index, section: 0))?.backgroundColor = Colors.foregroundColor
            }
        }
    }
    
    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let param = UIDragPreviewParameters()
        param.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.rowHeight).insetBy(dx: Constants.smallMargin, dy: 4), cornerRadius: 10)
        return param
    }
    
    func tableView(_ tableView: UITableView, dropPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        let param = UIDragPreviewParameters()
        param.visiblePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: tableView.rowHeight).insetBy(dx: Constants.smallMargin, dy: 4), cornerRadius: 10)
        return param
    }
      
}

