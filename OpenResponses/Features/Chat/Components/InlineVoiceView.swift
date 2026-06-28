import SwiftUI

struct InlineVoiceView: View {
    @Binding var isPresented: Bool
    @StateObject private var service = RealtimeService.shared
    
    @State private var statusText = "Connecting..."
    @State private var audioLevel: Float = 0.0
    @State private var isMuted = false
    @State private var transcriptText = ""
    @State private var delegateWrapper = VoiceModeDelegateWrapper()
    @State private var scale: CGFloat = 1.0
    
    @AppStorage("realtime_voice") private var voice: String = "alloy"
    @AppStorage("realtime_instructions") private var instructions: String = "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
    @AppStorage("realtime_modalities") private var modalities: String = "audio,text"
    
    private let barCount = 12
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            // Inline transcript display
            if !transcriptText.isEmpty {
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        Text(transcriptText)
                            .font(.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .id("transcriptBottom")
                    }
                    .frame(maxHeight: 60)
                    .onChange(of: transcriptText) { _, _ in
                        withAnimation {
                            proxy.scrollTo("transcriptBottom", anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack(spacing: 16) {
                // Mute button
                Button(action: {
                    isMuted.toggle()
                    if isMuted {
                        service.disconnect()
                        statusText = "Muted"
                    } else {
                        service.connect(voice: voice, instructions: instructions, modalities: modalities)
                        statusText = "Listening"
                    }
                }) {
                    Image(systemName: isMuted ? "mic.slash.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(isMuted ? .red : .primary)
                        .frame(width: 44, height: 44)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Visualizer and status
                VStack(spacing: 4) {
                    Text(service.currentState == "Connected" ? (audioLevel > 0.05 ? "Speaking..." : "Listening...") : service.currentState)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                    
                    HStack(spacing: 3) {
                        ForEach(0..<barCount, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                                .frame(
                                    width: 4,
                                    height: max(4, CGFloat(audioLevel * 40 * Float.random(in: 0.5...1.5)))
                                )
                                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: audioLevel)
                        }
                    }
                    .frame(height: 40, alignment: .center)
                }
                
                Spacer()
                
                // End Call button
                Button(action: disconnectAndClose) {
                    Image(systemName: "phone.down.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
        .onAppear {
            setupService()
        }
        .onDisappear {
            service.disconnect()
        }
    }
    
    private func setupService() {
        delegateWrapper.onConnect = { statusText = "Connected" }
        delegateWrapper.onDisconnect = { statusText = "Disconnected" }
        delegateWrapper.onTranscript = { transcriptText += $0 }
        delegateWrapper.onAudioLevel = { audioLevel = $0 }
        delegateWrapper.onError = { message in
            statusText = "Error"
            print("Voice error: \(message)")
        }
        service.delegate = delegateWrapper
        service.connect(
            voice: voice,
            instructions: instructions,
            modalities: modalities
        )
        statusText = "Connecting..."
    }
    
    private func disconnectAndClose() {
        service.disconnect()
        withAnimation(.easeOut(duration: 0.2)) {
            isPresented = false
        }
    }
}
