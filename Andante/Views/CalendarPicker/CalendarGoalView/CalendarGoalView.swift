//
//  CalendarGoalView.swift
//  Andante
//
//  Created by Miles Vinson on 7/6/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class CalendarGoalView: UIView, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public weak var delegate: CalendarPickerDelegate?
    
    private let monthLabel = UILabel()
    private let weekDayLabels = WeekdayLabelsView()
    
    private var layout: CalendarFlowLayout!
    private var collectionView: UICollectionView!
    private var calendar = Calendar.current
    
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    private var currentPage = 0
    
    private var firstMonth: Month!
    private var totalMonths = 0
    private var today: Day!
    
    private let profile: CDProfile?
    
    private struct GoalData {
        let profile: CDProfile
        let proportion: CGFloat
        let goal: Int
    }
    
    private let goals: [GoalData]
    
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)
    
    init() {
        self.profile = User.getActiveProfile()
        
        if let profile = profile {
            self.goals = [GoalData(profile: profile, proportion: 1, goal: Int(profile.dailyGoal))]
        } else {
            let sum = CGFloat(CDProfile.getTotalDailyGoal())
            self.goals = CDProfile.getAllProfiles().map({ profile in
                return GoalData(
                    profile: profile,
                    proportion: CGFloat(profile.dailyGoal) / sum,
                    goal: Int(profile.dailyGoal))
            })
        }
        
        super.init(frame: .zero)
        
        if let earliest = PracticeDatabase.shared.sessions().last(where: {
            if let profile = self.profile {
                return $0.session?.profile == profile
            } else {
                return true
            }
        })?.startTime {
            firstMonth = Month(date: earliest)
        }
        else {
            firstMonth = Month(date: Date())
        }
        let currentMonth = Month(date: Date())
        totalMonths = firstMonth.monthsBetween(currentMonth) + 1
        currentPage = totalMonths - 1
        
        backButton.isEnabled = currentPage > 0
        nextButton.isEnabled = currentPage < totalMonths-1
        
        today = Day(date: Date())
        
        monthLabel.text = Formatter.formatDate(currentMonth.date, includeDay: false, includeMonth: true, includeYear: true)
        monthLabel.textColor = Colors.text
        monthLabel.font = Fonts.semibold.withSize(18)
        self.addSubview(monthLabel)
        
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .heavy)), for: .normal)
        nextButton.tintColor = Colors.text.withAlphaComponent(0.75)
        nextButton.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        self.addSubview(nextButton)
        
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .heavy)), for: .normal)
        backButton.tintColor = Colors.text.withAlphaComponent(0.75)
        backButton.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        self.addSubview(backButton)
        
        self.addSubview(weekDayLabels)
        
        layout = CalendarFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(CalendarGoalViewCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView.delegate = self
        collectionView.dataSource = self

        self.addSubview(collectionView)
        
        selectionFeedback.prepare()
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        monthLabel.frame = CGRect(
            x: Constants.margin, y: 0,
            width: self.bounds.width - Constants.margin*2,
            height: 36)
        
        let buttonSize: CGFloat = 44
        nextButton.frame = CGRect(
            x: self.bounds.maxX - Constants.margin - buttonSize + 14,
            y: monthLabel.center.y - buttonSize/2,
            width: buttonSize, height: buttonSize)
        
        backButton.frame = CGRect(
            x: nextButton.frame.minX - 2 - buttonSize,
            y: monthLabel.center.y - buttonSize/2,
            width: buttonSize, height: buttonSize)
        
        weekDayLabels.frame = CGRect(
            x: Constants.margin, y: monthLabel.frame.maxY,
            width: self.bounds.width - Constants.margin*2,
            height: 24)
        
        
        let height = self.bounds.height - (weekDayLabels.frame.maxY + 6)
        layout.itemSize = CGSize(width: Int(weekDayLabels.itemSize), height: Int(height/6))
        
        let collectionWidth = layout.itemSize.width*7
        
        collectionView.frame = CGRect(
            x: (self.bounds.width - collectionWidth)/2,
            y: weekDayLabels.frame.maxY + 6,
            width: collectionWidth,
            height: height)
        
        collectionView.scrollToItem(at: IndexPath(row: 0, section: currentPage), at: .left, animated: false)
            
    }
    
    public func reloadData() {
        collectionView.reloadSections([currentPage])
    }
    
    func numberOfRows(for month: Month) -> Int {
        return 6
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: 80 + (6*46))
    }
    
    @objc func didTapButton(_ sender: UIButton) {
        selectionFeedback.impactOccurred()
        
        if sender === backButton {
            currentPage = max(0, currentPage-1)
        }
        else {
            currentPage = min(totalMonths-1, currentPage+1)
        }
        
        collectionView.scrollToItem(at: IndexPath(row: 0, section: currentPage), at: .left, animated: false)
                
    }
}

//MARK: CollectionView delegate methods
extension CalendarGoalView {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return totalMonths
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6 * 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarGoalViewCell
        
        let month = firstMonth.addingMonths(indexPath.section)
        let firstDate = month.date
        let lastDate = firstDate.endOfMonth()
        let startDay = firstDate.weekday()
        let lastDay = calendar.component(.day, from: lastDate)
        let convertedIndex = (indexPath.row - startDay) + 1
        
        let day = Day(day: convertedIndex, month: month.month, year: month.year)
        
        cell.day = day

        cell.isPastToday = today.isBefore(day)
        
        if convertedIndex > 0 && convertedIndex <= lastDay {
            cell.isInMonth = true
        }
        else {
            cell.isInMonth = false
        }
        
        var progress: CGFloat = 0
        
        for goalData in self.goals {
            if let sessions = PracticeDatabase.shared.sessions(for: day, profile: goalData.profile) {
                let practiceTime = sessions.reduce(into: 0) { $0 += Int($1.practiceTime) }
                let profileProgress = min(1, CGFloat(practiceTime) / CGFloat(goalData.goal))
                progress += goalData.proportion * profileProgress
            }
        }
        
        cell.progress = progress
        
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.frame.width == 0 { return }
        
        var page: Int
        if scrollView.frame == .zero {
            page = 0
        }
        else {
            page = Int((scrollView.contentOffset.x+scrollView.frame.width/2)/scrollView.frame.width)
        }
                
        if page < 0 || page > totalMonths-1 {
            return
        }
        
        currentPage = page
        
        
        backButton.isEnabled = currentPage > 0
        nextButton.isEnabled = currentPage < totalMonths-1
        
        
        monthLabel.text = Formatter.formatDate(firstMonth.addingMonths(currentPage).date, includeDay: false, includeMonth: true, includeYear: true)
    }
   
}
