import AVFoundation
import UIKit
import Combine

/// Service for handling audio recording functionality
class AudioRecordingService: NSObject, ObservableObject {
    
    private var audioRecorder: AVAudioRecorder?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    @Published var isRecording = false
    @Published var hasPermission = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var recordingTimer: Timer?
    private var recordingStartTime: Date?
    
    override init() {
        super.init()
        // Don't check permissions during init to avoid deadlocks
        // Let the system handle permission requests naturally when recording starts
    }
    
    /// Check if we can start recording (will trigger system permission request if needed)
    func checkPermissionIfNeeded() {
        // Don't programmatically check permissions to avoid deadlocks
        // The system will automatically prompt for permissions when startRecording() is called
        // We'll update hasPermission based on the actual recording attempt result
    }
    
    /// Start recording audio
    func startRecording() -> Bool {
        guard !isRecording else { return false }
        
        // Check permission using appropriate API based on iOS version
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .denied:
                hasPermission = false
                return false
            case .undetermined:
                // Permission not determined yet - request it
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.hasPermission = granted
                        if granted {
                            // Try recording again after permission is granted
                            _ = self?.startRecording()
                        }
                    }
                }
                return false
            case .granted:
                hasPermission = true
                // Continue with recording below
            @unknown default:
                hasPermission = false
                return false
            }
        } else {
            switch audioSession.recordPermission {
            case .denied:
                hasPermission = false
                return false
            case .undetermined:
                // Permission not determined yet - request it
                audioSession.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async {
                        self?.hasPermission = granted
                        if granted {
                            // Try recording again after permission is granted
                            _ = self?.startRecording()
                        }
                    }
                }
                return false
            case .granted:
                hasPermission = true
                // Continue with recording below
            @unknown default:
                hasPermission = false
                return false
            }
        }
        
        do {
            // Configure audio session
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Create temporary file URL for recording
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("recording_\(UUID().uuidString).m4a")
            
            // Configure recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Create and start recorder
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            let success = audioRecorder?.record() ?? false
            if success {
                isRecording = true
                hasPermission = true // Recording succeeded, so we have permission
                recordingStartTime = Date()
                startTimer()
                
                // Add haptic feedback for recording start
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
            } else {
                hasPermission = false // Recording failed, likely due to permissions
            }
            
            return success
            
        } catch {
            print("Failed to start recording: \(error)")
            hasPermission = false // Recording failed, likely due to permissions
            return false
        }
    }
    
    /// Stop recording and return the audio data
    func stopRecording() -> Data? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        
        // Add haptic feedback for recording stop
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Read the recorded file
        guard let url = audioRecorder?.url else { return nil }
        
        do {
            let audioData = try Data(contentsOf: url)
            
            // Clean up the temporary file
            try FileManager.default.removeItem(at: url)
            
            return audioData
        } catch {
            print("Failed to read recording: \(error)")
            return nil
        }
    }
    
    /// Cancel recording without returning data
    func cancelRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        
        // Clean up the temporary file
        if let url = audioRecorder?.url {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Get current audio level for visual feedback
    func getAudioLevel() -> Float {
        guard let recorder = audioRecorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        return recorder.averagePower(forChannel: 0)
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            DispatchQueue.main.async {
                self.recordingDuration = Date().timeIntervalSince(startTime)
            }
        }
    }
    
    private func stopTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingDuration = 0
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecordingService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording failed")
            isRecording = false
            stopTimer()
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        print("Recording encode error: \(error?.localizedDescription ?? "Unknown")")
        isRecording = false
        stopTimer()
    }
}
