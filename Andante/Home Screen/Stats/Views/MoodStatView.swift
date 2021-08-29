//
//  MoodStatView.swift
//  Andante
//
//  Created by Miles Vinson on 8/26/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class MoodFocusStatView: BaseStatView {
    
    enum MoodFocus {
        case mood, focus
        
        var stat: Stat {
            switch self {
            case .mood: return Stat.mood
            case .focus: return Stat.focus
            }
        }
        
        var string: String {
            switch self {
            case .mood: return "Mood"
            case .focus: return "Focus"
            }
        }
        
        func value(_ session: CDSessionAttributes) -> CGFloat {
            switch self {
            case .mood: return CGFloat(session.mood)
            case .focus: return CGFloat(session.focus)
            }
        }
    }
    
    private var type: MoodFocus = .mood
    
    private var dataType: DataType = .recent
    
    private let chart = StatsChartView()
    private let lineChart = StatsLineChartView()
    
    private struct Data {
        var values: [CGFloat] = []
        var labels: [String] = []
    }
    
    private var recentData = OrderedTrendDict<Day>()
    private var monthlyData = OrderedTrendDict<Day>()
    
    private var weekdayData = OrderedTrendDict<Int>()
    private var timeData = OrderedTrendDict<Int>()
    private var lengthData = OrderedTrendDict<Int>()
    
    private var today: Day!
    
    init(_ type: MoodFocus) {
        super.init()
        
        self.type = type
        
        self.icon = type.stat.icon
        self.color = type.stat.color
        self.title = type.string
        self.detailText = dataType.string
        
        chart.fixedMaxValue = 5
        chart.color = type.stat.color
        self.contentView.addSubview(chart)
        
        lineChart.fixedMaxValue = 5
        lineChart.color = type.stat.color
        lineChart.alpha = 0
        self.contentView.addSubview(lineChart)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
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
        menu.addSpacer(height: 8)
        menu.addTitleItem(title: "Trends")
        menu.addItem(title: "Time of Day", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.timeOfDay)
            menu.removeIcons()
            menu.selectItem(at: 5)
        })
        menu.addItem(title: "Day of the Week", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.weekDay)
            menu.removeIcons()
            menu.selectItem(at: 6)
        })
        menu.addItem(title: "Length of Session", icon: nil, handler: {
            [weak self] in
            guard let self = self else { return }
            self.setDataType(.sessionLength)
            menu.removeIcons()
            menu.selectItem(at: 7)
        })
        
        switch self.dataType {
        case .recent: menu.selectItem(at: 1)
        case .monthly: menu.selectItem(at: 2)
        case .timeOfDay: menu.selectItem(at: 5)
        case .weekDay: menu.selectItem(at: 6)
        case .sessionLength: menu.selectItem(at: 7)
        default: break
        }
        
        let extraOffset: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 34 : 0
        let point = self.convert(CGPoint(x: self.bounds.maxX - 40, y: 10 + extraOffset), to: delegate.view.window)
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
        
        public var recentData = OrderedTrendDict<Day>()
        public var monthlyData = OrderedTrendDict<Day>()
        
        public var weekdayData = OrderedTrendDict<Int>()
        public var timeData = OrderedTrendDict<Int>()
        public var lengthData = OrderedTrendDict<Int>()
        
        private let type: MoodFocus
        
        init(_ type: MoodFocus, _ sessions: [CDSessionAttributes]) {
            self.type = type
            self.sessions = sessions
            
            performSetup()
               
            for session in sessions {
                
                let day = Day(date: session.startTime ?? Date())
                let value = type.value(session)
                
                recentData.addValue(key: day, value: value)
                monthlyData.addValue(key: day, value: value)

                weekdayData.addValue(key: day.date.weekday(), value: value)
                timeData.addValue(key: timeIndex(for: session.startTime ?? Date()), value: value)
                lengthData.addValue(key: lengthIndex(for: session), value: value)
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
            
            for i in 0...7 {
                timeData.addKey(i, value: -1, label: timeString(for: i))
            }
            
            for i in 0...6 {
                lengthData.addKey(i, value: -1, label: lengthString(for: i))
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
        
        func lengthIndex(for session: CDSessionAttributes) -> Int {
            let time = Int(session.practiceTime)
            return min(6, time/10)
        }
        
        func lengthString(for index: Int) -> String {
            switch index {
                case 0: return "0m+"
                case 1: return "10m+"
                case 2: return "20m+"
                case 3: return "30m+"
                case 4: return "40m+"
                case 5: return "50m+"
                case 6: return "60m+"
                default: return ""
            }
        }
        
    }
    
    
}

extension MoodFocusStatView: StatDataSource {
    
    func reloadBlock() -> StatsViewController.ReloadBlock {
        return { sessions in
            let operation = ReloadOperation(self.type, sessions)
            return {
                DispatchQueue.main.async {
                    self.recentData = operation.recentData
                    self.monthlyData = operation.monthlyData
                    self.weekdayData = operation.weekdayData
                    self.timeData = operation.timeData
                    self.lengthData = operation.lengthData
                    self.setChart(animated: false)
                }
            }
        }
    }
    
    func setChart(animated: Bool) {
        
        var data: (
            values: [CGFloat],
            labels: [String],
            count: CGFloat)
            = (values: [], labels: [], count: CGFloat(0))
        switch dataType {
        case .recent:
            data.values = recentData.values
            data.labels = recentData.labels
            data.count = recentData.count
        case .monthly:
            data.values = monthlyData.values
            data.labels = monthlyData.labels
            data.count = monthlyData.count
        case .weekDay:
            data.values = weekdayData.values
            data.labels = weekdayData.labels
            self.descriptionText = "Showing average \(type.string.lowercased()) per day of the week."
        case .timeOfDay:
            data.values = timeData.values
            data.labels = timeData.labels
            self.descriptionText = "Showing average \(type.string.lowercased()) for sessions beginning at different times."
        case .sessionLength:
            data.values = lengthData.values
            data.labels = lengthData.labels
            self.descriptionText = "Showing average \(type.string.lowercased()) vs length of session."
        default:
            data.values = recentData.values
            data.labels = recentData.labels
        }
        
        if dataType == .yearly || dataType == .monthly || dataType == .recent {
            
            
            var total: CGFloat = 0
            var count: CGFloat = 0
            for avg in data.values {
                if avg != 0 {
                    total += avg
                    count += 1
                }
            }
            let avg = count > 0 ? ( total / count ) : 0
            self.setFirstStatLabel(
                title: Formatter.formatDecimals(num: Double(avg)),
                detail: "Daily Average")
            
            self.setSecondStatLabel(
                title: "",
                detail: "")
            
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
