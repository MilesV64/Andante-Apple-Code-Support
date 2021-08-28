//
//  TotalsStatView.swift
//  Andante
//
//  Created by Miles Vinson on 8/24/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//

import UIKit

class TotalsStatView: UIView {
    
    private struct Data {
        var practiceTime: Int = 0
        var sessions: Int = 0
        var mood: Int = 0
        var focus: Int = 0
    }
    
    private let practiceView = TotalsView(.practice)
    private let sessionsView = TotalsView(.sessions)
    private let moodView = TotalsView(.mood)
    private let focusView = TotalsView(.focus)
    
    public func setCompact(_ compact: Bool) {
        [practiceView, sessionsView, moodView, focusView].forEach { $0.setCompact(compact) }
    }
    
    init() {
        super.init(frame: .zero)
        
        self.addSubview(practiceView)
        self.addSubview(sessionsView)
        self.addSubview(moodView)
        self.addSubview(focusView)
        
        practiceView.label.detailLabel.text = "Total practiced"
        sessionsView.label.detailLabel.text = "Total sessions"
        moodView.label.detailLabel.text = "Average mood"
        focusView.label.detailLabel.text = "Average focus"

        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds.insetBy(dx: 0, dy: 4)
        
        let itemWidth = (frame.width - 8 - Constants.xsMargin*2)/2
        let itemHeight = (frame.height - 8)/2
        
        practiceView.frame = CGRect(
            x: Constants.xsMargin,
            y: frame.minY,
            width: itemWidth,
            height: itemHeight)
        
        sessionsView.frame = CGRect(
            x: frame.midX + 4,
            y: frame.minY,
            width: itemWidth,
            height: itemHeight)
        
        moodView.frame = CGRect(
            x: Constants.xsMargin,
            y: frame.midY + 4,
            width: itemWidth,
            height: itemHeight)
        
        focusView.frame = CGRect(
            x: frame.midX + 4,
            y: frame.midY + 4,
            width: itemWidth,
            height: itemHeight)
        
    }
    
    private func setUI(_ data: Data) {
        practiceView.label.titleLabel.text = Formatter.formatMinutesCondensedButAlsoLong(data.practiceTime)
        
        sessionsView.label.titleLabel.text = "\(data.sessions)"
                
        if data.sessions == 0 {
            moodView.label.titleLabel.text = "--"
            focusView.label.titleLabel.text = "--"
        }
        else {
            moodView.label.titleLabel.text = Formatter.formatDecimals(
                num: Double(data.mood) / Double(data.sessions))
            
            focusView.label.titleLabel.text = Formatter.formatDecimals(
                num: Double(data.focus) / Double(data.sessions))
        }
        
    }
    
    private class ReloadOperation: Operation {
        
        public var data = Data()
        public var sessions: [CDSessionAttributes] = []
        
        override func main() {
            guard !isCancelled else { return }
            
            for session in sessions {
                guard !isCancelled else { return }
                
                data.practiceTime += Int(session.practiceTime)
                data.sessions += 1
                data.mood += Int(session.mood)
                data.focus += Int(session.focus)
                
            }
            
        }
        
    }
    
}

extension TotalsStatView: StatDataSource {
    
    func reloadBlock() -> StatsViewController.ReloadBlock {
        return { sessions in
            
            var data = Data()
            
            for session in sessions {
                data.practiceTime += Int(session.practiceTime)
                data.sessions += 1
                data.mood += Int(session.mood)
                data.focus += Int(session.focus)
            }
            
            return {
                DispatchQueue.main.async {
                    self.setUI(data)
                }
            }
        }
    }
    
}

private class TotalsView: MaskedShadowView {
    
    private let iconView = IconView()
    public let label = LabelGroup()
    
    public func setCompact(_ compact: Bool) {
        if compact {
            label.titleLabel.font = Fonts.bold.withSize(20)
        }
        else {
            label.titleLabel.font = Fonts.bold.withSize(25)
        }
        setNeedsLayout()
    }
    
    init(_ stat: Stat) {
        super.init()
        
        iconView.roundCorners(9)
        iconView.tintAdjustmentMode = .normal
        iconView.backgroundColor = stat.color
        iconView.icon = stat.icon
        iconView.iconColor = Colors.white
        self.addSubview(iconView)
        
        label.titleLabel.textColor = Colors.text
        label.titleLabel.font = Fonts.bold.withSize(20)
        label.detailLabel.textColor = Colors.lightText
        label.detailLabel.font = Fonts.regular.withSize(16)
        label.padding = 2
        
        label.titleLabel.text = "--"
        self.addSubview(label)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        iconView.iconSize = CGSize(22)
        iconView.frame = CGRect(
            x: Constants.smallMargin,
            y: Constants.smallMargin,
            width: 36,
            height: 36).integral
        
        label.detailLabel.font = Fonts.regular.withSize(isSmallScreen() ? 15 : 16)
        
        let height = label.sizeThatFits(self.bounds.size).height
        label.frame = CGRect(
            x: Constants.margin,
            y: self.bounds.maxY - height - Constants.margin,
            width: self.bounds.width - Constants.margin*2,
            height: height)
        
    }
}
