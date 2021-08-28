//
//  TimerManager.swift
//  Andante
//
//  Created by Miles Vinson on 8/2/19.
//  Copyright © 2019 Miles Vinson. All rights reserved.
//

import UIKit

protocol TimerManagerDelegate: class {
    func timerDidUpdateMinutes(minutes: Int)
    func timerDidUpdate(seconds: Int)
}

class TimerManager: NSObject {
    
    public weak var delegate: TimerManagerDelegate?
    
    enum TimerState {
        case running, paused, stopped
    }
    
    private var timerState: TimerState = .stopped
    
    public var isPaused: Bool {
        return timerState == .paused
    }
    
    public var currentState: TimerState {
        return self.timerState
    }
    
    private var displayLink: CADisplayLink?
    
    //for keeping track of pausing/resuming
    private var timerStartDate: Date?
    private var timerStartTime: Double?
    
    /**
     In seconds
    */
    private var timerTime: Double {
        return (self.timerStartTime ?? 0) + Date().timeIntervalSince(timerStartDate ?? Date())
    }
    
    public var practiceTime: Int {
        return Int(timerTime/60)
    }
    
    public var timerSeconds: Int {
        return Int(timerTime)
    }
    
    //When the timer was initially started
    public var startTime: Date?
    
    private var lastTimerTime = -1
     
    override init() {
        super.init()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
    }
    
    @objc func updateTimer() {
        if Int(timerTime / 60) > lastTimerTime {
            lastTimerTime = Int(timerTime / 60)
            delegate?.timerDidUpdateMinutes(minutes: lastTimerTime)
        }
        
        delegate?.timerDidUpdate(seconds: Int(timerTime))
        
    }
    
    public func startTimer(start: Date = Date(), seconds: Int = 0) {
        self.startTime = start
        
        self.timerStartDate = Date().addingTimeInterval(-0.4)
        self.timerStartTime = Double(seconds)
        
        displayLink?.add(to: .current, forMode: .common)
        self.timerState = .running
    }
    
    public func pauseTimer() {
        displayLink?.invalidate()
        self.timerState = .paused
        
        self.timerStartTime = self.timerTime
        self.timerStartDate = nil

    }
    
    public func resumeTimer() {
        self.timerStartDate = Date()
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateTimer))
        displayLink?.add(to: .current, forMode: .common)
        self.timerState = .running
    }
    
    public func stopTimer() {
        displayLink?.invalidate()
        displayLink = nil
        self.timerState = .stopped
        
    }
    
    /**
     Returns minutes on the timer
    */
    public func getTimerTime() -> Int {
        return Int(round(self.timerTime/60))
    }
    
    private func getMilli(time: TimeInterval) -> Int {
        //first 2 decimals of timeinterval in seconds
        let remainder = (time - Double(Int(time)))*100
        let result = Int(round(remainder))
        if result == 100 {
            return 0
        }
        return Int(round(remainder))
    }
    
    private func formatTime(time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        
        if hours != 0 {
            return String(hours) + String(format:":%02i", (minutes % 60)) + String(format:":%02i", seconds)
        }
        
        
        return String(format:"%02i", minutes) + String(format:":%02i", seconds)
        
    }
    
}
