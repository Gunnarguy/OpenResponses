import AVFoundation

/// Feeds each microphone buffer to the sample-rate converter exactly once.
/// Repeatedly returning the same input invents extra speech and prevents reliable VAD turn endings.
final class RealtimePCMEncoder {
    private let converter: AVAudioConverter
    private let outputFormat: AVAudioFormat

    init?(inputFormat: AVAudioFormat) {
        guard inputFormat.sampleRate > 0, inputFormat.channelCount > 0,
              let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 24_000, channels: 1, interleaved: false),
              let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else { return nil }
        self.converter = converter
        self.outputFormat = outputFormat
        converter.primeMethod = .none
    }

    func encode(_ input: AVAudioPCMBuffer) throws -> Data {
        let capacity = AVAudioFrameCount(ceil(Double(input.frameLength) * 24_000 / input.format.sampleRate)) + 32
        guard let output = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: capacity) else { return Data() }
        var supplied = false
        var error: NSError?
        let status = converter.convert(to: output, error: &error) { _, state in
            guard !supplied else { state.pointee = .noDataNow; return nil }
            supplied = true
            state.pointee = .haveData
            return input
        }
        if let error { throw error }
        guard status != .error, output.frameLength > 0, let samples = output.int16ChannelData?[0] else { return Data() }
        return Data(bytes: samples, count: Int(output.frameLength) * 2)
    }

    static func level(_ data: Data) -> Float {
        guard data.count >= 2 else { return 0 }
        let energy: Float = data.withUnsafeBytes { bytes in
            var sum: Float = 0
            for offset in stride(from: 0, to: bytes.count - 1, by: 2) {
                let value = Float(Int16(littleEndian: bytes.loadUnaligned(fromByteOffset: offset, as: Int16.self))) / 32768
                sum += value * value
            }
            return sum / Float(bytes.count / 2)
        }
        guard energy > 0 else { return 0 }
        return max(0, min(1, (10 * log10(energy) + 55) / 55))
    }
}

/// Playback accounting is independent of server completion and display labels.
/// The duration deadline also releases the microphone if an audio callback is lost.
struct RealtimePlaybackState {
    struct Buffer {
        let id = UUID()
        let generation: UUID
        var startsAt: TimeInterval
        var endsAt: TimeInterval
        let frames: Int
        let level: Float
        let itemID: String?
        let contentIndex: Int
    }
    private(set) var generation = UUID()
    private(set) var buffers: [Buffer] = []
    private var completedFrames: [String: Int] = [:]
    private var echoTailUntil: TimeInterval = 0

    mutating func enqueue(frames: Int, level: Float, itemID: String?, contentIndex: Int, now: TimeInterval, latency: TimeInterval) -> Buffer {
        let start = max(buffers.last?.endsAt ?? now, now + latency)
        let buffer = Buffer(generation: generation, startsAt: start, endsAt: start + Double(frames) / 24_000,
                            frames: frames, level: level, itemID: itemID, contentIndex: contentIndex)
        buffers.append(buffer)
        return buffer
    }

    mutating func complete(_ buffer: Buffer, now: TimeInterval) {
        guard buffer.generation == generation, let index = buffers.firstIndex(where: { $0.id == buffer.id }) else { return }
        buffers.remove(at: index)
        if let itemID = buffer.itemID { completedFrames[itemID, default: 0] += buffer.frames }
        if buffers.isEmpty { echoTailUntil = now + 0.25 }
    }

    /// Returns true only when playback callbacks failed to drain an already elapsed queue.
    mutating func recoverExpiredPlayback(now: TimeInterval) -> Bool {
        guard let last = buffers.last, now > last.endsAt + 0.75 else { return false }
        reset()
        return true
    }

    func suppressesMicrophone(now: TimeInterval) -> Bool { !buffers.isEmpty || now < echoTailUntil }
    func level(now: TimeInterval) -> Float {
        buffers.first { now >= $0.startsAt && now < $0.endsAt }?.level ?? 0
    }

    func truncation(now: TimeInterval) -> [String: Any]? {
        guard let first = buffers.first, let itemID = first.itemID else { return nil }
        let pendingPlayed = buffers.filter { $0.itemID == itemID }.reduce(0) { partial, buffer in
            partial + min(buffer.frames, max(0, Int((now - buffer.startsAt) * 24_000)))
        }
        return ["type": "conversation.item.truncate", "item_id": itemID, "content_index": first.contentIndex,
                "audio_end_ms": (completedFrames[itemID, default: 0] + pendingPlayed) / 24]
    }

    /// Moves every queued buffer later by `interval`, the time the player held them while paused.
    mutating func delay(by interval: TimeInterval) {
        guard interval > 0 else { return }
        for index in buffers.indices {
            buffers[index].startsAt += interval
            buffers[index].endsAt += interval
        }
    }

    mutating func reset() {
        generation = UUID()
        buffers = []
        completedFrames = [:]
        echoTailUntil = 0
    }
}

/// GPT-Live listens while it speaks and sends no speech-started event, so the client decides when the caller
/// has cut in. Sustained microphone speech during assistant playback pauses the player at once. If Live keeps
/// sending audio through the hold window, the speech was a backchannel ("mm-hmm") and playback resumes;
/// otherwise Live has yielded to the caller and the queued audio is discarded, so no tail plays.
struct LiveInterruptionGate {
    enum Action: Equatable { case none, pause, resume, discard }

    /// `RealtimePCMEncoder.level` of caller speech; 0.35 is about -36 dBFS.
    var speechLevel: Float = 0.35
    /// Speech must last this long before the player pauses, so clicks and breaths do not.
    var speechOnset: TimeInterval = 0.18
    /// How long playback stays paused while waiting to see whether Live keeps talking.
    var holdWindow: TimeInterval = 0.6
    /// Seconds of new Live audio per second of hold that mean Live kept talking.
    var continueRatio: Double = 0.5

    private(set) var isHolding = false
    private var speechSince: TimeInterval?
    private var holdStartedAt: TimeInterval = 0
    private var audioDuringHold: TimeInterval = 0

    mutating func microphone(level: Float, at now: TimeInterval, assistantAudible: Bool) -> Action {
        guard !isHolding else { return .none }
        guard assistantAudible, level >= speechLevel else { speechSince = nil; return .none }
        let since = speechSince ?? now
        speechSince = since
        guard now - since >= speechOnset else { return .none }
        isHolding = true
        holdStartedAt = now
        audioDuringHold = 0
        speechSince = nil
        return .pause
    }

    mutating func outputAudio(duration: TimeInterval) {
        if isHolding { audioDuringHold += duration }
    }

    mutating func tick(at now: TimeInterval) -> Action {
        guard isHolding, now - holdStartedAt >= holdWindow else { return .none }
        isHolding = false
        return audioDuringHold >= holdWindow * continueRatio ? .resume : .discard
    }

    mutating func reset() {
        isHolding = false
        speechSince = nil
        audioDuringHold = 0
    }
}
