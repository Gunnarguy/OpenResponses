import SwiftUI

struct VoiceModeView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = RealtimeService.shared
    
    @State private var statusText = "Connecting..."
    @State private var transcriptText = ""
    @State private var isMuted = false
    @State private var audioLevel: Float = 0.0
    @State private var delegateWrapper = VoiceModeDelegateWrapper()
    @State private var scale: CGFloat = 1.0
    @State private var animateWaves = false
    @State private var showSettings = false
    
    @AppStorage("realtime_voice") private var voice: String = "alloy"
    @AppStorage("realtime_instructions") private var instructions: String = "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
    @AppStorage("realtime_modalities") private var modalities: String = "audio,text"
    @AppStorage("realtime_model") private var realtimeModel: String = "gpt-realtime-2.1"
    
    // Waveform bar count
    private let barCount = 18
    
    var body: some View {
        ZStack {
            // Stunning dark gradient background with colored accent glows
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.05, blue: 0.08), Color(red: 0.08, green: 0.1, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative background glowing orbs
            GeometryReader { geo in
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .position(x: geo.size.width * 0.25, y: geo.size.height * 0.3)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 350, height: 350)
                        .blur(radius: 90)
                        .position(x: geo.size.width * 0.75, y: geo.size.height * 0.7)
                }
            }
            
            VStack(spacing: 30) {
                // Top header bar
                HStack {
                    Button {
                        disconnectAndClose()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.title3.bold())
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    Spacer()
                    Text("Voice Mode")
                        .font(.headline)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.title3.bold())
                            .foregroundColor(.white.opacity(0.7))
                            .padding(12)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Status Indicator
                VStack(spacing: 8) {
                    Text(statusText.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .tracking(2)
                        .foregroundColor(.blue.opacity(0.8))
                    
                    Text(service.currentState == "Connected" ? (audioLevel > 0.05 ? "Speaking..." : "Listening...") : service.currentState)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                
                Spacer()
                
                // Dynamic Visualizer (animated circular gradient with waveform)
                ZStack {
                    // Outer pulsing ring
                    Circle()
                        .stroke(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom), lineWidth: 2)
                        .frame(width: 180, height: 180)
                        .scaleEffect(scale)
                        .opacity(2.0 - Double(scale))
                        .animation(.easeOut(duration: 1.2).repeatForever(autoreverses: false), value: scale)
                    
                    // Main visualizer circle
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 90
                            )
                        )
                        .frame(width: 160, height: 160)
                    
                    // Waveform lines
                    HStack(spacing: 4) {
                        ForEach(0..<barCount, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .purple, .pink],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: 6,
                                    height: max(6, CGFloat(audioLevel * 180 * Float.random(in: 0.4...1.2)))
                                )
                                .animation(.spring(response: 0.15, dampingFraction: 0.5), value: audioLevel)
                        }
                    }
                }
                .onAppear {
                    scale = 1.6
                }
                
                Spacer()
                
                // Realtime Transcript display
                if !transcriptText.isEmpty {
                    ScrollView {
                        Text(transcriptText)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .transition(.opacity.combined(with: .scale))
                    }
                    .frame(maxHeight: 120)
                } else {
                    Text("Start speaking to begin your conversation...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .frame(height: 120)
                }
                
                Spacer()
                
                // Floating control panel (glassmorphic pill)
                HStack(spacing: 40) {
                    // Mute Microphone
                    Button {
                        isMuted.toggle()
                        // Since we just stop mic sending in a real implementation:
                        if isMuted {
                            service.disconnect()
                            statusText = "Muted"
                        } else {
                            service.connect()
                            statusText = "Listening"
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                                .font(.title2)
                                .foregroundColor(isMuted ? .red : .white)
                                .frame(width: 60, height: 60)
                                .background(isMuted ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                                .clipShape(Circle())
                            Text(isMuted ? "Unmute" : "Mute")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    // Disconnect / End Button
                    Button {
                        disconnectAndClose()
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "phone.down.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .frame(width: 75, height: 75)
                                .background(Color.red)
                                .clipShape(Circle())
                                .shadow(color: .red.opacity(0.4), radius: 10, x: 0, y: 5)
                            Text("End")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Speaker Mode / Info Toggle
                    Button {
                        // Speaker option placeholder
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Circle())
                            Text("Speaker")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            delegateWrapper.onConnect = { statusText = "Connected" }
            delegateWrapper.onDisconnect = { statusText = "Disconnected" }
            delegateWrapper.onTranscript = { transcriptText += $0 }
            delegateWrapper.onAudioLevel = { audioLevel = $0 }
            delegateWrapper.onError = { message in
                statusText = "Error"
                transcriptText = message
            }
            service.delegate = delegateWrapper
            service.connect(
                model: realtimeModel,
                voice: voice,
                instructions: instructions,
                modalities: modalities
            )
            statusText = "Connecting..."
        }
        .onDisappear {
            service.disconnect()
        }
        .sheet(isPresented: $showSettings) {
            VoiceModeSettingsSheet()
        }
    }
    
    private func disconnectAndClose() {
        service.disconnect()
        isPresented = false
    }
}

class VoiceModeDelegateWrapper: RealtimeServiceDelegate {
    var onConnect: (() -> Void)?
    var onDisconnect: (() -> Void)?
    var onTranscript: ((String) -> Void)?
    var onAudioLevel: ((Float) -> Void)?
    var onError: ((String) -> Void)?
    
    func realtimeServiceDidConnect() {
        DispatchQueue.main.async { [weak self] in
            self?.onConnect?()
        }
    }
    func realtimeServiceDidDisconnect() {
        DispatchQueue.main.async { [weak self] in
            self?.onDisconnect?()
        }
    }
    func realtimeServiceDidReceiveTranscript(_ text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onTranscript?(text)
        }
    }
    func realtimeServiceDidReceiveAudioLevel(_ level: Float) {
        DispatchQueue.main.async { [weak self] in
            self?.onAudioLevel?(level)
        }
    }
    func realtimeServiceDidReceiveError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onError?(message)
        }
    }
    func realtimeServiceStateChanged(_ state: String) {}
}

#Preview {
    VoiceModeView(isPresented: .constant(true))
}
