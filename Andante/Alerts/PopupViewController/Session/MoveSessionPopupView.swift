//
//  MoveSessionPopupView.swift
//  Andante
//
//  Created by Miles Vinson on 2/24/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import Combine
import CoreData

class MoveSessionPopupView: PopupContentView, FetchedObjectControllerDelegate, UIGestureRecognizerDelegate, UITableViewDelegate {
    
    private let fetchedObjectController: FetchedObjectTableViewController<CDProfile>
    private let tableView: UITableView
    private let headerView = PopupSecondaryViewHeader(title: "Move Session")
    
    private var currentProfile: CDProfile?
    
    private var initialCount = 0
    
    public var moveAction: ((CDProfile)->())?
        
    init(session: CDSession) {
        
        tableView = UITableView()
        
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        
        let sort = NSSortDescriptor(key: "creationDate", ascending: true)
        request.sortDescriptors = [sort]
        
        fetchedObjectController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: request,
            managedObjectContext: DataManager.context)
        
        super.init()
                
        fetchedObjectController.cellProvider = {
            [weak self] (tableView, indexPath, profile) in
            guard let self = self else { return UITableViewCell() }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! MoveSessionCell
            cell.setProfile(profile, isEnabled: profile == self.currentProfile)
            return cell
            
        }

        fetchedObjectController.delegate = self
        
        self.currentProfile = session.profile
        
        fetchedObjectController.performFetch()
        initialCount = fetchedObjectController.controller.fetchedObjects?.count ?? 0
        
        addSubview(headerView)
        
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 8))
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 2))
        tableView.alwaysBounceVertical = false
        tableView.backgroundColor = .clear
        tableView.register(MoveSessionCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 66
        tableView.separatorInset = .zero
        tableView.separatorColor = .clear
        tableView.delegate = self
        
        addSubview(tableView)
        
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
        let profile = fetchedObjectController.controller.object(at: indexPath)
        moveAction?(profile)
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
        
        let tableHeight = tableView.rowHeight * CGFloat(itemCount) + 10
        
        return headerHeight + tableHeight + 10
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        tableView.layoutMargins.left = Constants.smallMargin
        tableView.layoutMargins.right = Constants.smallMargin
        
        headerView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: PopupSecondaryViewHeader.height)
        
        tableView.frame = CGRect(
            from: CGPoint(x: 0, y: headerView.frame.maxY),
            to: CGPoint(x: bounds.maxX, y: bounds.maxY))
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class MoveSessionCell: UITableViewCell {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let iconView = ProfileImageView()
    private let label = UILabel()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        self.backgroundView?.backgroundColor = .clear
        
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
    
    public func setProfile(_ profile: CDProfile?, isEnabled: Bool) {
        if isEnabled {
            self.label.alpha = 0.35
            self.iconView.alpha = 0.35
            self.isUserInteractionEnabled = false
        } else {
            self.label.alpha = 1
            self.iconView.alpha = 1
            self.isUserInteractionEnabled = true
        }

        iconView.profile = profile

        cancellables.removeAll()
        profile?.publisher(for: \.name).sink {
            [weak self] name in
            guard let self = self else { return }
            self.label.text = name
        }.store(in: &cancellables)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.bounds.size = CGSize(44)
        iconView.center = CGPoint(x: Constants.smallMargin + iconView.bounds.width/2, y: bounds.midY)
        label.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 16, y: 0),
            to: CGPoint(x: bounds.maxX - Constants.smallMargin, y: bounds.maxY))
        
    }
}
