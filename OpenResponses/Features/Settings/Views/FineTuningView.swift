import SwiftUI

struct FineTuningView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var jobs: [FineTuningJob] = []
    @State private var isLoading = false
    @State private var selectedBaseModel = "gpt-4o-mini"
    @State private var statusMessage: String? = nil
    @State private var errorMessage: String? = nil
    
    @AppStorage("ft_n_epochs") private var nEpochs: String = "auto"
    @AppStorage("ft_batch_size") private var batchSize: String = "auto"
    @AppStorage("ft_learning_rate") private var learningRateMultiplier: String = "auto"
    
    private let availableBaseModels = ["gpt-4o-mini", "gpt-4o-2024-08-26", "gpt-3.5-turbo-0125"]
    
    var body: some View {
        List {
            Section("Launch Custom Training Job") {
                Picker("Base Model", selection: $selectedBaseModel) {
                    ForEach(availableBaseModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                
                Button {
                    exportAndStartFineTuning()
                } label: {
                    Label("Export & Train Custom Model", systemImage: "cpu.fill")
                }
                .foregroundColor(.purple)
                .disabled(viewModel.messages.count < 3)
                
                if viewModel.messages.count < 3 {
                    Text("ℹ️ Active conversation needs at least 3 messages (system, user, assistant exchanges) to qualify for training export.")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Converts active chat thread containing \(viewModel.messages.count) messages into a fine-tuning dataset, uploads it, and launches the training job.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Hyperparameters (Optional)") {
                HStack {
                    Text("Epochs")
                    Spacer()
                    TextField("auto or number", text: $nEpochs)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
                HStack {
                    Text("Batch Size")
                    Spacer()
                    TextField("auto or number", text: $batchSize)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
                HStack {
                    Text("Learning Rate Multiplier")
                    Spacer()
                    TextField("auto or float", text: $learningRateMultiplier)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            
            Section("Active & Succeeded Custom Models") {
                if isLoading && jobs.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading training runs...")
                        Spacer()
                    }
                } else if jobs.isEmpty {
                    Text("No custom models have been created yet. Launch one above.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(jobs, id: \.id) { job in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(job.id)
                                    .font(.system(.subheadline, design: .monospaced))
                                    .fontWeight(.bold)
                                Spacer()
                                Text(job.status.uppercased())
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(job.status).opacity(0.15))
                                    .foregroundColor(statusColor(job.status))
                                    .cornerRadius(6)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Base Model: \(job.model)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let customModel = job.fineTunedModel {
                                    Text("Output Model: \(customModel)")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                }
                                Text("Started: \(formatTimestamp(job.createdAt))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 12) {
                                Button {
                                    refreshJob(job.id)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                
                                if ["queued", "running", "validating_files"].contains(job.status) {
                                    Button(role: .destructive) {
                                        cancelJob(job.id)
                                    } label: {
                                        Label("Cancel Job", systemImage: "xmark.circle")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Fine-Tuning Jobs")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    loadJobs()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            loadJobs()
        }
        .alert("Status", isPresented: Binding(
            get: { statusMessage != nil },
            set: { newValue in if !newValue { statusMessage = nil } }
        )) {
            Button("OK") { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { newValue in if !newValue { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    private func loadJobs() {
        isLoading = true
        Task {
            do {
                let fetchedJobs = try await FineTuningService.shared.listFineTuningJobs()
                await MainActor.run {
                    self.jobs = fetchedJobs.sorted(by: { $0.createdAt > $1.createdAt })
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load fine-tuning jobs: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func refreshJob(_ id: String) {
        // Since listing jobs retrieves status for all of them, re-listing is the most clean API approach here.
        loadJobs()
    }
    
    private func cancelJob(_ id: String) {
        Task {
            do {
                _ = try await FineTuningService.shared.cancelFineTuningJob(jobId: id)
                await MainActor.run {
                    self.statusMessage = "Fine-tuning job cancellation requested."
                    loadJobs()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel job: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func exportAndStartFineTuning() {
        isLoading = true
        Task {
            do {
                // Map local messages to dataset messages
                let tuningMessages = viewModel.messages.compactMap { msg -> FineTuningMessage? in
                    guard let text = msg.text, !text.isEmpty else { return nil }
                    let roleStr: String
                    switch msg.role {
                    case .user: roleStr = "user"
                    case .assistant: roleStr = "assistant"
                    case .system: roleStr = "system"
                    }
                    return FineTuningMessage(role: roleStr, content: text)
                }
                
                // Fine-tuning dataset needs at least 1 prompt-response format, wrap inside a single conversation object
                let conversation = FineTuningConversation(messages: tuningMessages)
                
                // Compile to jsonl payload
                let jsonlData = try FineTuningService.shared.compileFineTuningJSONL(conversations: [conversation])
                
                // Upload dataset
                let openaiFile = try await OpenAIService().uploadFile(
                    fileData: jsonlData,
                    filename: "fine_tuning_input.jsonl",
                    purpose: "fine-tune"
                )
                
                // Launch run
                let job = try await FineTuningService.shared.createFineTuningJob(
                    trainingFileId: openaiFile.id,
                    model: selectedBaseModel,
                    nEpochs: nEpochs,
                    batchSize: batchSize,
                    learningRateMultiplier: learningRateMultiplier
                )
                
                await MainActor.run {
                    self.jobs.insert(job, at: 0)
                    self.isLoading = false
                    self.statusMessage = "Successfully exported conversation, uploaded dataset, and scheduled training run \(job.id)!"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to start fine-tuning: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "succeeded": return .green
        case "failed": return .red
        case "running": return .blue
        case "queued", "validating_files": return .orange
        default: return .gray
        }
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return date.formatted(date: .numeric, time: .shortened)
    }
}
