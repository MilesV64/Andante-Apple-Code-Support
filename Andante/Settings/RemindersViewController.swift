//
//  RemindersViewController.swift
//  Andante
//
//  Created by Miles Vinson on 11/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import Combine
import CoreData
import UIKit
import os.log

class RemindersViewController: ChildTransitionViewController {
    
    private let headerView = UIView()
    private let backButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    
    let newReminderButton = BottomActionButton(title: "New Reminder")
    
    private var fetchController: FetchedObjectTableViewController<CDReminder>!
    private let tableView = UITableView(frame: .zero)
    
    private var emptyStateView: UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Colors.backgroundColor
        
        let fetchRequest = CDReminder.fetchRequest() as NSFetchRequest<CDReminder>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        fetchController = FetchedObjectTableViewController(
            tableView: tableView,
            fetchRequest: fetchRequest,
            managedObjectContext: DataManager.context)
                
        fetchController.cellProvider = {
            [weak self] (tableView, indexPath, reminder) in
            guard let self = self else { return UITableViewCell() }
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ReminderCell
            cell.delegate = self
            cell.setReminder(reminder, profile: self.profile(for: reminder.profileID))
            return cell
        }
        
        fetchController.delegate = self
        fetchController.performFetch()
        
        headerView.backgroundColor = Colors.backgroundColor
        self.view.addSubview(headerView)
        
        titleLabel.text = "Practice Reminders"
        titleLabel.textColor = Colors.text
        titleLabel.font = Fonts.semibold.withSize(17)
        titleLabel.textAlignment = .center
        headerView.addSubview(titleLabel)
        
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .bold))?.withRenderingMode(.alwaysTemplate), for: .normal)
        backButton.tintColor = Colors.text
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        backButton.contentHorizontalAlignment = .left
        backButton.contentEdgeInsets.left = Constants.smallMargin - 1
        headerView.addSubview(backButton)
        
        newReminderButton.backgroundColor = Colors.backgroundColor
        newReminderButton.style = .floating
        newReminderButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.newReminder()
        }
        view.addSubview(newReminderButton)
        
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.separatorInset = .zero
        tableView.rowHeight = 88
        tableView.estimatedRowHeight = 88
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 10))
        tableView.register(ReminderCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
    }
    
    private func profile(for id: String?) -> CDProfile? {
        let request = CDProfile.fetchRequest() as NSFetchRequest<CDProfile>
        if let profiles = try? DataManager.context.fetch(request) {
            return profiles.first { $0.uuid == id }
        }
        return nil
    }
    
    private func updateEmptyState(isEmpty: Bool, animate: Bool = false) {
        if isEmpty {
            if emptyStateView == nil {
                let view = UIImageView()
                view.image = UIImage(name: "alarm.fill", pointSize: 120, weight: .regular)
                view.tintColor = Colors.lightColor
                view.isUserInteractionEnabled = false
                
                if animate {
                    view.alpha = 0
                    UIView.animate(withDuration: 0.4, delay: 0.2, options: .curveEaseInOut, animations: {
                        view.alpha = 1
                    }, completion: nil)

                }
                
                self.view.insertSubview(view, belowSubview: tableView)
                self.emptyStateView = view
            }
        } else {
            emptyStateView?.removeFromSuperview()
            emptyStateView = nil
        }
    }
    
    override func didAppear() {
        super.didAppear()
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                [weak self] in
                guard let self = self else { return }
                
                if settings.authorizationStatus == .denied {
                    self.displayNeedsNotificationsAlert()
                }
                else if settings.authorizationStatus != .authorized {
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .sound]) { granted, error in
                        
                        if granted == false {
                            DispatchQueue.main.async {
                                [weak self] in
                                guard let self = self else { return }
                                
                                self.displayNeedsNotificationsAlert()
                            }
                            
                        }
                        
                    }
                }
            }
            
        }
        
    }
    
    private func displayNeedsNotificationsAlert() {
        let alert = UIAlertController(title: "Turn on notifications", message: "To use practice reminders, you'll need to allow notifications from Andante", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler: { action in
            if let appSettings = NSURL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(appSettings as URL, options: [:], completionHandler: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    private func newReminder() {
        let vc = NewReminderViewController()
        vc.popoverPresentationController?.sourceView = newReminderButton
        vc.popoverPresentationController?.sourceRect = CGRect(
            x: newReminderButton.bounds.center.x - 1,
            y: newReminderButton.bounds.minY + 4,
            width: 2, height: 2)
        vc.popoverPresentationController?.permittedArrowDirections = .down
        vc.profile = User.getActiveProfile()
        vc.action = { reminderModel in
            let context = DataManager.backgroundContext
            let reminder = CDReminder(context: context)
            reminder.date = reminderModel.date
            reminder.setDays(reminderModel.days)
            reminder.profileID = reminderModel.profileID
            reminder.isEnabled = reminderModel.isEnabled
            reminder.scheduleNotification(context: context)
            try? context.save()
            

        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc func didTapBack() {
        self.close()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        headerView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 66)
        
        backButton.frame = CGRect(x: 0, y: 6, width: 50, height: 60)
        titleLabel.frame = CGRect(x: 50, y: 6, width: headerView.bounds.width - 100, height: 60)
        
        let buttonSize = newReminderButton.sizeThatFits(self.view.bounds.size)
        newReminderButton.frame = CGRect(
            x: 0, y: view.bounds.maxY - buttonSize.height,
            width: buttonSize.width, height: buttonSize.height)
        
        
        emptyStateView?.sizeToFit()
        emptyStateView?.center = CGPoint(
            x: view.bounds.midX,
            y: headerView.frame.maxY + (newReminderButton.frame.minY - headerView.frame.maxY)/2)
        
        
        tableView.frame = CGRect(
            from: CGPoint(x: 0, y: headerView.frame.maxY),
            to: CGPoint(x: view.bounds.maxX, y: newReminderButton.frame.minY))
        
    }
    
}

extension RemindersViewController: UITableViewDelegate, ReminderCellDelegate, FetchedObjectControllerDelegate {
    
    func fetchedObjectControllerDidUpdate(isEmpty: Bool, firstUpdate: Bool) {
        self.updateEmptyState(isEmpty: isEmpty, animate: false)
    }
    
    func reminderCellDidToggleSwitch(_ cell: ReminderCell, isOn: Bool) {
        //os_log("Setting reminder enabled: %{isOn}@ after user toggles switch", isOn)
        cell.reminder?.setEnabled(isOn)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? ReminderCell else { return }
        
        let vc = NewReminderViewController()
        
        vc.popoverPresentationController?.sourceView = cell
        vc.popoverPresentationController?.sourceRect = CGRect(
            x: cell.iconView.frame.maxX + Constants.smallMargin + 2,
            y: cell.iconView.frame.midY + 2,
            width: 4, height: 4)
        vc.popoverPresentationController?.permittedArrowDirections = .left
        
        guard let reminder = fetchController.object(at: indexPath) else { return }
        vc.reminder = reminder
        vc.profile = profile(for: reminder.profileID)
        vc.action = {
            [weak self] reminderModel in
            guard let self = self else { return }
            
            if reminder.profileID != reminderModel.profileID {
                cell.setReminder(reminder, profile: self.profile(for: reminderModel.profileID))
            }
            
            reminder.profileID = reminderModel.profileID
            reminder.date = reminderModel.date
            reminder.setDays(reminderModel.days)
            reminder.isEnabled = reminderModel.isEnabled
            reminder.scheduleNotification()
            
            DataManager.saveContext()
        }
        
        vc.deleteAction = {
            reminder.unscheduleNotification()
            DataManager.context.delete(reminder)
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
}

protocol ReminderCellDelegate: class {
    func reminderCellDidToggleSwitch(_ cell: ReminderCell, isOn: Bool)
}

class ReminderCell: UITableViewCell {
    
    private let bgView = MaskedShadowView()
    
    public weak var delegate: ReminderCellDelegate?
    
    public var reminder: CDReminder?
    public var profile: CDProfile?
    
    private var cancellables = Set<AnyCancellable>()
    
    public func setReminder(_ reminder: CDReminder?, profile: CDProfile?) {
        self.reminder = reminder
        self.profile = profile
        
        cancellables.removeAll()
        
        profile?.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            self.updateUI()
        }.store(in: &cancellables)
        
        reminder?.objectWillChange.sink {
            [weak self] in
            guard let self = self else { return }
            self.updateUI()
        }.store(in: &cancellables)
        
        updateUI()
    }
    
    private let titleLabel = UILabel()
    private let onButton = UISwitch()
    private let detailLabel = UILabel()
    public let iconView = ProfileImageView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
        self.backgroundColor = .clear
        
        iconView.backgroundColor = Colors.lightColor
        bgView.addSubview(iconView)
                
        bgView.addSubview(titleLabel)
        titleLabel.font = Fonts.semibold.withSize(18)
        titleLabel.textColor = Colors.text
        
        bgView.addSubview(detailLabel)
        detailLabel.font = Fonts.regular.withSize(15)
        detailLabel.textColor = Colors.lightText
        detailLabel.adjustsFontSizeToFitWidth = true
        detailLabel.minimumScaleFactor = 0.1
        
        onButton.onTintColor = Colors.green
        onButton.addTarget(self, action: #selector(didToggleButton), for: .valueChanged)
        bgView.addSubview(onButton)
        
        contentView.addSubview(bgView)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            bgView.pushDown()
        } else {
            bgView.pushUp()
        }
    }
    
    @objc func didToggleButton() {
        delegate?.reminderCellDidToggleSwitch(self, isOn: onButton.isOn)
    }
    
    private func updateUI() {
        
        guard let reminder = self.reminder, let profile = self.profile else { return }
        let days = reminder.getDays()
        
        iconView.profile = profile
        titleLabel.text = reminder.date?.string(timeStyle: .short) ?? ""
        onButton.isOn = reminder.isEnabled
        
        if days.count == 7 {
            detailLabel.text = "Every day"
        } else if days.count == 0 {
            detailLabel.text = "No repeat"
        } else {
            let weekdays: Set<Int> = [0,1,2,3,4]
            if weekdays == Set<Int>(days) {
                detailLabel.text = "Weekdays"
                return
            }
            
            let weekends: Set<Int> = [5,6]
            if weekends == Set<Int>(days) {
                detailLabel.text = "Weekends"
                return
            }
            
            var string = ""
            for (i, day) in Array(days).sorted().enumerated() {
                string += Formatter.weekdayString(day).prefix(3)
                if i < days.count - 1 {
                    string += ", "
                }
            }
            detailLabel.text = string
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        onButton.sizeToFit()
        
        bgView.frame = self.bounds.insetBy(dx: Constants.smallMargin, dy: 4)
               
        let titleSize = titleLabel.sizeThatFits(bgView.bounds.size)
        let detailSize = detailLabel.sizeThatFits(bgView.bounds.size)
        let padding: CGFloat = 0

        let combinedHeight = titleSize.height + detailSize.height + padding
        let minY = bgView.bounds.height/2 - combinedHeight/2
               
        iconView.frame = CGRect(x: Constants.smallMargin, y: bgView.bounds.midY - 23,
                                       width: 46, height: 46)
               
        titleLabel.frame = CGRect(
            from: CGPoint(x: iconView.frame.maxX + 16, y: minY),
            to: CGPoint(
                x: bgView.bounds.maxX - Constants.margin - onButton.bounds.width - 16,
                y: minY + titleSize.height))

        onButton.center = CGPoint(
            x: bgView.bounds.maxX - Constants.smallMargin - onButton.bounds.width/2,
            y: bgView.bounds.midY)
        
        
        detailLabel.frame = CGRect(
            from: CGPoint(x: titleLabel.frame.minX, y: titleLabel.frame.maxY + padding),
            to: CGPoint(x: onButton.frame.minX - 16, y: titleLabel.frame.maxY + padding + detailSize.height))
        
        
    }
}

