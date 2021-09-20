//
//  CalendarScrollView.swift
//  Andante
//
//  Created by Miles Vinson on 5/19/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit
import CoreData


protocol CalendarScrollViewDelegate: AnyObject {
    func didSelectCalendarCell(_ day: Day, sourceView: UIView?)
}


class CalendarScrollView: UIView, UICollectionViewDataSource, UICollectionViewDelegate {
    
    public var delegate: CalendarScrollViewDelegate?
    
    private var lastProfile: CDProfile?
    
    var layout: UICollectionViewFlowLayout!
    var collectionView: UICollectionView!
    
    let calendar = Calendar.current
    var startDate = Date()
    
    private var daysToDisplay: Int = 0
    
    public func reloadData() {
        collectionView.reloadSections([0])
    }
    
    init() {
        super.init(frame: .zero)
        
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 0, left: Constants.xsMargin-4, bottom: 0, right: Constants.xsMargin-4)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(CalendarCollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.clipsToBounds = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delaysContentTouches = false
        self.addSubview(collectionView)
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(databaseDidUpdate),
            name: PracticeDatabase.PracticeDatabaseDidChangeNotification, object: nil)
        
    }
    
    private var indexPathsToAnimate: [IndexPath] = []
    
    public func dayDidChange() {
        let currentCount = self.daysToDisplay
        let trueCount = self.amountOfDays()
        
        let diff = trueCount - currentCount
        
        
        if diff > 0 {
            let maxOffset = self.collectionView.contentSize.width - self.collectionView.bounds.width
            
            self.daysToDisplay += diff
            
            let indexes = (0..<diff).map { IndexPath(row: self.daysToDisplay - diff + $0, section: 0) }
            self.indexPathsToAnimate = indexes
            
            self.collectionView.insertItems(at: indexes)
            
            // Don't scroll to new cell if you already have scrolled from the end
            if self.collectionView.contentOffset.x == maxOffset {
                collectionView.scrollToItem(at: IndexPath(row: self.daysToDisplay-1, section: 0), at: .left, animated: true)
            }
            
        }
        else {
            // Something went wrong, just reload to get back on track
            self.setStartDay()
        }
    }
    
    @objc func databaseDidUpdate() {
        guard let profile = User.getActiveProfile() else { return }
        
        if lastProfile == profile {
            collectionView.reloadItems(at: collectionView.indexPathsForVisibleItems)
        }
        else {
            lastProfile = profile
            setStartDay()
        }
        
    }
    
    private func setStartDay() {
        guard let profile = lastProfile else { return }
        
        let startDate = calendar.startOfDay(for: profile.creationDate ?? Date())
        let today = calendar.startOfDay(for: Date())
        let diff = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
        if diff < 15 {
            self.startDate = calendar.date(byAdding: .day, value: -(14 - diff), to: startDate) ?? startDate
        }
        else {
            self.startDate = startDate
        }
        
        self.daysToDisplay = self.amountOfDays()
        collectionView.reloadData()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let count: CGFloat = min(14, floor(bounds.width / 75))
        
        layout.itemSize = CGSize(width: (self.bounds.width - (Constants.xsMargin-4)*2)/count,
                                 height: self.bounds.height)
        
        
        collectionView.frame = self.bounds
        
        collectionView.scrollToItem(at: IndexPath(row: self.daysToDisplay-1, section: 0), at: .left, animated: false)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.daysToDisplay
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarCollectionViewCell
        
        let day = self.day(for: indexPath.row)
        
        if let sessions = PracticeDatabase.shared.sessions(for: day) {
            cell.sessionCount = min(6, sessions.count)
        } else {
            cell.sessionCount = 0
        }
        
        cell.day = day
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectCalendarCell(self.day(for: indexPath.row), sourceView: collectionView.cellForItem(at: indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        if let firstIndex = self.indexPathsToAnimate.firstIndex(of: indexPath) {
            let cell = cell as! CalendarCollectionViewCell
            cell.animate()
            self.indexPathsToAnimate.remove(at: firstIndex)

        }
    }
    
    private func day(for index: Int) -> Day {
        return Day(date: calendar.date(byAdding: .day, value: index, to: startDate) ?? Date())
    }
    
    private func amountOfDays() -> Int {
        let today = calendar.startOfDay(for: Date())
        return 1 + (calendar.dateComponents([.day], from: startDate, to: today).day ?? 0)
    }
}

private class CalendarCollectionViewCell: UICollectionViewCell {
    
    let bgView = MaskedShadowView()

    public var day = Day(day: 0, month: 0, year: 0) {
        didSet {
            reloadData()
        }
    }
    
    public var sessionCount = 0
        
    private let centerLabel = UILabel()
    private let topLabel = UILabel()
    
    private var dots: [SessionDotView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgView.transformScale = 0.88
        bgView.isUserInteractionEnabled = false
        self.addSubview(bgView)
        
        centerLabel.font = Fonts.medium.withSize(15)
        centerLabel.textAlignment = .center
        bgView.addSubview(centerLabel)
        
        topLabel.font = Fonts.semibold.withSize(15)
        topLabel.textAlignment = .center
        bgView.addSubview(topLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func animate() {
        self.bgView.alpha = 0
        self.bgView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5).concatenating(CGAffineTransform(translationX: -self.bounds.width * 0.7, y: 0))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1, options: []) {
                self.bgView.alpha = 1
                self.bgView.transform = .identity
            } completion: { _ in
                //
            }
        }
        
    }
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                bgView.pushDown()
            }
            else {
                bgView.pushUp()
            }
        }
    }
    
    private var lastBounds = CGRect.zero
    override func layoutSubviews() {
        super.layoutSubviews()
        
        bgView.contextualFrame = self.bounds.insetBy(dx: 4, dy: 0)
                
        centerLabel.sizeToFit()
        centerLabel.center = bgView.bounds.center.offset(dx: 0, dy: 1)
        
        topLabel.frame = CGRect(x: 0, y: 5, width: bgView.bounds.width, height: centerLabel.frame.minY - 5)
        
        if dots.count == 0 { return }
        let dotPadding: CGFloat = -4
        let totalPadding = dotPadding * CGFloat(dots.count-1)
        let dotSize: CGFloat = 9
        let totalDotSize = dotSize * CGFloat(dots.count)
        let totalWidth = totalDotSize + totalPadding
        for i in 0..<dots.count {
            let dot = dots[i]
            let width = dotSize + dotPadding
            dot.frame = CGRect(x: bgView.bounds.midX - totalWidth/2 + (width*CGFloat(i)),
                               y: bgView.bounds.maxY - 20,
                               width: dotSize, height: dotSize)
        }
        
    }
    
    private func reloadData() {
        topLabel.text = "\(day.day)"
        centerLabel.text = String(Formatter.weekdayString(day.date).prefix(3))
        
        if sessionCount > dots.count {
            let dif = sessionCount - dots.count
            for _ in 0..<dif {
                let dot = SessionDotView()
                bgView.insertSubview(dot, at: 0)
                dots.append(dot)
            }
        }
        else if sessionCount < dots.count {
            let dif = dots.count - sessionCount
            for i in 0..<dif {
                dots[i].removeFromSuperview()
            }
            dots.removeSubrange(0..<dif)
        }
        
        if day == Day(date: Date()) {
            setUI(today: true)
        }
        else {
            setUI(today: false)
        }
        
        setNeedsLayout()
    }
    
    private func setUI(today: Bool) {
        if today {
            centerLabel.text = "Today"
        }
        else {
            centerLabel.text = String(Formatter.weekdayString(day.date).prefix(3))
        }
        
        if dots.count > 0 {
            bgView.backgroundColor = Colors.orange
            bgView.shadowColor = .black
            bgView.extraShadowOpacity = 0.07
            
            centerLabel.textColor = Colors.white
            topLabel.textColor = Colors.white.withAlphaComponent(0.7)
            
            for dot in dots {
                dot.outlineColor = Colors.orange
                dot.dotColor = Colors.white
            }
            
        }
        else {
            bgView.backgroundColor = Colors.foregroundColor
            bgView.shadowColor = MaskedShadowView.ShadowColor
            bgView.extraShadowOpacity = 0
            
            centerLabel.textColor = Colors.text
            topLabel.textColor = Colors.lightText
            
            for dot in dots {
                dot.outlineColor = Colors.foregroundColor
                dot.dotColor = Colors.orange
            }
            
        }
        
    }
    
}

private class SessionDotView: UIView {
    
    private var dot = UIView()
    
    public var dotColor: UIColor? {
        get {
            return dot.backgroundColor
        }
        set {
            dot.backgroundColor = newValue
        }
    }
    
    public var outlineColor: UIColor? {
        get {
            return self.backgroundColor
        }
        set {
            self.backgroundColor = newValue
        }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.backgroundColor = Colors.foregroundColor
        dot.backgroundColor = Colors.orange
        self.addSubview(dot)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        dot.frame = self.bounds.insetBy(dx: 1.5, dy: 1.5)
        self.roundCorners(prefersContinuous: false)
        dot.roundCorners(prefersContinuous: false)
        
    }
    
}
