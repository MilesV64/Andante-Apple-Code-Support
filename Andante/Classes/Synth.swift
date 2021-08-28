//
//  Synth.swift
//  AudioTests
//
//  Created by Miles Vinson on 11/16/20.
//

import AVFoundation
import Foundation

class Synth {
    
    private var audioEngine: AVAudioEngine
    private var time: Float = 0
    private let sampleRate: Double
    private let deltaTime: Float
    private let twoPi = 2 * Float.pi
    private var currentPhase: Float = 0
    private var phaseIncrement: Float = 0
    
    private var volumeTimer: Timer?
    private var frequencyTimer: Timer?
    
    public var frequencyRampValue: Float = 0
    
    public var octave: Int = 3 {
        didSet {
            let freq = frequency/2 * powf(2, Float(octave-2))
            phaseIncrement = (twoPi / Float(sampleRate)) * freq
        }
    }
        
    public var frequency: Float = 440 {
        didSet {
            let freq = frequency/2 * powf(2, Float(octave-2))
            phaseIncrement = (twoPi / Float(sampleRate)) * freq
        }
    }
    
    private lazy var sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        
        for frame in 0..<Int(frameCount) {
            
            let value = sin(self.currentPhase)
            // Advance the phase for the next frame.
            self.currentPhase += self.phaseIncrement
            if self.currentPhase >= self.twoPi {
                self.currentPhase -= self.twoPi
            }
            if self.currentPhase < 0.0 {
                self.currentPhase += self.twoPi
            }
            
            for buffer in ablPointer {
                let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                buf[frame] = value
            }
        }
        
        self.frequencyRampValue = 0
        
        return noErr
    }
    
    init() {
        audioEngine = AVAudioEngine()

        let mainMixer = audioEngine.mainMixerNode
        let outputNode = audioEngine.outputNode
        let format = outputNode.inputFormat(forBus: 0)

        sampleRate = format.sampleRate
        deltaTime = 1 / Float(sampleRate)
        
        let inputFormat = AVAudioFormat(
            commonFormat: format.commonFormat,
            sampleRate: format.sampleRate,
            channels: 1,
            interleaved: format.isInterleaved)
        
        audioEngine.attach(sourceNode)
        audioEngine.connect(sourceNode, to: mainMixer, format: inputFormat)
        audioEngine.connect(mainMixer, to: outputNode, format: nil)
        mainMixer.outputVolume = 0
        
        self.volume = 1
        audioEngine.mainMixerNode.outputVolume = 0
        
    }
    
    public var volume: Float = 0
    
    public func setVolume(_ volume: Float) {
        self.volume = volume
        audioEngine.mainMixerNode.outputVolume = volume
    }

    public var isPlaying: Bool {
        return audioEngine.isRunning
    }
    
    public func start() {
        do {
           try audioEngine.start()
        } catch {
           print("Could not start engine: \(error.localizedDescription)")
        }
        
        self.setVolume(self.volume, duration: 0.08)
    }
    
    public func stop() {
        setVolume(0, duration: 0.25) {
            [weak self] in
            guard let self = self else { return }
            self.audioEngine.stop()
        }
    }
    
    private func setVolume(_ volume: Float, duration: TimeInterval, completion: (()->Void)? = nil) {
        volumeTimer?.invalidate()
        
        let interval: Float = 0.01
        let initialVolume = audioEngine.mainMixerNode.outputVolume
        let range = volume - initialVolume
        let step = (interval * range) / Float(duration)
        
        volumeTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(interval), repeats: true) {
            [weak self] timer in
            guard let self = self else { return }
            
            let newVolume = self.audioEngine.mainMixerNode.outputVolume + step
            
            if (step > 0 && newVolume >= volume) || (step < 0 && newVolume <= volume) {
                self.audioEngine.mainMixerNode.outputVolume = volume
                self.volumeTimer?.invalidate()
                completion?()
            }
            else {
                self.audioEngine.mainMixerNode.outputVolume = newVolume
            }
            
        }
    }
    
    /**
     - parameter note: 0 = C, 11 = B
     */
    func setNote(_ note: Int) {
        self.frequency = frequency(for: note)
    }
    
    private func frequency(for note: Int) -> Float {
        switch note {
        case 0: return 261.63
        case 1: return 277.18
        case 2: return 293.66
        case 3: return 311.13
        case 4: return 329.63
        case 5: return 349.23
        case 6: return 369.99
        case 7: return 392.00
        case 8: return 415.30
        case 9: return 440.00
        case 10: return 466.16
        case 11: return 493.88
        default: return 0
        }
    }
    
}


