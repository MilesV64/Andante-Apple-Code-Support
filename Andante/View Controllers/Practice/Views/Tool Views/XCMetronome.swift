//
//  Metronome.swift
//  MetronomeKit_WatchOS
//
//  Created by xiangyu sun on 9/8/18.
//  Copyright © 2018 xiangyu sun. All rights reserved.
//
import Foundation
import AVFoundation
import os


public protocol MetronomeDelegate: class {
    func metronomeTicking(_ metronome: Metronome, currentTick: Int)
}

public final class Metronome {
    
    public private(set) var tempoBPM = 0
    
    public private(set) var isPlaying = false
    
    public weak var delegate: MetronomeDelegate?
    
    let engine: AVAudioEngine = AVAudioEngine()
    /// owned by engine
    let player: AVAudioPlayerNode = AVAudioPlayerNode()
    
    var bufferSampleRate: Double!
    var audioFormat: AVAudioFormat!
    
    var timeInterval: TimeInterval = 0
    
    var syncQueue = DispatchQueue(label: "Metronome")

    var nextBeatSampleTime: AVAudioFramePosition = 0
    /// controls responsiveness to tempo changes
    
    var playerStarted = false

    var buffer: AVAudioPCMBuffer?
    
    public init() {
        
        let clickURL = Bundle.main.url(forResource: "metronome.click", withExtension: "wav")!
        let audioFile = try! AVAudioFile(forReading: clickURL)
        let audioFormat = audioFile.processingFormat
        let audioFrameCount = UInt32(0.02 * audioFormat.sampleRate)
        
        buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: audioFrameCount)
        buffer!.frameLength = audioFrameCount
        
        try! audioFile.read(into: buffer!)
        
        self.audioFormat = buffer!.format
        self.bufferSampleRate = self.audioFormat.sampleRate
        
        initiazeDefaults()

        
    }
    
    deinit {
        self.stop()
        engine.detach(player)
        buffer = nil
    }
    
    public func start() throws {
        
        if player.engine == nil {
            engine.attach(player)
            engine.connect(player, to:  engine.outputNode, fromBus: 0, toBus: 0, format: self.audioFormat)
        }
        
        // Start the engine without playing anything yet.
        try engine.start()
        
        isPlaying = true
        
        updateTimeInterval()
        nextBeatSampleTime = 0
        
        self.syncQueue.async() {
            self.scheduleBeats()
        }
    }
    
    func initiazeDefaults() {
        tempoBPM = 120
        timeInterval = 0
    }

    
    public func stop() {
        isPlaying = false
        
        /* Note that pausing or stopping all AVAudioPlayerNode's connected to an engine does
         NOT pause or stop the engine or the underlying hardware.
         
         The engine must be explicitly paused or stopped for the hardware to stop.
         */
        player.stop()
        player.reset()
        
        /* Stop the audio hardware and the engine and release the resources allocated by the prepare method.
         
         Note that pause will also stop the audio hardware and the flow of audio through the engine, but
         will not deallocate the resources allocated by the prepare method.
         
         It is recommended that the engine be paused or stopped (as applicable) when not in use,
         to minimize power consumption.
         */
        engine.stop()
        
        playerStarted = false
    }
    
    public func setTempo(to value: Int) {
        
        tempoBPM = value
        
        updateTimeInterval()
    }
    
    public func reset() {
        
        initiazeDefaults()
        updateTimeInterval()
        
        isPlaying = false
        playerStarted = false
    }
    
    func scheduleBeats() {
        if (!isPlaying) { return }
        
        let playerBeatTime = AVAudioTime(sampleTime: nextBeatSampleTime, atRate: bufferSampleRate)
        // This time is relative to the player's start time.
        
        player.scheduleBuffer(buffer!, at: playerBeatTime, options: AVAudioPlayerNodeBufferOptions(rawValue: 0), completionHandler: {
            self.syncQueue.async() {
                self.scheduleBeats()
            }
        })
                
        if (!playerStarted && engine.isRunning) {
            // We defer the starting of the player so that the first beat will play precisely
            // at player time 0. Having scheduled the first beat, we need the player to be running
            // in order for nodeTimeForPlayerTime to return a non-nil value.
            player.play()
            playerStarted = true
        }
        
        // Schedule the delegate callback (metronomeTicking:bar:beat:) if necessary.
        
        if let delegate = self.delegate, let nodeBeatTime = player.nodeTime(forPlayerTime: playerBeatTime) {
            
            let output: AVAudioIONode = engine.outputNode
                            
            let latencyHostTicks: UInt64 = AVAudioTime.hostTime(forSeconds: output.presentationLatency)
            let dispatchTime = DispatchTime(uptimeNanoseconds: nodeBeatTime.hostTime + latencyHostTicks)
            
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: dispatchTime) {
                DispatchQueue.main.async {
                    if self.isPlaying {
                        delegate.metronomeTicking(self, currentTick: 0)
                    }
                }
            }
        }
        
        let samplesPerBeat = AVAudioFramePosition(timeInterval * bufferSampleRate)
        nextBeatSampleTime += samplesPerBeat
    }
    

    func updateTimeInterval() {
        timeInterval = (60.0 / Double(tempoBPM))
    }
    
 
}
