//
//  ContainerViewController.swift
//  Andante
//
//  Created by Miles Vinson on 7/23/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

extension UIViewController {
    func containerViewController() -> UIViewController {
        return ContainerViewController(rootVC: self)
    }
}

class ContainerViewController: UIViewController {
    
    private weak var rootVC: UIViewController?
    
    init(rootVC: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        
        self.rootVC = rootVC
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let rootVC = self.rootVC {
            self.addChild(rootVC)
            self.view.addSubview(rootVC.view)
            
            rootVC.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rootVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                rootVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                rootVC.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                rootVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
            ])
            
            rootVC.didMove(toParent: self)
            
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class SettingsContainerViewController: UIViewController {
    
    public var settingsViewController: SettingsViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.preferredContentSize = Constants.modalSize
        
        let settingsVC = SettingsViewController()
        self.addChild(settingsVC)
        self.view.addSubview(settingsVC.view)
        self.settingsViewController = settingsVC
        
        settingsVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            settingsVC.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            settingsVC.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            settingsVC.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            settingsVC.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        settingsVC.didMove(toParent: self)
        
    }
    
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
}
