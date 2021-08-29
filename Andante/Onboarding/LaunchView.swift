//
//  LaunchViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/15/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class LaunchView: UIView, NSFetchedResultsControllerDelegate {
    
    private let launchView: UIView
    
    private var loadingIndicator: UIActivityIndicatorView?
    private var loadingLabel: UILabel?
    
    private var checkCloudDataCompletion: ((Bool)->())?
    private var didFindData = false
    
    init() {
        
        launchView = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!.view!
        
        super.init(frame: .zero)
        
        addSubview(launchView)
        
    }
    
    private var checkDataFRC: NSFetchedResultsController<CDProfile>?
    public func checkForCloudData(_ completion: ((Bool)->())?) {
        showLoadingView(showLabel: false) {
            [weak self] in
            guard let self = self else { return }
            
            let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
            request.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            self.checkCloudDataCompletion = completion
            
            self.checkDataFRC = NSFetchedResultsController(
                fetchRequest: request,
                managedObjectContext: DataManager.context,
                sectionNameKeyPath: nil,
                cacheName: nil)
            
            self.checkDataFRC?.delegate = self
            do {
                try self.checkDataFRC?.performFetch()
            }
            catch {
                print("Error performing fetch for checking data: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                [weak self] in
                guard let self = self, self.didFindData == false else { return }
                print("did not find in 2 seconds")
                self.checkDataFRC = nil
                completion?(false)
                UIView.animate(withDuration: 0.25) {
                    self.loadingIndicator?.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                    self.loadingIndicator?.alpha = 0
                }
                self.checkCloudDataCompletion = nil
            }
            
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        
        if snapshot.numberOfItems > 0 {
            didFindData = true
            checkCloudDataCompletion?(true)
            self.checkCloudDataCompletion = nil
            self.checkDataFRC = nil
        }
        
    }

    private func showLoadingView(showLabel: Bool = true, _ completion: (()->())?) {
        loadingIndicator = UIActivityIndicatorView()
        loadingIndicator!.color = Colors.white
        loadingIndicator!.alpha = 0
        loadingIndicator!.transform = CGAffineTransform(translationX: 0, y: 40)
        loadingIndicator!.startAnimating()
        addSubview(loadingIndicator!)
        
        loadingLabel = UILabel()

        if showLabel {
            loadingLabel!.text = "Updating"
            loadingLabel!.textColor = Colors.white
            loadingLabel!.font = Fonts.regular.withSize(15)
            loadingLabel!.alpha = 0
            loadingLabel!.transform = loadingIndicator!.transform
            addSubview(loadingLabel!)
        }
       
        UIView.animate(withDuration: 1.25, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.loadingIndicator!.alpha = 1
            self.loadingIndicator!.transform = .identity
            self.loadingLabel?.alpha = 1
            self.loadingLabel?.transform = .identity
        }, completion: { complete in
            completion?()
        })
    }
    
    private func newIconName(for iconName: String) -> String {
        switch iconName {
        case "Violin": return "violin"
        case "Cello": return "cello"
        case "Harp": return "harp"
        case "Guitar": return "acoustic-guitar"
        case "Electric Guitar": return "electric-guitar"
        case "Piano": return "piano"
        case "Folk Music": return "accordion"
        case "Bassoon": return "bassoon"
        case "Clarinet": return "clarinet"
        case "Piccolo": return "flute"
        case "Trumpet": return "trumpet"
        case "Saxophone": return "saxophone"
        case "Trombone": return "trombone"
        case "Tuba": return "tuba"
        case "French Horn": return "french-horn"
        case "Bass Drum": return "timpani"
        case "Timpani": return "timpani"
        case "Drum Kit": return "drum-set"
        case "Xylophone": return "xylophone"
        case "Marimba": return "marimba"
        case "Microphone": return "singing"
        case "Electronic": return "synthesizer"
        case "Male Conductor": return "conducting-baton"
        case "Female Conductor": return "conducting-baton"
        case "Producer": return "synthesizer"
        case "Pen": return "pen"
        default: return "music"
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.frame = superview?.bounds ?? .zero
        launchView.frame = self.bounds
        
        if
            let loadingIndicator = self.loadingIndicator,
            let loadingLabel = self.loadingLabel
        {
            loadingIndicator.bounds.size = CGSize(40)
            loadingIndicator.center = CGPoint(x: bounds.midX, y: floor(bounds.height * 4/5))
            
            loadingLabel.sizeToFit()
            loadingLabel.center = CGPoint(x: bounds.midX, y: loadingIndicator.center.y + 30)
        }
        
    }
}