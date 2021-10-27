//
//  LaunchViewController.swift
//  Andante
//
//  Created by Miles Vinson on 3/15/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData

class LaunchView: UIView {
    
    private let launchView: UIView
    
    private var loadingIndicator = UIActivityIndicatorView()
    private var loadingLabel = UILabel()
    
    private var checkCloudDataCompletion: ((Bool)->())?
    
    private var didFindAnyData = false
    private var didFindProfileData = false
    
    init() {
        
        launchView = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()!.view!
        
        super.init(frame: .zero)
        
        addSubview(launchView)
        
    }
    
    
    public func checkForCloudData(_ completion: ((Bool)->())?) {
        self.checkCloudDataCompletion = completion
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.practiceDatabaseDidUpdate),
            name: PracticeDatabase.PracticeDatabaseAnySessionDataDidChangeNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.profilesDidChange),
            name: ProfileMonitor.ProfilesDidChangeNotification,
            object: nil
        )
        
        showLoadingView(completion: { [weak self] in
            guard let self = self else { return }
            guard !self.didFindProfileData else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
                guard let self = self, self.didFindAnyData == false else { return }
                print("LaunchView: Did not find any data in 4 seconds")
                
                completion?(false)
                UIView.animate(withDuration: 0.25) {
                    self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                    self.loadingIndicator.alpha = 0
                    self.loadingLabel.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                    self.loadingLabel.alpha = 0
                }
                self.checkCloudDataCompletion = nil
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                guard let self = self, self.didFindProfileData == false else { return }
                print("LaunchView: Did not find any profile data in 12 seconds")
                
                completion?(false)
                UIView.animate(withDuration: 0.25) {
                    self.loadingIndicator.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                    self.loadingIndicator.alpha = 0
                    self.loadingLabel.transform = CGAffineTransform(scaleX: 0.25, y: 0.25)
                    self.loadingLabel.alpha = 0
                }
                self.checkCloudDataCompletion = nil
            }
            
        })
    }
    
    @objc func profilesDidChange() {
        guard !self.didFindProfileData else { return }
        
        if CDProfile.getAllProfiles(context: DataManager.context).count > 0 {
            self.didFindProfileData = true
            self.checkCloudDataCompletion?(true)
            self.checkCloudDataCompletion = nil
        }

    }
    
    @objc func practiceDatabaseDidUpdate() {
        guard !self.didFindProfileData else { return }
        
        if self.didFindAnyData == false {
            print("LaunchView: Found iCloud data")
            self.showLabel()
            self.didFindAnyData = true
        }
        
        if CDProfile.getAllProfiles(context: DataManager.context).count > 0 {
            self.didFindProfileData = true
            self.checkCloudDataCompletion?(true)
            self.checkCloudDataCompletion = nil
        }
        
    }

    private func showLoadingView(completion: (()->())?) {
        loadingIndicator.color = Colors.white
        loadingIndicator.alpha = 0
        loadingIndicator.transform = CGAffineTransform(translationX: 0, y: 40)
        loadingIndicator.startAnimating()
        addSubview(loadingIndicator)
        
        loadingLabel.text = "Retrieving iCloud Data"
        loadingLabel.textColor = Colors.white
        loadingLabel.font = Fonts.regular.withSize(15)
        loadingLabel.alpha = 0
        loadingLabel.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        addSubview(loadingLabel)
       
        UIView.animate(withDuration: 1.25, delay: 0, usingSpringWithDamping: 0.92, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.loadingIndicator.alpha = 1
            self.loadingIndicator.transform = .identity
        }, completion: { complete in
            completion?()
        })
    }
    
    private func showLabel() {
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
            self.loadingLabel.alpha = 1
            self.loadingLabel.transform = .identity
        }, completion: { _ in
            //
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
        
        loadingIndicator.bounds.size = CGSize(40)
        loadingIndicator.center = CGPoint(x: bounds.midX, y: floor(bounds.height * 4/5))
        
        loadingLabel.sizeToFit()
        loadingLabel.center = CGPoint(x: bounds.midX, y: loadingIndicator.center.y + 30)
        
    }
}
