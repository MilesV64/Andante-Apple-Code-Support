//
//  Tuner.swift
//  Andante
//
//  Created by Miles Vinson on 11/17/20.
//  Copyright © 2020 Miles Vinson. All rights reserved.
//


import AVFoundation
import Foundation

class Tuner {
    
    private var selectedTuner = 0
    public func setSelectedTuner(_ option: Int) {
        if selectedTuner == option { return }
        
        let isPlaying = self.isPlaying
        
        if selectedTuner == 0 {
            if synth.isPlaying {
                synth.stop()
            }
        } else if selectedTuner == 1 {
            if audioPlayers.isPlaying {
                audioPlayers.stop()
            }
        }
        
        selectedTuner = option
        
        if isPlaying {
            if selectedTuner == 0 {
                synth.start()
            } else if selectedTuner == 1 {
                audioPlayers.start()
            }
        }
        
    }
    
    private let synth = Synth()
    private let audioPlayers = AudioPlayers()
    
    public var octave: Int = 2 {
        didSet {
            synth.octave = octave
        }
    }
    
    public func play() {
        if selectedTuner == 0 {
            synth.start()
        } else {
            audioPlayers.start()
        }
    }
    
    public func stop() {
        if selectedTuner == 0 {
            synth.stop()
        } else {
            audioPlayers.stop()
        }
    }
    
    public var volume: Float = 1 {
        didSet {
            synth.setVolume(volume)
            audioPlayers.volume = volume
        }
    }
    
    public var isPlaying: Bool {
        return selectedTuner == 0 ? synth.isPlaying : audioPlayers.isPlaying
    }
    
    public func setNote(_ note: Int) {
        synth.setNote(note)
        
        var filename: String
        
        switch note {
        case 0: filename = "C"
        case 1: filename = "Db"
        case 2: filename = "D"
        case 3: filename = "Eb"
        case 4: filename = "E"
        case 5: filename = "F"
        case 6: filename = "F#"
        case 7: filename = "G"
        case 8: filename = "Ab"
        case 9: filename = "A"
        case 10: filename = "Bb"
        case 11: filename = "B"
        default: filename = "C"
        }
        
        audioPlayers.setSound(Bundle.main.url(forResource: filename, withExtension: "mp3")!)
        
        
    }
    
}

class AudioPlayers: NSObject, AVAudioPlayerDelegate {
    
    private var url: URL?
    
    var first: AVAudioPlayer?
    var second: AVAudioPlayer?
    var duration: TimeInterval = 0
    
    var timer: Timer?
    
    var phase = 0
    
    var isPlaying = false
    
    var volume: Float = 1
    
    func start() {
        phase = 0
        
        self.duration = first?.duration ?? 0
        
        if second?.isPlaying ?? false {
            second?.stop()
        }
        
        isPlaying = true
        
        first?.currentTime = duration/2
        first?.volume = 0
        first?.play()

        second?.currentTime = 0
        second?.volume = 0
        second?.play()
        
        var initialFade = true
                
        let fadeDuration = self.duration*0.5
        
        var lastTime = CACurrentMediaTime()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true, block: {
            [weak self] timer in
            guard let self = self else { return }
            
            let player = self.phase == 0 ? self.second : self.first
            let fadePlayer = self.phase == 0 ? self.first : self.second
            
            let diff = CACurrentMediaTime() - lastTime
            let progress = min(1, Float(diff/fadeDuration))
            
            if initialFade {
                let initialFadeProgress = 0.975 * min(1, ((progress / 0.025)))
                fadePlayer?.volume = initialFadeProgress*self.volume
                
                if initialFadeProgress == 0.975 {
                    initialFade = false
                }
            }
            else {
                fadePlayer?.volume = self.volume - (self.volume*progress)
            }
            
            player?.volume = self.volume*progress
            
            
            if diff >= fadeDuration {
                lastTime = CACurrentMediaTime()
                fadePlayer?.currentTime = 0
                fadePlayer?.volume = 0
                fadePlayer?.play()
                self.phase = self.phase == 0 ? 1 : 0
            }
            
            
        })
        
    }
    
    func stop(duration: TimeInterval = 0.25, _ completion: (()->Void)? = nil) {
        isPlaying = false
        
        timer?.invalidate()
        first?.setVolume(0, fadeDuration: duration)
        second?.setVolume(0, fadeDuration: duration)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            [weak self] in
            guard let self = self else { return }
            
            guard self.isPlaying == false else { return }
            
            self.first?.stop()
            self.second?.stop()
            
            completion?()

        }
    }
    
    func setSound(_ url: URL) {
        
        func set() {
            self.url = url
            first = createPlayer()
            second = createPlayer()
        }
        
        if isPlaying {
            stop(duration: 0.15) {
                [weak self] in
                guard let self = self else { return }
                
                set()
                self.start()
            }
        } else {
            set()
        }
        
        
    }
    
    private func createPlayer() -> AVAudioPlayer? {
        guard let url = self.url else { return nil }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            return player
        }
        catch {
            print("Error starting player", error.localizedDescription)
        }
        
        return nil
    }
    
}

class PureTuners: NSObject {
    
    
    
}

extension Float {
    /// Rounds the double to decimal places value
    func rounded(_ places: Int) -> Float {
        let divisor = pow(10.0, Float(places))
        return (self * divisor).rounded() / divisor
    }
}
