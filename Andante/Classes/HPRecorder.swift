
import Foundation
import AVFoundation

public class HPRecorder: NSObject {
   
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    open var session: AVAudioSession!
    open var audioRecorder: AVAudioRecorder?

    private var levelTimer: Timer?
    // Time interval to get percent of loudness
    open var timeInterVal: TimeInterval = 0.014
    // File name of audio
    open var audioFilename: URL!
    
    public var isRecording = false

    // Recorder did finish
    open var recorderDidFinish: ((_ recocorder: AVAudioRecorder, _ url: URL, _  success: Bool) -> Void)?
    // Recorder occur error
    open var recorderOccurError: ((_ recocorder: AVAudioRecorder, _ error: Error) -> Void)?
    // Percent of loudness
    open var percentLoudness: ((_ percent: Float) -> Void)?

    open lazy var settings: [String : Any] = {
        return [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
    }()

    public init(settings: [String : Any], audioFilename: URL, audioInput: AVAudioSessionPortDescription) {
        super.init()
        self.session = AVAudioSession.sharedInstance()
        self.settings = settings
        self.audioFilename = audioFilename
        
    }

    public override init() {
        super.init()
        self.session = AVAudioSession.sharedInstance()
        
        try? self.session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetooth])
        
    }
    
    // Ask permssion to record audio
    public func askPermission(completion: ((_ allowed: Bool) -> Void)?) {
        if session.responds(to: #selector(AVAudioSession.requestRecordPermission(_:))) {
            session.requestRecordPermission({(granted: Bool) -> Void in
                completion?(granted)
            })
        } else {
            completion?(false)
        }
    }

    private func getFilename() -> URL {
        return RecordingsManager.getRecordingsDirectory().appendingPathComponent(UUID().uuidString + ".m4a")
    }
    
    public func prepare() {
        if audioFilename == nil {
            self.audioFilename = getFilename()
        }
    }
    
    public func willStartRecording(completion: (()->())?) {
        
        DispatchQueue.global(qos: .background).async {
            [weak self] in
            guard let self = self else { return }
            
            do {
                try self.session.setActive(true)
            }
            catch {
                print(error)
            }
            
            
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    // Start recording
    public func startRecording() {

        do {
            if audioRecorder == nil {
                if audioFilename == nil {
                    self.audioFilename = getFilename()
                }
                audioRecorder = try AVAudioRecorder(url: self.audioFilename, settings: settings)
            }
            
            audioRecorder!.delegate = self
            audioRecorder!.record()
            audioRecorder!.isMeteringEnabled = true

            self.levelTimer = Timer.scheduledTimer(withTimeInterval: timeInterVal, repeats: true, block: { [weak self] (timer) in
                self?.levelTimerCallback()
            })

            isRecording = true

        } catch {
            print(error)
            endRecording()
        }
    }

    // End recording
    public func endRecording() {
        self.levelTimer?.invalidate()
        self.levelTimer = nil
        
        audioRecorder?.stop()
        audioRecorder?.delegate = nil
        audioRecorder = nil
        
        isRecording = false
        audioFilename = nil
        
    }

    // Pause recorinding - not used
    public func pauseRecording() {
        guard let audioRecorder = audioRecorder else { return }
        if audioRecorder.isRecording {
            audioRecorder.pause()
            isRecording = false
        }
    }

    // Resume recording - not used
    public func resumeRecording() {
        guard let audioRecorder = audioRecorder else { return }
        if !audioRecorder.isRecording {
            audioRecorder.record()
            isRecording = true
        }
    }

    @objc func levelTimerCallback() {
        guard let audioRecorder = audioRecorder else { return }
        audioRecorder.updateMeters()
        let averagePower = audioRecorder.averagePower(forChannel: 0)
        let percentage = self.getIntensityFromPower(decibels: averagePower)
        self.percentLoudness?(percentage*100)
    }

    // Will return a value between 0.0 ... 1.0, based on the decibels
    func getIntensityFromPower(decibels: Float) -> Float {
        let minDecibels: Float = -160
        let maxDecibels: Float = 0

        // Clamp the decibels value
        if decibels < minDecibels {
            return 0
        }
        if decibels >= maxDecibels {
            return 1
        }

        // This value can be adjusted to affect the curve of the intensity
        let root: Float = 2

        let minAmp = powf(10, 0.05 * minDecibels)
        let inverseAmpRange: Float = 1.0 / (1.0 - minAmp)
        let amp: Float = powf(10, 0.05 * decibels)
        let adjAmp = (amp - minAmp) * inverseAmpRange

        return powf(adjAmp, 1.0 / root)
    }
}

extension HPRecorder: AVAudioRecorderDelegate {
    public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            endRecording()
            self.recorderDidFinish?(recorder, recorder.url, false)
        } else {
            self.recorderDidFinish?(recorder, recorder.url, true)
        }
    }

    public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            self.recorderOccurError?(recorder, error)
        }
    }
    
}
