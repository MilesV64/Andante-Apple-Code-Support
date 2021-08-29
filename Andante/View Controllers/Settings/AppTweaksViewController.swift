//
//  AppTweaksViewController.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

class AppTweaksTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "App Tweaks"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didTapDone))
        
    }
    
    @objc func didTapDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
