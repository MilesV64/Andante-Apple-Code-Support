//
//  File.swift
//  Andante
//
//  Created by Miles Vinson on 2/20/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine
import CoreData

class MoveEntryPopupView: PopupContentView, FetchedObjectControllerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate {
    
    private let fetchedObjectController: FetchedObjectTableViewController<CDJournalFolder>
    private let tableView: UITableView
    private let headerView = PopupSecondaryViewHeader(title: "Move Entry")
    private let newFolderView = NewFolderView()
    
    private var currentFolder: CDJournalFolder?
    
    private var initialCount = 0
    
    public var moveAction: ((CDJournalFolder)->())?
        
    init(entry: CDJournalEntry) {
        
        tableView = UITableView()
        
        let request = CDJournalFolder.fetchRequest() as NSFetchRequest<CDJournalFolder>
        
        let sort = NSSortDescriptor(key: "index", ascending: true)
        request.sortDescriptors = [sort]
        
        if let folder = entry.folder, let profile = folder.profile {
            let predicate = NSPredicate(format: "profile = %@", profile)
            request.predicate = predicate
            
            self.initialCount = profile.journalFolders?.count ?? 0
        }
        
        fetchedObjectController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        super.init()
                
        fetchedObjectController.cellProvider = {
            [weak self] (tableView, indexPath, folder) in
            guard let self = self else { return UITableViewCell() }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MoveEntryFolderCell
            cell.setFolder(folder, isEnabled: folder == self.currentFolder)
            return cell
            
        }

        fetchedObjectController.delegate = self
        
        self.currentFolder = entry.folder
        
        fetchedObjectController.performFetch()
        
        addSubview(headerView)
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 1))
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = .clear
        tableView.register(MoveEntryFolderCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 58
        tableView.separatorInset = .zero
        tableView.separatorColor = .clear
        tableView.delegate = self
        
        addSubview(tableView)
        
        newFolderView.action = {
            [weak self] in
            guard let self = self else { return }
            
            if let popupVC = self.popupViewController as? JournalEntryOptionsViewController {
                popupVC.closeCompletion = popupVC.newFolderHandler
                popupVC.close()
            }
            
        }
        addSubview(newFolderView)
        
    }
    
    override func didTransition(_ popupViewController: TransitionPopupViewController) {
        popupViewController.panGesture.delegate = self
    }
    
    override func didDissapear() {
        popupViewController?.panGesture.delegate = nil
        popupViewController?.panGesture.isEnabled = true
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard let panGesture = popupViewController?.panGesture else { return }
        
        if panGesture.velocity(in: nil).y > 0 {
            if (scrollView.contentOffset.y + scrollView.contentInset.top) <= 0 {
                scrollView.isScrollEnabled = false
                scrollView.isScrollEnabled = true
            }
            else {
                popupViewController?.disablePanWithoutClosing()
            }
        
        }
        else {
            panGesture.isEnabled = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard let panGesture = popupViewController?.panGesture else { return }
        panGesture.isEnabled = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let folder = fetchedObjectController.controller.object(at: indexPath)
        moveAction?(folder)
    }
    
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        
        if !firstUpdate {
            initialCount = 0
            UIView.animate(withDuration: 0.25) {
                self.popupViewController?.viewDidLayoutSubviews()
                self.layoutSubviews()
            }
        }

    }
    
    
    override func preferredHeight(for width: CGFloat) -> CGFloat {
        let headerHeight: CGFloat = PopupSecondaryViewHeader.height
        let itemCount = max(initialCount, fetchedObjectController.dataSource.snapshot().numberOfItems)
        
        let tableHeight = tableView.rowHeight * CGFloat(itemCount)
        
        return headerHeight + tableHeight + 4 + 92
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.layoutMargins.left = Constants.smallMargin
        tableView.layoutMargins.right = Constants.smallMargin
        
        headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: PopupSecondaryViewHeader.height)
        
        newFolderView.frame = CGRect(
            x: 0, y: bounds.maxY - 92 - safeAreaInsets.bottom,
            width: bounds.width,
            height: 92)
        
        tableView.frame = CGRect(
            from: CGPoint(x: 0, y: headerView.frame.maxY),
            to: CGPoint(x: bounds.maxX, y: newFolderView.frame.minY))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class MoveEntryFolderCell: UITableViewCell {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let iconView = UIImageView()
    private let label = UILabel()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.backgroundView?.backgroundColor = .clear
        
        iconView.image = UIImage(name: "folder.fill", pointSize: 18, weight: .regular)
        iconView.tintColor = Colors.lightText
        contentView.addSubview(iconView)
        
        label.textColor = Colors.text
        label.font = Fonts.regular.withSize(17)
        contentView.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentView.backgroundColor = Colors.cellHighlightColor
        } else {
            UIView.animate(withDuration: 0.25) {
                self.contentView.backgroundColor = .clear
            }
        }
    }
    
    public func setFolder(_ folder: CDJournalFolder?, isEnabled: Bool) {
        if isEnabled {
            self.label.alpha = 0.35
            self.iconView.alpha = 0.35
            self.isUserInteractionEnabled = false
        } else {
            self.label.alpha = 1
            self.iconView.alpha = 1
            self.isUserInteractionEnabled = true
        }
        
        cancellables.removeAll()
        folder?.publisher(for: \.title).sink {
            [weak self] title in
            guard let self = self else { return }
            self.label.text = title
        }.store(in: &cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.sizeToFit()
        iconView.center = CGPoint(x: Constants.smallMargin + 12, y: bounds.midY)
        label.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 16, y: 0),
            to: CGPoint(x: bounds.maxX - Constants.smallMargin, y: bounds.maxY))
        
    }
}

class NewFolderView: Separator {
    
    private let iconView = UIImageView()
    private let label = UILabel()
    
    private let button = PushButton()
    
    public var action: (()->())? {
        didSet {
            button.action = action
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.insetToMargins()
        self.position = .top
        
        button.backgroundColor = Colors.orange
        
        button.setTitle("New Folder", color: Colors.white, font: Fonts.medium.withSize(17))
        
        button.cornerRadius = 12
        
        addSubview(button)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        button.frame = CGRect(
            x: Constants.smallMargin,
            y: 18,
            width: bounds.width - Constants.smallMargin*2,
            height: 52)
    
    }
}
