//
//  FetchedObjectCollectionViewDataSource.swift
//  Andante
//
//  Created by Miles Vinson on 2/17/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData
import Combine

@objc protocol FetchedObjectControllerDelegate: class {
    @objc optional func fetchedObjectControllerShouldAnimateUpdate(
        snapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>,
        oldSnapshot: NSDiffableDataSourceSnapshot<String, NSManagedObjectID>) -> Bool
    @objc optional func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool)
}

class FetchedObjectCollectionViewController<Object: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
    
    typealias CDDataSource = UICollectionViewDiffableDataSource<String, NSManagedObjectID>
    typealias CDSnapshot = NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
    
    public weak var delegate: FetchedObjectControllerDelegate?
    
    var controller: NSFetchedResultsController<Object>!
    var collectionView: UICollectionView!
    var dataSource: CDDataSource!
    
    var cellProvider: ((UICollectionView, IndexPath, Object)->(UICollectionViewCell?))?
    var supplementaryViewProvider: ((UICollectionView, String, IndexPath)->(UICollectionReusableView))?
    
    var cancellables = Set<AnyCancellable>()
    
    private var firstUpdate = true
    
    init(
        collectionView: UICollectionView,
        fetchRequest: NSFetchRequest<Object>,
        managedObjectContext: NSManagedObjectContext,
        sectionNameKeyPath: String? = nil
    ) {
        
        super.init()

        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: sectionNameKeyPath,
            cacheName: nil)
        
        controller.delegate = self
        
        self.collectionView = collectionView
        
        dataSource = CDDataSource(collectionView: collectionView) {
            [weak self] (collectionView, indexPath, objectID) -> UICollectionViewCell? in
            guard
                let self = self,
                let obj = try? DataManager.context.existingObject(with: objectID) as? Object
            else {
                return UICollectionViewCell()
                
            }
            
            return self.cellProvider?(collectionView, indexPath, obj)
        }
        
        dataSource.supplementaryViewProvider = {
            
            [weak self] (collectionView, kind, indexPath) in
            guard let self = self else { return nil }
            
            return self.supplementaryViewProvider?(collectionView, kind, indexPath)
        }
        
        collectionView.dataSource = dataSource
        
    }
    
    public func performFetch() {
        do {
            try controller.performFetch()
        } catch {
            print("Fetch failed")
        }
    }
    
    public func object(at indexPath: IndexPath) -> Object? {
        if let objectID = dataSource.itemIdentifier(for: indexPath) {
            return try? DataManager.context.existingObject(with: objectID) as? Object
        }
        return nil
    }
    
    public func numberOfItems() -> Int {
        return controller.fetchedObjects?.count ?? 0
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        let delegateShouldAnimate = delegate?.fetchedObjectControllerShouldAnimateUpdate?(
            snapshot: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>,
            oldSnapshot: dataSource.snapshot())
        
        let shouldAnimate = delegateShouldAnimate ?? (collectionView.numberOfSections != 0)
        
        if shouldAnimate {
            self.dataSource.apply(snapshot as CDSnapshot, animatingDifferences: true)
        } else {
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot as CDSnapshot, animatingDifferences: false)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.fetchedObjectControllerDidUpdate?(
                isEmpty: snapshot.numberOfItems == 0, firstUpdate: self.firstUpdate)
            
            self.firstUpdate = false
        }
        
        
    }
    
}

class FetchedObjectTableViewController<Object: NSManagedObject>: NSObject, NSFetchedResultsControllerDelegate {
        
    class CDDataSource: UITableViewDiffableDataSource<String, NSManagedObjectID> {
        public var canEdit = false
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return canEdit
        }
    }
    
    typealias CDSnapshot = NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
    
    public weak var delegate: FetchedObjectControllerDelegate?
    
    var controller: NSFetchedResultsController<Object>!
    var tableView: UITableView!
    var dataSource: CDDataSource!
    
    public var canSwipeToEdit: Bool {
        get {
            return dataSource.canEdit
        } set {
            dataSource.canEdit = newValue
        }
    }
    
    var cellProvider: ((UITableView, IndexPath, Object)->(UITableViewCell?))?
    
    var cancellables = Set<AnyCancellable>()
    
    private var firstUpdate = true
    
    init(
        tableView: UITableView,
        fetchRequest: NSFetchRequest<Object>,
        managedObjectContext: NSManagedObjectContext
    ) {
        
        super.init()

        controller = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        controller.delegate = self
        
        self.tableView = tableView
        
        dataSource = CDDataSource(tableView: tableView) {
            [weak self] (tableView, indexPath, objectID) -> UITableViewCell? in
            
            guard
                let self = self,
                let obj = try? DataManager.context.existingObject(with: objectID) as? Object
            else {
                return UITableViewCell()
                
            }
            
            return self.cellProvider?(tableView, indexPath, obj)
        }
        
        tableView.dataSource = dataSource
        
    }
    
    public func performFetch() {
        do {
            try controller.performFetch()
        } catch {
            print("Fetch failed")
        }
    }
    
    public func numberOfItems() -> Int {
        return controller.fetchedObjects?.count ?? 0
    }
    
    public func object(at indexPath: IndexPath) -> Object? {
        if let objectID = dataSource.itemIdentifier(for: indexPath) {
            return try? DataManager.context.existingObject(with: objectID) as? Object
        }
        return nil
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        let delegateShouldAnimate = delegate?.fetchedObjectControllerShouldAnimateUpdate?(
            snapshot: snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>,
            oldSnapshot: dataSource.snapshot())
        
        let shouldAnimate = delegateShouldAnimate ?? (tableView.numberOfSections != 0)
        
        if shouldAnimate {
            self.dataSource.apply(snapshot as CDSnapshot, animatingDifferences: true)
        } else {
            DispatchQueue.main.async {
                self.dataSource.apply(snapshot as CDSnapshot, animatingDifferences: false)
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.fetchedObjectControllerDidUpdate?(
                isEmpty: snapshot.numberOfItems == 0, firstUpdate: self.firstUpdate)
            
            self.firstUpdate = false
        }
        
        
        
    }
    
}
