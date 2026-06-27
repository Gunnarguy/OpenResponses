//
//  VoiceRecorderService.swift
//  OpenResponses
//

import Foundation
import AVFoundation
import Combine

class VoiceRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    
    private var timer: Timer?
    private var completionHandler: ((Data?) -> Void)?
    
    // Setup and request permission
    func requestPermission(completion: @escaping (Bool) -> Void) {
        #if os(iOS) || os(macOS)
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
        #else
        completion(false)
        #endif
    }
    
    func startRecording(completion: @escaping (Data?) -> Void) {
        self.completionHandler = completion
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
        #endif
        
        do {
            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent(UUID().uuidString + ".wav")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatLinearPCM),
                AVSampleRateKey: 16000.0, // 16kHz is ideal for OpenAI audio
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            DispatchQueue.main.async {
                self.isRecording = true
                self.recordingDuration = 0
                self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                    self?.recordingDuration = self?.audioRecorder?.currentTime ?? 0
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
            completion(nil)
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        DispatchQueue.main.async {
            self.isRecording = false
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        var audioData: Data? = nil
        if flag {
            audioData = try? Data(contentsOf: recorder.url)
        }
        
        DispatchQueue.main.async {
            self.completionHandler?(audioData)
        }
        
        // Clean up
        try? FileManager.default.removeItem(at: recorder.url)
    }
}
