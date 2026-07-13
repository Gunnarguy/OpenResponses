import SwiftUI

struct VoiceModeSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("realtime_voice") private var voice: String = "alloy"
    @AppStorage("realtime_instructions") private var instructions: String = "You are a helpful assistant speaking in a friendly, conversational voice. Keep responses brief."
    @AppStorage("realtime_modalities") private var modalities: String = "audio,text"
    @AppStorage("realtime_model") private var realtimeModel: String = "gpt-realtime-2.1"
    @AppStorage("realtime_barge_in") private var bargeIn: Bool = false
    
    let voices = ["alloy", "echo", "fable", "onyx", "nova", "shimmer"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Model Selection")) {
                    Picker("Model", selection: $realtimeModel) {
                        Text("gpt-realtime-2.1").tag("gpt-realtime-2.1")
                        Text("gpt-realtime-2.1-mini").tag("gpt-realtime-2.1-mini")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Voice configuration")) {
                    Picker("Voice", selection: $voice) {
                        ForEach(voices, id: \.self) { v in
                            Text(v.capitalized).tag(v)
                        }
                    }
                }
                
                Section(header: Text("Instructions")) {
                    TextEditor(text: $instructions)
                        .frame(minHeight: 100)
                }
                
                Section(header: Text("Advanced Configuration")) {
                    Picker("Modalities", selection: $modalities) {
                        Text("Audio & Text").tag("audio,text")
                        Text("Text Only").tag("text")
                    }
                }
                
                Section(header: Text("Turn Taking")) {
                    Toggle("Voice Barge-In", isOn: $bargeIn)
                    Text("Allow interrupting the assistant by speaking. Recommended only when using headphones to prevent echo feedback loops.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Voice Mode Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    VoiceModeSettingsSheet()
}
