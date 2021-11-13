//
//  PracticeTimeStatView.swift
//  Andante
//
//  Created by Miles Vinson on 8/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class PracticeTimeStatView: BaseStatView {
    
    private var dataType: DataType = .recent
    
    private let chart = StatsChartView()
    private let lineChart = StatsLineChartView()
    
    private struct Data {
        var values: [CGFloat] = []
        var labels: [String] = []
    }
    
    private var recentData = OrderedDataDict<Day>()
    private var monthlyData = OrderedDataDict<Day>()
    private var yearlyData = OrderedDataDict<Month>()
    
    private var weekdayData = OrderedTrendDict<Int>()
    private var timeData = OrderedTrendDict<Int>()
    
    private var today: Day!
    
    override init() {
        super.init()
        
        self.icon = Stat.practice.icon
        self.color = Stat.practice.color
        self.detailText = dataType.string
        
        chart.color = Colors.practiceTimeColor
        self.contentView.addSubview(chart)
        
        lineChart.color = Colors.practiceTimeColor
        lineChart.alpha = 0
        self.contentView.addSubview(lineChart)
        
        setChart(animated: false)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.title = isSmallScreen() ? "Practice" : "Practice Time"
        
        chart.frame = contentView.bounds
        lineChart.frame = contentView.bounds
        
    }
    
    override func didTapDetailButton() {
        guard let delegate = self.delegate else { return }
        
        let menu = PopupMenuViewController()
        menu.width = 208
        
        menu.addTitleItem(title: "Time Frames")
        menu.addItem(title: "Last 7 Days", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.recent)
            menu.removeIcons()
            menu.selectItem(at: 1)
        })
        menu.addItem(title: "This Month", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.monthly)
            menu.removeIcons()
            menu.selectItem(at: 2)
        })
        menu.addItem(title: "This Year", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.yearly)
            menu.removeIcons()
            menu.selectItem(at: 3)
        })
        menu.addSpacer(height: 8)
        menu.addTitleItem(title: "Trends")
        menu.addItem(title: "Time of Day", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.timeOfDay)
            menu.removeIcons()
            menu.selectItem(at: 6)
        })
        menu.addItem(title: "Day of the Week", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.weekDay)
            menu.removeIcons()
            menu.selectItem(at: 7)
        })
        
        switch self.dataType {
        case .recent: menu.selectItem(at: 1)
        case .monthly: menu.selectItem(at: 2)
        case .yearly: menu.selectItem(at: 3)
        case .timeOfDay: menu.selectItem(at: 6)
        case .weekDay: menu.selectItem(at: 7)
        default: break
        }
        
        let extraOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 34 : 0
        let point = self.convert(CGPoint(x: self.bounds.maxX - 40, y: 60 + extraOffset), to: delegate.view.window)
        menu.relativePoint = point
        menu.constrainToScreen = true
        menu.delayCompletion = false
        
        if let superview = self.superview as? UIScrollView {
            menu.setScrollview(superview)
        }
        
        menu.show(delegate)
        
    }
    
    private func setDataType(_ type: DataType) {
        self.dataType = type
        self.detailText = type.string
        self.setChart(animated: true)
    }
    
    
    private class ReloadOperation {
        public var sessions: [CDSessionAttributes]
        
        public var recentData = OrderedDataDict<Day>()
        public var monthlyData = OrderedDataDict<Day>()
        public var yearlyData = OrderedDataDict<Month>()
        
        public var weekdayData = OrderedTrendDict<Int>()
        public var timeData = OrderedTrendDict<Int>()
        
        init(_ sessions: [CDSessionAttributes]) {
            self.sessions = sessions
            
            performSetup()
                        
            for session in sessions {
                let practiceTime = CGFloat(session.practiceTime)
                let day = Day(date: session.startTime ?? Date())
                recentData[day]? += practiceTime
                monthlyData[day]? += practiceTime
                yearlyData[Month(of: day)]? += practiceTime
                
                weekdayData.addValue(key: day.date.weekday(), value: practiceTime)
                timeData.addValue(key: timeIndex(for: session.startTime ?? Date()), value: practiceTime)
            }
            
        }
        
        private func performSetup() {
            let today = Day(date: Date())
            
            for i in 0...6 {
                let day = today.addingDays(-6 + i)
                recentData.addKey(day, value: 0, label: String(Formatter.weekdayString(day.date).prefix(2)))
                
                weekdayData.addKey(i, value: -1, label: String(Formatter.weekdayString(i).prefix(2)))
            }
            
            let month = Month(date: today.date)
            let days = month.numberOfDays() - 1
            for i in 0...days {
                let day = Day(date: month.date).addingDays(i)
                
                if i == 0 {
                    monthlyData.addKey(day, value: 0, label: "\(month.month)/\(day.day)")
                }
                else if i % 6 == 0 || i == days {
                    monthlyData.addKey(day, value: 0, label: "\(day.day)")
                }
                else {
                    monthlyData.addKey(day, value: 0, label: "")
                }
            }
            
            let firstMonth = Month.firstMonthOfTheYear()
            for i in 0...11 {
                let month = firstMonth.addingMonths(i)
                
                yearlyData.addKey(month, value: 0, label: String(Formatter.monthName(for: month.date).prefix(1)))
            }
            
            for i in 0...7 {
                timeData.addKey(i, value: -1, label: timeString(for: i))
            }
        }
    
        func timeIndex(for date: Date) -> Int {
            //0, 3, 6, 9, 12, 15, 18, 21
            //0-2:59, etc
            let time = Calendar.current.component(.hour, from: date)
            return time/3
        }
        
        func timeString(for index: Int) -> String {
            if Settings.standardTime {
                return "\(3*index)"
            }
            else {
                let value = 3*index
                
                if value == 0 {
                    return "12a"
                }
                else if value == 12 {
                    return "12p"
                }
                else if value > 12 {
                    return "\(value - 12)p"
                }
                else {
                    return "\(value)a"
                }
            }
        }
    }
    
}

extension PracticeTimeStatView: StatDataSource {
    func reloadBlock() -> StatsViewController.ReloadBlock {
        return { sessions in
            let operation = ReloadOperation(sessions)
            return {
                DispatchQueue.main.async {
                    self.recentData = operation.recentData
                    self.monthlyData = operation.monthlyData
                    self.yearlyData = operation.yearlyData
                    self.weekdayData = operation.weekdayData
                    self.timeData = operation.timeData
                    self.setChart(animated: false)
                }
            }
        }
    }
    
    func setChart(animated: Bool) {
        
        var data: (total: CGFloat, values: [CGFloat], labels: [String], count: CGFloat)
            = (total: 0, values: [], labels: [], count: 0)
        switch dataType {
        case .recent:
            data.total = recentData.total
            data.values = recentData.values
            data.labels = recentData.labels
            data.count = recentData.count
        case .monthly:
            data.total = monthlyData.total
            data.values = monthlyData.values
            data.labels = monthlyData.labels
            data.count = monthlyData.count
        case .yearly:
            data.total = yearlyData.total
            data.values = yearlyData.values
            data.labels = yearlyData.labels
            data.count = yearlyData.count
        case .weekDay:
            data.values = weekdayData.values
            data.labels = weekdayData.labels
            self.descriptionText = "Showing average practice time per day of the week."
        case .timeOfDay:
            data.values = timeData.values
            data.labels = timeData.labels
            self.descriptionText = "Showing average practice time for sessions beginning at different times."
        default:
            data.total = recentData.total
            data.values = recentData.values
            data.labels = recentData.labels
        }
        
        if dataType == .yearly || dataType == .monthly || dataType == .recent {
            
            self.setFirstStatLabel(
                title: Formatter.formatMinutesShorter(mins: Int(data.total)),
                detail: "Total practiced")
            
            let avg = data.count != 0 ? Int(data.total / data.count) : 0
            self.setSecondStatLabel(
                title: Formatter.formatMinutesShorter(mins: avg),
                detail: "\(dataType == .yearly ? "Monthly" : "Daily") average")
            
            self.descriptionText = ""
            
            self.chart.alpha = 0
            self.lineChart.alpha = 0
            self.chart.setChart(values: data.values, xAxisLabels: data.labels)
            UIView.animateWithCurve(duration: animated ? 0.5 : 0, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
                self.chart.alpha = 1
            }, completion: nil)
            
        }
        else {
            self.setFirstStatLabel(
                title: "",
                detail: "")
            
            self.setSecondStatLabel(
                title: "",
                detail: "")
            
            self.chart.alpha = 0
            self.lineChart.alpha = 0
            self.lineChart.setChart(values: data.values, xAxisLabels: data.labels)
            UIView.animateWithCurve(duration: animated ? 0.5 : 0, curve: UIView.CustomAnimationCurve.cubic.easeOut, animation: {
                self.lineChart.alpha = 1
            }, completion: nil)
            
        }

        
        
        
    }
    
}

class OrderedDataDict<T: Hashable> {
    
    var dict: [T : Int] = [:]
    var values: [CGFloat] = []
    var labels: [String] = []
    var total: CGFloat = 0
    var count: CGFloat = 0
    
    func addKey(_ key: T, value: CGFloat, label: String) {
        dict[key] = values.count
        values.append(value)
        labels.append(label)
        total += value
    }
    
    subscript(key: T) -> CGFloat? {
        get {
            if let index = dict[key] {
                return values[index]
            }
            return nil
        }
        set {
            if let index = dict[key] {
                
                //get count of keys that data was inputted (rather than just all keys)
                if values[index] == 0 && newValue != 0 {
                    count += 1
                }
                
                total += ( newValue ?? 0 ) - values[index]
                values[index] = newValue ?? 0
            }
        }
    }
    
}

class OrderedTrendDict<T: Hashable> {
    
    var dict: [T : Int] = [:]
    var values: [CGFloat] = []
    var counts: [CGFloat] = []
    var labels: [String] = []
    
    var count: CGFloat = 0
    
    func addKey(_ key: T, value: CGFloat, label: String) {
        dict[key] = values.count
        values.append(value)
        labels.append(label)
        counts.append(0)
    }
    
    func addValue(key: T, value: CGFloat, log: Bool = false) {
        if let index = dict[key] {
            
            //get count of keys that data was inputted (rather than just all keys)
            if counts[index] == 0 {
                counts[index] = 1
                count += 1
                values[index] = value
            }
            else {
                let currentAvg = values[index]
                let currentSize = counts[index]
                let newValue = ( currentAvg * currentSize + value ) / ( currentSize + 1 )
                values[index] = newValue
                
            }
            
            
        }
    }
    
}
