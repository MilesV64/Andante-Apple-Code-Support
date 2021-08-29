//
//  AppTweaksViewController.swift
//  Andante
//
//  Created by Miles on 8/28/21.
//  Copyright © 2021 Miles Vinson. All rights reserved.
//

import UIKit

protocol AppTweaksViewControllerDelegate: AnyObject {
    func appTweaksViewController(didChangeAndantePro isPremium: Bool)
}

class AppTweaksViewController: UITableViewController {
    
    public weak var delegate: AppTweaksViewControllerDelegate?
    
    private class AppTweakCell {
        
        let reuseIdentifier: String
        
        let title: String
        
        init(title: String, reuseIdentifier: String) {
            self.title = title
            self.reuseIdentifier = reuseIdentifier
        }
        
    }
    
    private class AppTweakToggleCell: AppTweakCell {
        
        static let reuseIdentifier = "Toggle"
        
        let action: ((Bool) -> ())?
        let isOn: (() -> Bool)?
        
        init(title: String, isOn: (()->Bool)?, action: ((Bool) -> ())?) {
            self.isOn = isOn
            self.action = action
            super.init(title: title, reuseIdentifier: Self.reuseIdentifier)
        }
        
    }
    
    private class AppTweakSelectCell: AppTweakCell {
        
        static let reuseIdentifier = "Select"
        
        let action: (() -> ())?
        
        init(title: String, action: (()->())?) {
            self.action = action
            super.init(title: title, reuseIdentifier: Self.reuseIdentifier)
        }
        
    }
    
    init() {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var items: [[AppTweakCell]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "App Tweaks"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.didTapDone))
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: AppTweakSelectCell.reuseIdentifier)
        self.tableView.register(ToggleTableViewCell.self, forCellReuseIdentifier: AppTweakToggleCell.reuseIdentifier)
        
        self.items = [
            [
                AppTweakToggleCell(
                    title: "Andante Pro",
                    isOn: {
                        return Settings.isPremium
                    },
                    action: { [weak self] isOn in
                        Settings.isPremium = isOn
                        self?.delegate?.appTweaksViewController(didChangeAndantePro: isOn)
                    }
                )
            ],
            [
                AppTweakSelectCell(
                    title: "Reset Tutorial Tooltips",
                    action: {
                        ToolTips.didShowGoalTooltip = false
                        ToolTips.didShowSessionsTooltip = false
                        ToolTips.didShowNotesTooltip = false
                    }
                ),
                AppTweakSelectCell(
                    title: "Reset Tuner Trial",
                    action: {
                        Settings.didTryTuner = false
                    }
                ),
            ]
            
        ]
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.tableView.rowHeight = 50
                
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.items.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.items[indexPath.section][indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: item.reuseIdentifier, for: indexPath)
        
        cell.textLabel?.text = item.title
        
        if let item = item as? AppTweakToggleCell {
            let cell = cell as! ToggleTableViewCell
            cell.isOn = item.isOn?() ?? false
            cell.action = item.action
        }
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let item = self.items[indexPath.section][indexPath.row] as? AppTweakSelectCell {
            item.action?()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func didTapDone() {
        self.dismiss(animated: true, completion: nil)
    }
    
}

class ToggleTableViewCell: UITableViewCell {
    
    private let toggle = UISwitch()
    
    public var action: ((Bool) -> ())?
    public var isOn: Bool = false {
        didSet {
            self.toggle.isOn = self.isOn
        }
    }
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        
        toggle.addTarget(self, action: #selector(didToggle(_:)), for: .touchUpInside)
        self.accessoryView = toggle
        
    }
    
    @objc func didToggle(_ sender: UISwitch) {
        self.action?(sender.isOn)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
