import Foundation
import AVFoundation
import Combine

protocol RealtimeServiceDelegate: AnyObject {
    func realtimeServiceDidConnect()
    func realtimeServiceDidDisconnect()
    func realtimeServiceDidReceiveTranscript(_ text: String)
    func realtimeServiceDidReceiveAudioLevel(_ level: Float)
    func realtimeServiceDidReceiveError(_ message: String)
    func realtimeServiceStateChanged(_ state: String)
}

class RealtimeService: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    static let shared = RealtimeService()
    
    weak var delegate: RealtimeServiceDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var recordingEngine: AVAudioEngine?
    private var playbackEngine: AVAudioEngine?
    private var playerNode = AVAudioPlayerNode()
    private var playFormat: AVAudioFormat?
    
    // Configuration
    private var currentVoice: String = "alloy"
    private var currentInstructions: String = "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
    private var currentModalities: [String] = ["audio", "text"]
    
    private var isConnected = false
    @Published private(set) var currentState = "Disconnected" {
        didSet {
            delegate?.realtimeServiceStateChanged(currentState)
        }
    }
    
    private override init() {
        super.init()
        setupAudioPlayback()
    }
    
    private func setupAudioPlayback() {
        playbackEngine = AVAudioEngine()
        playFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24000.0, channels: 1, interleaved: false)
        
        guard let playbackEngine = playbackEngine, let playFormat = playFormat else { return }
        
        playbackEngine.attach(playerNode)
        playbackEngine.connect(playerNode, to: playbackEngine.mainMixerNode, format: playFormat)
        
        do {
            try playbackEngine.start()
            playerNode.play()
        } catch {
            print("Failed to start playback engine: \(error)")
        }
    }
    
    private func updateState(_ state: String) {
        if Thread.isMainThread {
            self.currentState = state
        } else {
            DispatchQueue.main.async {
                self.currentState = state
            }
        }
    }

    func connect(
        model: String = "gpt-realtime-2.1",
        voice: String = "alloy",
        instructions: String? = nil,
        modalities: String = "audio,text"
    ) {
        guard let apiKey = KeychainService.shared.load(forKey: "openAIKey"), !apiKey.isEmpty else {
            DispatchQueue.main.async {
                self.delegate?.realtimeServiceDidReceiveError("API Key is missing in Keychain.")
            }
            return
        }
        
        updateState("Connecting...")
        self.currentVoice = voice
        self.currentInstructions = instructions ?? "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
        self.currentModalities = modalities == "text" ? ["text"] : ["audio", "text"]
        
        #if os(iOS)
        DispatchQueue.global(qos: .userInitiated).async {
            let audioSession = AVAudioSession.sharedInstance()
            do {
                try audioSession.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
                try audioSession.setActive(true)
            } catch {
                print("Failed to configure audio session: \(error)")
            }
        }
        #endif
        
        let urlString = "wss://api.openai.com/v1/realtime?model=\(model)"
        var request = URLRequest(url: URL(string: urlString)!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let delegateQueue = OperationQueue()
        delegateQueue.maxConcurrentOperationCount = 1
        delegateQueue.qualityOfService = .userInitiated
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: delegateQueue)
        self.session = session
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
    }
    
    func disconnect() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [weak self] in
                self?.disconnect()
            }
            return
        }
        
        guard isConnected else { return }
        isConnected = false
        
        stopMicrophoneCapture()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        session?.invalidateAndCancel()
        session = nil
        updateState("Disconnected")
        self.delegate?.realtimeServiceDidDisconnect()
        
        #if os(iOS)
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                print("Failed to deactivate audio session: \(error)")
            }
        }
        #endif
    }
    
    private func sendSessionUpdate() {
        var sessionDict: [String: Any] = [
            "type": "realtime", // Restore type which is required
            "instructions": currentInstructions
        ]
        
        if currentVoice != "" {
            sessionDict["audio"] = [
                "output": [
                    "voice": currentVoice
                ]
            ]
        }
        
        let update: [String: Any] = [
            "type": "session.update",
            "session": sessionDict
        ]
        
        send(update)
    }
    
    private func send(_ event: [String: Any]) {
        guard isConnected else { return }
        
        // Skip logging raw audio stream uploads entirely to keep the console clean
        if event["type"] as? String != "input_audio_buffer.append" {
            if let logData = try? JSONSerialization.data(withJSONObject: event, options: []),
               let logString = String(data: logData, encoding: .utf8) {
                AppLogger.log("Realtime Outgoing: \(logString)", category: .openAI, level: .debug)
            }
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: event, options: []),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(jsonString)) { [weak self] error in
            if let error = error {
                print("Failed to send WebSocket message: \(error)")
                self?.disconnect()
            }
        }
    }
    
    private func startListening() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handleIncomingMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        self.handleIncomingMessage(text)
                    }
                @unknown default:
                    break
                }
                if self.isConnected {
                    self.startListening()
                }
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.realtimeServiceDidReceiveError(error.localizedDescription)
                    self?.disconnect()
                }
            }
        }
    }
    
    private func handleIncomingMessage(_ text: String) {
        // Do not log delta events as they spam the console too much, log everything else
        if !text.contains(".delta") {
            AppLogger.log("Realtime Incoming: \(text)", category: .openAI, level: .debug)
        }
        
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        switch type {
        case "session.created":
            print("Realtime Session Created")
        case "input_audio_buffer.speech_started":
            // User barge-in!
            updateState("Listening...")
            DispatchQueue.main.async {
                self.playerNode.stop()
                self.playerNode.play()
            }
        case "response.audio.delta", "response.output_audio.delta":
            updateState("Speaking...")
            if let deltaBase64 = json["delta"] as? String,
               let audioData = Data(base64Encoded: deltaBase64) {
                playAudioChunk(audioData)
            }
        case "response.audio_transcript.delta", "response.output_audio_transcript.delta":
            if let textDelta = json["delta"] as? String {
                DispatchQueue.main.async {
                    self.delegate?.realtimeServiceDidReceiveTranscript(textDelta)
                }
            }
        case "error":
            if let errorObj = json["error"] as? [String: Any],
               let message = errorObj["message"] as? String {
                AppLogger.log("Realtime API Error: \(message)", category: .openAI, level: .error)
                DispatchQueue.main.async {
                    self.delegate?.realtimeServiceDidReceiveError(message)
                }
            }
        default:
            break
        }
    }
    
    private func playAudioChunk(_ data: Data) {
        let frameCount = UInt32(data.count / 2)
        guard let playFormat = playFormat,
              let buffer = AVAudioPCMBuffer(pcmFormat: playFormat, frameCapacity: frameCount) else { return }
        
        buffer.frameLength = frameCount
        data.withUnsafeBytes { rawBufferPointer in
            if let baseAddress = rawBufferPointer.baseAddress,
               let destAddress = buffer.int16ChannelData?[0] {
                destAddress.initialize(from: baseAddress.assumingMemoryBound(to: Int16.self), count: Int(frameCount))
            }
        }
        
        playerNode.scheduleBuffer(buffer)
    }
    
    private func startMicrophoneCapture() {
        recordingEngine = AVAudioEngine()
        guard let recordingEngine = recordingEngine else { return }
        
        let inputNode = recordingEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000.0,
            channels: 1,
            interleaved: false
        )!
        
        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            print("Failed to create audio converter")
            DispatchQueue.main.async {
                self.delegate?.realtimeServiceDidReceiveError("Failed to create audio converter (unsupported format).")
            }
            return
        }
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, time in
            guard let self = self else { return }
            
            let inputCallback: AVAudioConverterInputBlock = { inNumPackages, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            
            let converterBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: 4800)!
            var error: NSError?
            let status = converter.convert(to: converterBuffer, error: &error, withInputFrom: inputCallback)
            
            if status == .haveData, let channelData = converterBuffer.int16ChannelData {
                let channelDataPointer = channelData.pointee
                let byteCount = Int(converterBuffer.frameLength) * 2
                let data = Data(bytes: channelDataPointer, count: byteCount)
                
                // Calculate power level for waveform visualization
                var sum: Float = 0
                let samples = channelDataPointer
                let sampleCount = Int(converterBuffer.frameLength)
                for i in 0..<sampleCount {
                    let sampleVal = Float(samples[i]) / 32768.0
                    sum += sampleVal * sampleVal
                }
                let rms = sqrt(sum / Float(sampleCount))
                let level = rms > 0 ? 20 * log10(rms) : -160.0
                let normalizedLevel = max(0.0, min(1.0, (level + 80.0) / 80.0))
                
                DispatchQueue.main.async {
                    self.delegate?.realtimeServiceDidReceiveAudioLevel(normalizedLevel)
                }
                
                let base64Audio = data.base64EncodedString()
                let event: [String: Any] = [
                    "type": "input_audio_buffer.append",
                    "audio": base64Audio
                ]
                self.send(event)
            }
        }
        
        do {
            try recordingEngine.start()
            updateState("Listening...")
        } catch {
            print("Failed to start recording engine: \(error)")
            DispatchQueue.main.async {
                self.delegate?.realtimeServiceDidReceiveError("Failed to access microphone: \(error.localizedDescription)")
            }
        }
    }
    
    private func stopMicrophoneCapture() {
        guard let engine = recordingEngine else { return }
        recordingEngine = nil
        
        if engine.isRunning {
            engine.inputNode.removeTap(onBus: 0)
            engine.stop()
        }
    }
}

extension RealtimeService {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("WebSocket did connect")
        isConnected = true
        
        // Start WebSocket I/O immediately on the delegate queue (not main)
        startListening()
        sendSessionUpdate()
        
        // UI updates and mic capture go to main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.updateState("Connected")
            self.delegate?.realtimeServiceDidConnect()
            self.startMicrophoneCapture()
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "unknown"
        print("WebSocket did disconnect (code: \(closeCode.rawValue), reason: \(reasonString))")
        disconnect()
    }
}
