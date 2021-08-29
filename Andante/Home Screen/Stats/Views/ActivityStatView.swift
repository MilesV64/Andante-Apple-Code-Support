//
//  ActivityStatView.swift
//  Andante
//
//  Created by Miles Vinson on 8/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class ActivityStatView: StatBackgroundView, StatDataSource {
    
    public static let height: CGFloat = 297
    
    private var layout: UICollectionViewFlowLayout!
    private var collectionView: UICollectionView!
    
    private var maxTime: Int = 0
    private var totalDays: Int = 0
    private var offset: Int = 0
    private var startDay: Day = Day(date: Date())
    private var labels: [Day : UILabel] = [:]
    
    private var lastDay: Day?
    
    //for blocking collectionview
    private let leftView = UIView()
    private let rightView = UIView()
    
    private var dayLabels: [UILabel] = []
    
    private var showLabels = false
    private let tapGesture = UITapGestureRecognizer()
    
    private var lastProfile: CDProfile?
    
    private var data: [Day : Int] = [:]
    private var goal: Int = 0
    
    override init() {
        super.init()
        
        self.icon = UIImage(named: "calendar")
        self.color = Colors.orange
        self.title = "Activity"
        
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "cell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.clipsToBounds = false
        
        contentView.addSubview(collectionView)
        
        contentView.clipsToBounds = true
        
        leftView.backgroundColor = Colors.foregroundColor
        contentView.addSubview(leftView)
        
        rightView.backgroundColor = Colors.foregroundColor
        contentView.addSubview(rightView)
        
        for i in 0...6 {
            let label = UILabel()
            label.textColor = Colors.lightText
            label.font = Fonts.regular.withSize(12)
            label.text = String(Formatter.weekdayString(i).prefix(3))
            rightView.addSubview(label)
            dayLabels.append(label)
        }
        
        tapGesture.addTarget(self, action: #selector(didTapView))
        contentView.addGestureRecognizer(tapGesture)
        
    }
    
    public func reloadData() {
        guard let profile = User.getActiveProfile() else { return }
        goal = Int(profile.dailyGoal)
        if lastProfile == nil || lastProfile != profile {
            let start = Month(date: profile.creationDate ?? Date()).addingMonths(UIDevice.current.userInterfaceIdiom == .pad ? -10 : -3).date
            let end = Date()
            
            offset = start.weekday()

            let calendar = Calendar.current
            totalDays = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + offset + 1
            startDay = Day(date: start)
                    
            //TODO can this be optimized?
            collectionView.reloadData()
            collectionView.scrollToItem(at: IndexPath(row: totalDays-1, section: 0), at: .right, animated: false)
        }
        
        collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        
    }
    
    @objc func didTapView() {
        showLabels = !showLabels
        UIView.performWithoutAnimation({
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        })
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layout.itemSize = CGSize(collectionView.bounds.height/7)
        
        collectionView.frame = contentView.bounds.inset(by: UIEdgeInsets(
            top: 34, left: Constants.margin, bottom: Constants.margin, right: 50))
        
        leftView.frame = CGRect(
            from: CGPoint(x: 0, y: 1),
            to: CGPoint(x: collectionView.frame.minX, y: collectionView.frame.maxY))
        
        rightView.frame = CGRect(
            from: CGPoint(x: collectionView.frame.maxX, y: 1),
            to: CGPoint(x: contentView.bounds.maxX, y: collectionView.frame.maxY))
        
        for (i, label) in dayLabels.enumerated() {
            label.frame = CGRect(
                x: 8, y: collectionView.frame.minY - 1 + CGFloat(i)*layout.itemSize.height,
                width: rightView.bounds.width - 8,
                height: layout.itemSize.height)
        }
        
        collectionView.scrollToItem(at: IndexPath(row: totalDays-1, section: 0), at: .right, animated: false)

    }
    
    func createMonthLabel(_ day: Day) -> UILabel {
        let label = UILabel()
        label.textColor = Colors.text
        label.font = Fonts.semibold.withSize(15)
        
        let attStr = NSMutableAttributedString(
            string: Formatter.monthName(for: day.date, short: true),
            attributes: [
                .foregroundColor: Colors.text,
                .font: Fonts.semibold.withSize(15)
            ])
        
        if day.year != Day(date: Date()).year {
            attStr.append(
                NSAttributedString(
                    string: " \(day.year)",
                    attributes: [
                        .foregroundColor: Colors.lightText,
                        .font: Fonts.regular.withSize(15)
                    ]))
        }
        
        label.attributedText = attStr
        
        return label
    }
    
    func adjustMonthLabel(_ indexPath: IndexPath, day: Day) {
        let col = indexPath.row / 7
        let x = layout.itemSize.width * CGFloat(col)
        let origin = CGPoint(x: x + 1, y: -24)
        
        if labels[day] == nil {
            let label = createMonthLabel(day)
            collectionView.addSubview(label)
            labels[day] = label
        }
        
        if let label = labels[day] {
            label.sizeToFit()
            if totalDays - indexPath.row <= 7 {
                label.frame.origin = CGPoint(
                    x: x + layout.itemSize.width - 1 - label.bounds.width,
                    y: origin.y)
            }
            else {
                label.frame.origin = origin
            }
            
        }
        
    }
    
    func reloadBlock() -> StatsViewController.ReloadBlock {
        return { sessions in
            
            var data: [Day : Int] = [:]
            
            for session in sessions {
                let day = Day(date: session.startTime ?? Date())
                if data[day] == nil {
                    data[day] = Int(session.practiceTime)
                } else {
                    data[day]? += Int(session.practiceTime)
                }
            }
            
            return {
                DispatchQueue.main.async {
                    self.data = data
                    self.reloadData()
                }
            }
        }
    }
}


extension ActivityStatView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return totalDays
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! DayCell
        
        let day = startDay.addingDays(indexPath.row - offset)
        
        if let practiced = data[day] {
            if goal == 0 {
                cell.ratio = 1
            }
            else {
                let ratio = CGFloat(practiced) / CGFloat(goal)
                cell.ratio = 0.65 + (ratio * 0.35)
            }
        }
        else {
            cell.ratio = 0
        }
        
        cell.day = day.day
        cell.showLabel = showLabels
        
        if day.day == 1 {
            adjustMonthLabel(indexPath, day: day)
        }
                
        return cell
        
    }
    
}

fileprivate class DayCell: UICollectionViewCell {
    
    private let label = UILabel()
    private let bgView = UIView()
    
    public var showLabel = false {
        didSet {
            label.isHidden = !showLabel
        }
    }
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgView.roundCorners(2)
        self.addSubview(bgView)
        
        label.textColor = Colors.text
        label.font = Fonts.regular.withSize(11)
        label.textAlignment = .center
        label.isHidden = showLabel
        self.addSubview(label)
        
        
    }
    
    public var ratio: CGFloat? {
        didSet {
            if let ratio = ratio {
                if ratio == 0 {
                    bgView.backgroundColor = Colors.lightColor
                    label.textColor = Colors.lightText
                }
                else {
                    bgView.backgroundColor = Colors.orange.withAlphaComponent(ratio)
                    label.textColor = Colors.dynamicColor(light: .white, dark: Colors.text)
                }
            }
            else {
                bgView.backgroundColor = .clear
            }
        }
    }
    
    public var day: Int = 0 {
        didSet {
            label.text = "\(day)"
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        label.frame = self.bounds
        bgView.frame = self.bounds.insetBy(dx: 1, dy: 1)
        
    }
}

