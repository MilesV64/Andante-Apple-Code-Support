//
//  CalendarPickerView.swift
//  Andante
//
//  Created by Miles Vinson on 6/30/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

@objc protocol CalendarPickerDelegate: AnyObject {
    
    @objc optional func calendarPickerDidChangeMonth(to month: Month)
    @objc optional func calendarPickerDidSelectDay(day: Day)
    
}

class CalendarPickerView: Separator, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    public weak var delegate: CalendarPickerDelegate?
    
    private let monthLabel = UILabel()
    private let weekDayLabels = WeekdayLabelsView()
    
    private var layout: CalendarFlowLayout!
    private var collectionView: UICollectionView!
    private var calendar = Calendar.current
    
    private let nextButton = UIButton(type: .system)
    private let backButton = UIButton(type: .system)
    
    private var currentPage = 0
    public var selectedDay = Day(date: Date())
    
    private var firstMonth: Month!
    private let totalMonths = 24
    
    private let selectionFeedback = UIImpactFeedbackGenerator(style: .light)

    public var interactionHandler: (()->Void)?
    
    public func setInitialDay(_ day: Day) {
        selectedDay = day
        let currentMonth = Month(date: day.date)
        currentPage = totalMonths/2
        firstMonth = currentMonth.addingMonths(-currentPage)
    }
    
    init() {
        super.init(frame: .zero)
        
        currentPage = totalMonths/2

        let currentMonth = Month(date: Date())
        firstMonth = currentMonth.addingMonths(-currentPage)
        
        self.isUserInteractionEnabled = true
        self.position = .bottom
        self.inset = UIEdgeInsets(Constants.margin)
        
        monthLabel.text = Formatter.formatDate(currentMonth.date, includeDay: false, includeMonth: true, includeYear: true)
        monthLabel.textColor = Colors.text
        monthLabel.font = Fonts.semibold.withSize(18)
        self.addSubview(monthLabel)
        
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)), for: .normal)
        nextButton.tintColor = Colors.lightText
        nextButton.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)
        self.addSubview(nextButton)
        
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)), for: .normal)
        backButton.tintColor = Colors.lightText
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
        
        collectionView.register(CalendarPickerCell.self, forCellWithReuseIdentifier: "cell")
        
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
        
        
        layout.itemSize = CGSize(width: weekDayLabels.itemSize, height: 42)
        
        let collectionWidth = layout.itemSize.width*7
        
        collectionView.frame = CGRect(
            x: (self.bounds.width - collectionWidth)/2,
            y: weekDayLabels.frame.maxY,
            width: collectionWidth,
            height: layout.itemSize.height * 6)
        
        collectionView.scrollToItem(at: IndexPath(row: 0, section: currentPage), at: .left, animated: false)
            
    }
    
    func numberOfRows(for month: Month) -> Int {
        return 6
        let firstDate = month.date
        let lastDate = firstDate.endOfMonth()
        let startDay = firstDate.weekday()
        let lastDay = calendar.component(.day, from: lastDate)
        return 1 + ((startDay + lastDay) / 7)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let collectionHeight: CGFloat = 6*42
        let monthHeight: CGFloat = 36
        let weekdayLabelsHeight: CGFloat = 24
        let extra: CGFloat = 14
        return CGSize(width: size.width, height: monthHeight + weekdayLabelsHeight + collectionHeight + extra)
    }
    
    @objc func didTapButton(_ sender: UIButton) {
        interactionHandler?()
        
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
extension CalendarPickerView {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return totalMonths
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6 * 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CalendarPickerCell
        
        let month = firstMonth.addingMonths(indexPath.section)
        let firstDate = month.date
        let lastDate = firstDate.endOfMonth()
        let startDay = firstDate.weekday()
        let lastDay = calendar.component(.day, from: lastDate)
        let convertedIndex = (indexPath.row - startDay) + 1
        
        let day = Day(day: convertedIndex, month: month.month, year: month.year)
        
        cell.day = day
        cell.selectedDay = day == selectedDay
        
        if convertedIndex > 0 && convertedIndex <= lastDay {
            cell.isInMonth = true
        }
        else {
            cell.isInMonth = false
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let month = firstMonth.addingMonths(indexPath.section)
        let firstDate = month.date
        let lastDate = firstDate.endOfMonth()
        let startDay = firstDate.weekday()
        let lastDay = calendar.component(.day, from: lastDate)
        let convertedIndex = (indexPath.row - startDay) + 1
        
        let day = Day(day: convertedIndex, month: month.month, year: month.year)
        
        if day != selectedDay && convertedIndex > 0 && convertedIndex <= lastDay {
            interactionHandler?()
            
            selectionFeedback.impactOccurred()
            
            selectedDay = day
            collectionView.reloadData()
            
            delegate?.calendarPickerDidSelectDay?(day: day)
            
        }
        
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        interactionHandler?()
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

class CalendarFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        let attr = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        
        let row = CGFloat(Int(indexPath.row/7))
        let col = CGFloat(indexPath.row % 7)
        
        var offset: CGFloat = 0
        if let width = collectionView?.bounds.width {
            offset = width * CGFloat(indexPath.section)
        }
                
        let frame = CGRect(x: col * itemSize.width + offset,
                           y: row * self.itemSize.height,
                           width: itemSize.width,
                           height: self.itemSize.height)
        
        attr.frame = frame
        
        return attr
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let arr = super.layoutAttributesForElements(in: rect)!
        return arr.map {
            atts in
            
            var atts = atts
            if atts.representedElementCategory == .cell {
                let ip = atts.indexPath
                atts = self.layoutAttributesForItem(at:ip)!
            }

            return atts
        }
    }
    
    
}






class WeekdayLabelsView: UIView {
    
    private var labels: [UILabel] = []
    
    public func margin(itemSize: CGFloat) -> CGFloat {
        let label = labels[0]
        let labelWidth = label.sizeThatFits(self.bounds.size).width
        return itemSize/2 - labelWidth/2
    }
    
    init() {
        super.init(frame: .zero)
        
        for i in 0...6 {
            let label = UILabel()
            
            label.attributedText = NSAttributedString(string: textForIndex(i), attributes: [
                .kern: 0.3
            ])
            
            label.font = Fonts.semibold.withSize(14)
            label.textColor = Colors.text.withAlphaComponent(0.34)
            
            label.sizeToFit()
            
            self.addSubview(label)
            labels.append(label)
        }
        
    }
    
    func textForIndex(_ index: Int) -> String {
        switch index {
        case 0:
            return "MON"
        case 1:
            return "TUE"
        case 2:
            return "WED"
        case 3:
            return "THU"
        case 4:
            return "FRI"
        case 5:
            return "SAT"
        default:
            return "SUN"
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        let leadingMargin = labels[0].bounds.width/2
        let trailingMargin = labels[6].bounds.width/2
        
        let itemSize = (self.bounds.width - leadingMargin - trailingMargin)/6
        
        for i in 0...6 {
            let label = labels[i]
            
            label.center.y = self.bounds.midY
            label.center.x = leadingMargin + (CGFloat(i)*itemSize)
        }
        
    }
    
    public var itemSize: CGFloat {
        let leadingMargin = labels[0].bounds.width/2
        let trailingMargin = labels[6].bounds.width/2
        return (self.bounds.width - leadingMargin - trailingMargin)/6
    }
}
