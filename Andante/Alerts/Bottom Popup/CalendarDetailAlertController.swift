//
//  CalendarDetailAlertController.swift
//  Andante
//
//  Created by Miles Vinson on 2/9/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit


class CalendarDetailAlertController: PickerAlertController, UITableViewDelegate, UITableViewDataSource {

    private var day: Day!
        
    private var sessions: [CDSession] = []

    public var sessionHandler: ((_: CDSession)->Void)?
    public var newSessionHandler: (()->Void)?
    
    private let scrollViewContainer = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private let titleLabel = UILabel()
    private let titleSep = Separator()
    private let sessionsLabel = StatIconLabelGroup()
    private let practicedLabel = StatIconLabelGroup()
    private let moodLabel = StatIconLabelGroup()
    private let focusLabel = StatIconLabelGroup()
    
    private let newSessionButton = BottomActionButton(title: "Add a session")
    
    private var profile: CDProfile!
    
    convenience init(day: Day) {
        self.init()
        
        self.day = day
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        profile = User.getActiveProfile()
        
        panGesture.delegate = self
        
        if let sessions = PracticeDatabase.shared.sessions(for: day) {
            self.sessions = sessions.compactMap { $0.session }
        }
          
        scrollViewContainer.backgroundColor = .clear
        scrollViewContainer.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.register(PracticeSessionCalendarCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = 80
        
        let headerSep = Separator()
        headerSep.color = Colors.separatorColor
        headerSep.position = .bottom
        headerSep.insetToMargins()
        headerSep.bounds.size.height = 128
        headerSep.backgroundColor = .clear
        tableView.tableHeaderView = headerSep
        
        self.contentView.addSubview(scrollViewContainer)
        
        var sum = 0
        var avgMood = 0.0
        var avgFocus = 0.0
        for session in self.sessions {
            sum += session.practiceTime
            avgMood += Double(session.mood)
            avgFocus += Double(session.focus)
        }
        if sessions.count != 0 {
            avgMood = avgMood / Double(sessions.count)
            avgFocus = avgFocus / Double(sessions.count)
        }
        
        sessionsLabel.stat = .sessions
        sessionsLabel.titleLabel.text = "\(sessions.count)"
        sessionsLabel.detailLabel.text = "Session\(sessions.count != 1 ? "s" : "")"
        tableView.tableHeaderView?.addSubview(sessionsLabel)

        practicedLabel.stat = .practice
        practicedLabel.titleLabel.text = "\(Formatter.formatMinutesShort(mins: sum))"
        practicedLabel.detailLabel.text = "Practiced"
        tableView.tableHeaderView?.addSubview(practicedLabel)
        
        moodLabel.stat = .mood
        
        moodLabel.detailLabel.text = "Avg Mood"
        tableView.tableHeaderView?.addSubview(moodLabel)
        
        focusLabel.stat = .focus
        focusLabel.detailLabel.text = "Avg Focus"
        tableView.tableHeaderView?.addSubview(focusLabel)
        
        if sessions.count == 0 {
            moodLabel.value = 3
            moodLabel.titleLabel.text = "--"
            focusLabel.value = 3
            focusLabel.titleLabel.text = "--"
        }
        else {
            moodLabel.value = Int(round(avgMood))
            moodLabel.titleLabel.text = Formatter.formatDecimals(num: avgMood, trim: true)
            focusLabel.value = Int(round(avgFocus))
            focusLabel.titleLabel.text = Formatter.formatDecimals(num: avgFocus, trim: true)
        }
        
        titleLabel.text = day.date.string(dateStyle: .long)
        titleLabel.font = Fonts.semibold.withSize(18)
        titleLabel.textColor = Colors.text
        titleLabel.textAlignment = .center
        titleSep.backgroundColor = .clear
        titleSep.addSubview(titleLabel)
        titleSep.color = Colors.barSeparator
        titleSep.insetToMargins()
        titleSep.position = .bottom
        titleSep.isUserInteractionEnabled = true
        self.contentView.addSubview(titleSep)
        
        if sessions.count == 0 {
            newSessionButton.color = .clear
        }
        newSessionButton.insetToMargins()
        newSessionButton.action = {
            [weak self] in
            guard let self = self else { return }
            self.newSessionHandler?()
        }
        self.contentView.addSubview(newSessionButton)
        
    }
 
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if panGesture.velocity(in: nil).y > 0 {
            if (scrollView.contentOffset.y + scrollView.contentInset.top) <= 0 {
                scrollView.isScrollEnabled = false
                scrollView.isScrollEnabled = true
            }
            else {
                disablePanWithoutClosing()
            }
        
        }
        else {
            panGesture.isEnabled = false
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        panGesture.isEnabled = true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func didSelectSession(_ session: CDSession) {
        self.closeCompletion = {
            [weak self] in
            self?.sessionHandler?(session)
        }
        self.close()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.contentOffset.y = -tableView.contentInset.top
    }
    
    override func viewDidLayoutSubviews() {
        let fullHeight = (self.view.window?.bounds.height) ?? self.view.bounds.height
        let maxHeight = fullHeight * 0.8
        self.contentHeight = min(maxHeight, (CGFloat(sessions.count) * 80) + 46 + 128 + BottomActionButton.height)
        
        tableView.alwaysBounceVertical = popoverPresentationController?.arrowDirection != .unknown
        
        super.viewDidLayoutSubviews()
        
        scrollViewContainer.frame = contentView.bounds
        
        titleSep.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 46)
        titleLabel.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width, height: 36)
        
        sessionsLabel.frame = CGRect(x: 0, y: 0, width: contentView.bounds.width/4, height: tableView.tableHeaderView!.bounds.height)
        
        practicedLabel.frame = CGRect(x: self.contentView.bounds.width*0.25, y: 0, width: self.contentView.bounds.width/4, height: tableView.tableHeaderView!.bounds.height)
        
        moodLabel.frame = CGRect(x: self.contentView.bounds.width*0.5, y: 0, width: self.contentView.bounds.width/4, height: tableView.tableHeaderView!.bounds.height)
        
        focusLabel.frame = CGRect(x: self.contentView.bounds.width*0.75, y: 0, width: self.contentView.bounds.width/4, height: tableView.tableHeaderView!.bounds.height)
        
        let buttonHeight = BottomActionButton.height
        newSessionButton.frame = CGRect(
            x: 0, y: contentView.bounds.maxY - buttonHeight,
            width: contentView.bounds.width,
            height: buttonHeight)
        
        tableView.frame = scrollViewContainer.bounds.inset(by: UIEdgeInsets(top: titleSep.frame.maxY, left: 0, bottom: newSessionButton.bounds.height, right: 0))
        tableView.contentInset.top = 0
        tableView.verticalScrollIndicatorInsets.top = tableView.contentInset.top
        
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! PracticeSessionCalendarCell
        
        cell.setSession(sessions[indexPath.row])
        
        if indexPath.row == sessions.count - 1 {
            cell.separator.isHidden = true
        } else {
            cell.separator.isHidden = false
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.didSelectSession(sessions[indexPath.row])
    }
     
}

fileprivate class PracticeSessionCalendarCell: UITableViewCell {
    
    public let separator = Separator(position: .bottom)
    private var sessionView = PracticeSessionView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.backgroundColor = .clear
        self.selectionStyle = .none
        
        separator.insetToMargins()
        self.addSubview(separator)
        self.addSubview(sessionView)
        
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.backgroundColor = Colors.cellHighlightColor
        }
        else {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
            }
        }
    }
    
    public func setSession(_ session: CDSession) {
        sessionView.setSession(session)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        separator.frame = self.bounds
        sessionView.frame = self.bounds
    }
}



class StatIconLabelGroup: UIView {
    
    private let labelGroup = LabelGroup()
    public var titleLabel: UILabel {
        return labelGroup.titleLabel
    }
    
    public var detailLabel: UILabel {
        return labelGroup.detailLabel
    }
    
    private let iconView = StatIconView()
    public var stat: Stat? {
        didSet {
            iconView.stat = stat ?? .mood
        }
    }
    
    public var value: Int? {
        didSet {
            iconView.value = value
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(iconView)
        
        labelGroup.titleLabel.textColor = Colors.text
        labelGroup.titleLabel.font = Fonts.regular.withSize(22)
        labelGroup.detailLabel.textColor = Colors.lightText
        labelGroup.detailLabel.font = Fonts.regular.withSize(14)
        labelGroup.textAlignment = .center
        labelGroup.padding = 8
        self.addSubview(labelGroup)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        labelGroup.sizeToFit()
        let spacing: CGFloat = 9
        let iconSize: CGFloat = 32
        
        let totalHeight = labelGroup.bounds.height + spacing + iconSize
        
        iconView.frame = CGRect(
            x: self.bounds.midX - iconSize/2,
            y: self.bounds.midY - totalHeight/2 - 1,
            width: iconSize, height: iconSize).integral
        iconView.roundCorners(8)
        
        labelGroup.frame = CGRect(
            x: 0, y: iconView.frame.maxY + spacing,
            width: self.bounds.width,
            height: labelGroup.bounds.height).integral
        
        
    }
}
