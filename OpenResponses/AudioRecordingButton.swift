import SwiftUI
import Combine

/// Audio recording button with visual feedback and animation
struct AudioRecordingButton: View {
    @StateObject private var audioService = AudioRecordingService()
    let onRecordingComplete: (Data) -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var showPermissionAlert = false
    
    var body: some View {
        Button(action: {
            if audioService.isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        }) {
            ZStack {
                // Pulsing background when recording
                if audioService.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.3))
                        .frame(width: 60, height: 60)
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .animation(
                            Animation.easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: audioService.isRecording
                        )
                }
                
                // Main button
                Circle()
                    .fill(audioService.isRecording ? Color.red : Color.blue)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: audioService.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(audioService.isRecording ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3), value: audioService.isRecording)
            }
        }
        .disabled(!audioService.hasPermission)
        .overlay(
            // Recording duration display
            VStack {
                if audioService.isRecording {
                    Text(formatDuration(audioService.recordingDuration))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .offset(y: -35)
                }
            }
        )
        .accessibilityLabel(audioService.isRecording ? "Stop recording" : "Start voice recording")
        .accessibilityHint(audioService.isRecording ? "Tap to stop recording and send audio" : "Tap and hold to record audio message")
        .alert("Microphone Permission Required", isPresented: $showPermissionAlert) {
            Button("Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone access in Settings to record audio messages.")
        }
        .onChange(of: audioService.hasPermission) { _, hasPermission in
            if !hasPermission && !audioService.isRecording {
                showPermissionAlert = true
            }
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            if audioService.isRecording {
                // Update pulsing animation based on audio level
                let audioLevel = audioService.getAudioLevel()
                let normalizedLevel = CGFloat(max(0, (audioLevel + 40) / 40)) // Normalize from -40dB to 0dB
                scale = 1.0 + (normalizedLevel * 0.3)
                opacity = 0.7 + (normalizedLevel * 0.3)
            }
        }
    }
    
    private func startRecording() {
        guard audioService.hasPermission else {
            showPermissionAlert = true
            return
        }
        
        let success = audioService.startRecording()
        if !success {
            print("Failed to start recording")
        }
    }
    
    private func stopRecording() {
        if let audioData = audioService.stopRecording() {
            onRecordingComplete(audioData)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    AudioRecordingButton { data in
        print("Recorded \(data.count) bytes")
    }
    .padding()
}
