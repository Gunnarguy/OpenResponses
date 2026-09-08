import Foundation
import AVFoundation
import Combine

protocol RealtimeServiceDelegate: AnyObject {
    func realtimeServiceDidConnect()
    func realtimeServiceDidDisconnect()
    func realtimeServiceDidReceiveTranscript(_ text: String)
    func realtimeServiceDidCompleteUserMessage(_ text: String)
    func realtimeServiceDidCompleteAssistantMessage(_ text: String)
    func realtimeServiceDidReceiveAudioLevel(_ level: Float)
    func realtimeServiceDidReceiveError(_ message: String)
    func realtimeServiceStateChanged(_ state: String)
}

/// Socket events, playback accounting, mute and microphone uploads share one owner.
@MainActor
final class RealtimeService: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    static let shared = RealtimeService()
    weak var delegate: RealtimeServiceDelegate?

    private var webSocketTask: URLSessionWebSocketTask?
    private var session: URLSession?
    private var connectionGeneration = UUID()
    private var recordingEngine: AVAudioEngine?
    private var playbackEngine: AVAudioEngine?
    private var playerNode = AVAudioPlayerNode()
    private var playFormat: AVAudioFormat?
    private var audioAccumulator = Data()
    private var playback = RealtimePlaybackState()
    private var meterTimer: Timer?
    private var inputLevel: Float = 0
    private var lastInputAt: TimeInterval = 0
    private var publishedLevel: Float = 0
    private var responseActive = false
    private var interruptedResponseID: String?
    private var activeResponseID: String?
    private var audioReady = false
    private var hasInputTap = false
    private var currentBargeIn = false
    private var audioInterrupted = false
    private var isRestoringAudio = false
    private var interruptionObserver: NSObjectProtocol?
    private var configurationObservers: [NSObjectProtocol] = []
    private var restartAudioTask: Task<Void, Never>?

    private var currentVoice = "alloy"
    private var currentInstructions = "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
    private var textOnly = false
    private var isConnected = false
    @Published private(set) var isMicrophoneMuted = false
    @Published private(set) var currentState = "Disconnected" {
        didSet {
            guard currentState != oldValue else { return }
            delegate?.realtimeServiceStateChanged(currentState)
            AppLogger.log("Voice state: \(currentState)", category: .openAI, level: .debug)
        }
    }

    override init() { super.init() }

    nonisolated static let supportedVoices = ["marin", "cedar", "alloy", "ash", "ballad", "coral", "echo", "sage", "shimmer", "verse"]

    nonisolated static func sessionConfiguration(voice: String, instructions: String, textOnly: Bool, bargeIn: Bool = false) -> [String: Any] {
        [
            "type": "realtime", "instructions": instructions,
            "output_modalities": textOnly ? ["text"] : ["audio"],
            "audio": [
                "input": ["format": ["type": "audio/pcm", "rate": 24000],
                          "transcription": ["model": CurrentModelCatalog.transcriptionModel],
                          "turn_detection": ["type": "server_vad", "threshold": 0.5, "prefix_padding_ms": 300,
                                             "silence_duration_ms": 500, "create_response": true, "interrupt_response": bargeIn]],
                "output": ["format": ["type": "audio/pcm", "rate": 24000],
                           "voice": supportedVoices.contains(voice) ? voice : "marin"]
            ]
        ]
    }

    func connect(model: String = "gpt-realtime-2.1", voice: String = "alloy", instructions: String? = nil, modalities: String = "audio,text") {
        guard webSocketTask == nil, currentState != "Connecting..." else { return }
        guard let key = KeychainService.shared.load(forKey: "openAIKey"), !key.isEmpty else {
            reportError("API Key is missing in Keychain."); return
        }
        guard var url = URLComponents(string: "wss://api.openai.com/v1/realtime") else { return }
        url.queryItems = [URLQueryItem(name: "model", value: model)]
        guard let endpoint = url.url else { return }
        connectionGeneration = UUID()
        let generation = connectionGeneration
        currentState = "Connecting..."
        currentVoice = voice
        if let instructions { currentInstructions = instructions }
        textOnly = modalities == "text"
        currentBargeIn = UserDefaults.standard.bool(forKey: "realtime_barge_in")
        isMicrophoneMuted = false
        audioInterrupted = false
        audioAccumulator.removeAll()
        playback.reset()
        responseActive = false
        interruptedResponseID = nil
        activeResponseID = nil

        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self, self.connectionGeneration == generation else { return }
                guard granted else { self.reportError("Microphone access is disabled. Enable it in iOS Settings for OpenResponses."); return }
                do {
                    let audio = AVAudioSession.sharedInstance()
                    try audio.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker, .allowBluetoothHFP])
                    try audio.setActive(true)
                    var request = URLRequest(url: endpoint)
                    request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                    let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
                    self.session = session
                    let socket = session.webSocketTask(with: request)
                    self.webSocketTask = socket
                    socket.resume()
                } catch { self.reportError("Could not start voice audio: \(error.localizedDescription)"); self.disconnect() }
            }
        }
    }

    func setMicrophoneMuted(_ muted: Bool) {
        isMicrophoneMuted = muted
        audioAccumulator.removeAll()
        inputLevel = 0
        if muted { send(["type": "input_audio_buffer.clear"]) }
        refreshAudioState()
    }

    func setBargeInEnabled(_ enabled: Bool) {
        currentBargeIn = enabled
        let configuration = Self.sessionConfiguration(voice: currentVoice, instructions: currentInstructions, textOnly: textOnly, bargeIn: enabled)
        guard let audio = configuration["audio"] as? [String: Any], let input = audio["input"] as? [String: Any], let detection = input["turn_detection"] else { return }
        send(["type": "session.update", "session": ["type": "realtime", "audio": ["input": ["turn_detection": detection]]]])
    }

    func disconnect() {
        connectionGeneration = UUID() // Also cancels a pending microphone permission/connect callback.
        let wasActive = isConnected || webSocketTask != nil || currentState == "Connecting..."
        isConnected = false
        audioReady = false
        isRestoringAudio = false
        restartAudioTask?.cancel(); restartAudioTask = nil
        meterTimer?.invalidate(); meterTimer = nil
        if let interruptionObserver { NotificationCenter.default.removeObserver(interruptionObserver) }
        interruptionObserver = nil
        stopAudioEngines()
        playback.reset()
        responseActive = false
        isMicrophoneMuted = false
        audioAccumulator.removeAll()
        inputLevel = 0
        publishLevel(0)
        let socket = webSocketTask
        webSocketTask = nil
        socket?.cancel(with: .normalClosure, reason: nil)
        session?.invalidateAndCancel(); session = nil
        currentState = "Disconnected"
        if wasActive { delegate?.realtimeServiceDidDisconnect() }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func send(_ event: [String: Any]) {
        guard isConnected, let socket = webSocketTask,
              let data = try? JSONSerialization.data(withJSONObject: event) else { return }
        socket.send(.string(String(decoding: data, as: UTF8.self))) { [weak self] error in
            guard let error else { return }
            Task { @MainActor in
                guard let self, self.webSocketTask === socket else { return }
                self.reportError(error.localizedDescription); self.disconnect()
            }
        }
    }

    private func startListening(_ socket: URLSessionWebSocketTask) {
        socket.receive { [weak self] result in
            Task { @MainActor in
                guard let self, self.webSocketTask === socket, self.isConnected else { return }
                switch result {
                case .success(let message):
                    let data: Data
                    switch message {
                    case .string(let value): data = Data(value.utf8)
                    case .data(let value): data = value
                    @unknown default: self.startListening(socket); return
                    }
                    if let event = try? JSONSerialization.jsonObject(with: data) as? [String: Any] { self.handleEvent(event) }
                    if self.webSocketTask === socket { self.startListening(socket) }
                case .failure(let error): self.reportError(error.localizedDescription); self.disconnect()
                }
            }
        }
    }

    private func handleEvent(_ event: [String: Any]) {
        let type = event["type"] as? String ?? ""
        if !type.hasSuffix(".delta") { AppLogger.log("Voice event: \(type)", category: .openAI, level: .debug) }
        switch type {
        case "session.updated":
            guard !audioReady else { return }
            do {
                try startAudioEngines()
                audioReady = true
                observeAudioInterruptions()
                meterTimer = Timer(timeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
                    Task { @MainActor in self?.refreshAudioState() }
                }
                if let meterTimer { RunLoop.main.add(meterTimer, forMode: .common) }
                delegate?.realtimeServiceDidConnect()
            } catch { reportError("Could not start microphone/playback: \(error.localizedDescription)"); disconnect() }
        case "input_audio_buffer.speech_started":
            if !playback.buffers.isEmpty {
                if let truncation = playback.truncation(now: ProcessInfo.processInfo.systemUptime) { send(truncation) }
                interruptedResponseID = activeResponseID
                responseActive = false
                stopPlayback()
            }
        case "input_audio_buffer.speech_stopped":
            responseActive = true
        case "response.created":
            activeResponseID = (event["response"] as? [String: Any])?["id"] as? String
            responseActive = true
        case "response.audio.delta", "response.output_audio.delta":
            guard event["response_id"] as? String != interruptedResponseID || interruptedResponseID == nil,
                  let encoded = event["delta"] as? String, let data = Data(base64Encoded: encoded) else { return }
            playAudioChunk(data, itemID: event["item_id"] as? String, contentIndex: event["content_index"] as? Int ?? 0)
        case "response.audio_transcript.delta", "response.output_audio_transcript.delta", "response.output_text.delta", "response.text.delta":
            if let text = event["delta"] as? String { delegate?.realtimeServiceDidReceiveTranscript(text) }
        case "conversation.item.input_audio_transcription.completed":
            if let text = event["transcript"] as? String { delegate?.realtimeServiceDidCompleteUserMessage(text) }
        case "response.audio_transcript.done", "response.output_audio_transcript.done":
            if let text = event["transcript"] as? String { delegate?.realtimeServiceDidCompleteAssistantMessage(text) }
        case "response.output_text.done", "response.text.done":
            if let text = event["text"] as? String { delegate?.realtimeServiceDidCompleteAssistantMessage(text) }
        case "response.done":
            let response = event["response"] as? [String: Any] ?? [:]
            if response["id"] as? String == activeResponseID { responseActive = false }
            if response["status"] as? String == "failed" {
                let details = response["status_details"] as? [String: Any] ?? [:]
                let error = details["error"] as? [String: Any] ?? [:]
                reportError(error["message"] as? String ?? "The voice response failed. You can try speaking again.")
            }
        case "error":
            let error = event["error"] as? [String: Any] ?? [:]
            reportError(error["message"] as? String ?? "The voice request failed.")
            responseActive = false
            if !audioReady { disconnect() }
        default: break
        }
        refreshAudioState()
    }

    private func startAudioEngines() throws {
        stopAudioEngines()
        let output = AVAudioEngine()
        let player = AVAudioPlayerNode()
        guard let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: false) else { throw OpenAIServiceError.invalidResponseData }
        output.attach(player)
        output.connect(player, to: output.mainMixerNode, format: format)
        playerNode = player
        playbackEngine = output
        playFormat = format
        let inputEngine = AVAudioEngine()
        recordingEngine = inputEngine
        let input = inputEngine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard let encoder = RealtimePCMEncoder(inputFormat: inputFormat) else { throw OpenAIServiceError.invalidRequest("Unsupported microphone format.") }
        let generation = connectionGeneration
        input.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            do {
                let data = try encoder.encode(buffer)
                let level = RealtimePCMEncoder.level(data)
                Task { @MainActor in
                    guard let self, self.connectionGeneration == generation, self.recordingEngine === inputEngine else { return }
                    self.acceptMicrophoneAudio(data, level: level)
                }
            } catch {
                Task { @MainActor in
                    guard let self, self.connectionGeneration == generation else { return }
                    self.reportError("Microphone conversion failed: \(error.localizedDescription)"); self.disconnect()
                }
            }
        }
        hasInputTap = true
        inputEngine.prepare()
        try inputEngine.start()
        output.prepare()
        try output.start()
        player.play()
        for engine in [inputEngine, output] {
            configurationObservers.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    guard let self, self.audioReady, !self.audioInterrupted,
                          self.recordingEngine === engine || self.playbackEngine === engine else { return }
                    self.scheduleAudioRestart()
                }
            })
        }
    }

    private func acceptMicrophoneAudio(_ data: Data, level: Float) {
        guard audioReady, isConnected, !audioInterrupted, !isRestoringAudio else { return }
        let now = ProcessInfo.processInfo.systemUptime
        lastInputAt = now
        inputLevel = isMicrophoneMuted ? 0 : level
        // Always meter capture. Only actual buffered speaker audio may suppress upload.
        guard !isMicrophoneMuted, currentBargeIn || !playback.suppressesMicrophone(now: now) else {
            audioAccumulator.removeAll(); return
        }
        audioAccumulator.append(data)
        while audioAccumulator.count >= 4_800 {
            let chunk = audioAccumulator.prefix(4_800)
            send(["type": "input_audio_buffer.append", "audio": chunk.base64EncodedString()])
            audioAccumulator.removeFirst(4_800)
        }
    }

    private func playAudioChunk(_ data: Data, itemID: String?, contentIndex: Int) {
        guard audioReady, !audioInterrupted, !isRestoringAudio, data.count >= 2, let format = playFormat,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(data.count / 2)) else { return }
        buffer.frameLength = buffer.frameCapacity
        data.withUnsafeBytes { bytes in
            if let source = bytes.baseAddress, let destination = buffer.int16ChannelData?[0] { memcpy(destination, source, Int(buffer.frameLength) * 2) }
        }
        if playbackEngine?.isRunning != true { scheduleAudioRestart(); return }
        if !playerNode.isPlaying { playerNode.play() }
        let now = ProcessInfo.processInfo.systemUptime
        let audio = AVAudioSession.sharedInstance()
        let token = playback.enqueue(frames: Int(buffer.frameLength), level: RealtimePCMEncoder.level(data), itemID: itemID,
                                     contentIndex: contentIndex, now: now, latency: audio.outputLatency + audio.ioBufferDuration)
        // Increment tracking before scheduling; all completions return to this same actor.
        playerNode.scheduleBuffer(buffer, completionCallbackType: .dataPlayedBack) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.playback.complete(token, now: ProcessInfo.processInfo.systemUptime)
                self.refreshAudioState()
            }
        }
    }

    private func refreshAudioState() {
        guard isConnected, audioReady else { return }
        if audioInterrupted { currentState = "Audio interrupted"; publishLevel(0); return }
        if isRestoringAudio { currentState = "Restoring audio..."; publishLevel(0); return }
        let now = ProcessInfo.processInfo.systemUptime
        if playback.recoverExpiredPlayback(now: now) {
            playerNode.stop(); playerNode.play()
            AppLogger.log("Voice playback completion recovered after audio duration elapsed", category: .openAI, level: .warning)
        }
        if !playback.buffers.isEmpty {
            currentState = "Speaking..."
            publishLevel(playback.level(now: now))
        } else {
            currentState = isMicrophoneMuted ? "Muted" : responseActive ? "Thinking..." : "Listening..."
            publishLevel(isMicrophoneMuted || now - lastInputAt > 0.2 ? 0 : inputLevel)
        }
    }

    private func publishLevel(_ level: Float) {
        guard abs(level - publishedLevel) > 0.005 || (level == 0 && publishedLevel != 0) else { return }
        publishedLevel = level
        delegate?.realtimeServiceDidReceiveAudioLevel(level)
    }

    private func stopPlayback() {
        playback.reset() // Invalidates callbacks for audio stopped by barge-in, route changes or disconnect.
        playerNode.stop()
        if playbackEngine?.isRunning == true { playerNode.play() }
        publishLevel(0)
    }

    private func stopAudioEngines() {
        for observer in configurationObservers { NotificationCenter.default.removeObserver(observer) }
        configurationObservers = []
        if let engine = recordingEngine {
            if hasInputTap { engine.inputNode.removeTap(onBus: 0) }
            engine.stop()
        }
        hasInputTap = false
        recordingEngine = nil
        stopPlayback()
        playbackEngine?.stop(); playbackEngine = nil
    }

    private func observeAudioInterruptions() {
        interruptionObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] notification in
            let type = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let options = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            Task { @MainActor in
                guard let self, self.isConnected else { return }
                if type == AVAudioSession.InterruptionType.began.rawValue {
                    self.audioInterrupted = true
                    self.stopAudioEngines()
                    self.audioAccumulator.removeAll()
                    self.refreshAudioState()
                } else if AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume) {
                    self.audioInterrupted = false
                    self.scheduleAudioRestart()
                } else { self.disconnect() }
            }
        }
    }

    private func scheduleAudioRestart() {
        guard !audioInterrupted, isConnected, restartAudioTask == nil else { return }
        isRestoringAudio = true
        let generation = connectionGeneration
        currentState = "Restoring audio..."
        restartAudioTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 250_000_000)
                guard let self, self.connectionGeneration == generation else { return }
                try AVAudioSession.sharedInstance().setActive(true)
                try self.startAudioEngines()
                self.audioAccumulator.removeAll()
                self.send(["type": "input_audio_buffer.clear"])
                self.restartAudioTask = nil
                self.isRestoringAudio = false
                self.refreshAudioState()
            } catch is CancellationError {} catch {
                self?.reportError("Audio could not resume: \(error.localizedDescription)"); self?.disconnect()
            }
        }
    }

    private func reportError(_ message: String) {
        if !isConnected { currentState = "Error" }
        delegate?.realtimeServiceDidReceiveError(message)
        AppLogger.log("Voice error: \(message)", category: .openAI, level: .error)
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask socket: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            guard webSocketTask === socket else { return }
            isConnected = true
            startListening(socket)
            let configuration = Self.sessionConfiguration(voice: currentVoice, instructions: currentInstructions, textOnly: textOnly,
                                                          bargeIn: currentBargeIn)
            send(["type": "session.update", "session": configuration])
        }
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask socket: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            guard webSocketTask === socket else { return }
            disconnect()
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        Task { @MainActor in
            guard task === webSocketTask else { return }
            reportError(error.localizedDescription); disconnect()
        }
    }
}
