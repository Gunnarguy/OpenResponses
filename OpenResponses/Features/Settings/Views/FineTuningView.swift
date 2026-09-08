import SwiftUI
import UniformTypeIdentifiers

struct FineTuningView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @State private var jobs: [FineTuningJob] = []
    @State private var isLoading = false
    @State private var selectedBaseModel = "gpt-4.1-mini-2025-04-14"
    @State private var statusMessage: String? = nil
    @State private var errorMessage: String? = nil
    
    @AppStorage("ft_n_epochs") private var nEpochs: String = "auto"
    @AppStorage("ft_batch_size") private var batchSize: String = "auto"
    @AppStorage("ft_learning_rate") private var learningRateMultiplier: String = "auto"
    
    private let availableBaseModels = ["gpt-4.1-mini-2025-04-14", "gpt-4.1-nano-2025-04-14", "gpt-4.1-2025-04-14"]
    @State private var dataset: FineTuningDataset?
    @State private var datasetFilename: String?
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportDocument: JSONLDocument?
    @State private var isSubmitting = false
    
    var body: some View {
        List {
            Section("Fine-tuning availability") {
                Text("OpenAI is winding down fine-tuning. New accounts cannot access it; existing fine-tuning users may still create jobs while their account remains eligible.")
                    .font(.callout)
                Link("Current availability and requirements", destination: URL(string: "https://developers.openai.com/api/docs/guides/supervised-fine-tuning")!)
            }
            Section("Prepare Training Data") {
                Button("Import Reviewed JSONL") { showingImporter = true }
                    .disabled(isSubmitting)
                if let dataset {
                    Text("\(dataset.exampleCount) validated examples · \(datasetFilename ?? "Training data")")
                        .font(.caption)
                }
                Text("Import at least 10 text-only examples, one conversation per line. Review the answers before training. A single chat is only one example.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Export Current Chat as Draft") { exportChatDraft() }
                    .disabled(viewModel.messages.isEmpty || isSubmitting)
            }
            Section("Launch Training Job") {
                Picker("Base Model", selection: $selectedBaseModel) {
                    ForEach(availableBaseModels, id: \.self) { model in Text(model).tag(model) }
                }
                .pickerStyle(.menu)
                Button {
                    exportAndStartFineTuning()
                } label: {
                    Label(isSubmitting ? "Submitting…" : "Upload & Start Training", systemImage: "cpu.fill")
                }
                .disabled(dataset == nil || isSubmitting)
                Text("Uploads the selected dataset and starts a billable job using your existing account access.")
                    .font(.caption).foregroundStyle(.secondary)
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
                    Text("No training jobs found for this account.")
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
        .onAppear { loadJobs() }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.plainText, .json, .data]) { result in
            do {
                let url = try result.get()
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 50 * 1024 * 1024 else { throw OpenAIServiceError.invalidRequest("Choose a file smaller than 50 MB.") }
                dataset = try FineTuningDataset.validate(Data(contentsOf: url))
                datasetFilename = url.lastPathComponent
            } catch {
                dataset = nil
                datasetFilename = nil
                errorMessage = error.localizedDescription
            }
        }
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .plainText, defaultFilename: "chat-training-draft.jsonl") { result in
            if case .failure(let error) = result { errorMessage = error.localizedDescription }
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
    
    private func exportChatDraft() {
        do {
            // App status/error messages are not training instructions.
            let messages = viewModel.messages.compactMap { message -> FineTuningMessage? in
                guard message.role != .system, let text = message.text, !text.isEmpty else { return nil }
                return FineTuningMessage(role: message.role == .user ? "user" : "assistant", content: text)
            }
            let data = try FineTuningService.shared.compileFineTuningJSONL(conversations: [.init(messages: messages)])
            exportDocument = JSONLDocument(data: data)
            showingExporter = true
        } catch { errorMessage = error.localizedDescription }
    }

    private func exportAndStartFineTuning() {
        guard let dataset, !isSubmitting else { return }
        isSubmitting = true
        let model = selectedBaseModel
        let epochs = nEpochs
        let size = batchSize
        let rate = learningRateMultiplier
        Task {
            defer { isSubmitting = false }
            do {
                _ = try FineTuningDataset.validate(dataset.data)
                try FineTuningService.validateHyperparameters(nEpochs: epochs, batchSize: size, learningRateMultiplier: rate)
                let file = try await OpenAIService().uploadFile(fileData: dataset.data, filename: "fine_tuning_input.jsonl", purpose: "fine-tune")
                let job = try await FineTuningService.shared.createFineTuningJob(
                    trainingFileId: file.id, model: model, nEpochs: epochs,
                    batchSize: size, learningRateMultiplier: rate)
                jobs.insert(job, at: 0)
                statusMessage = "Training job \(job.id) submitted with \(dataset.exampleCount) examples. Status: \(job.status)."
            } catch { errorMessage = "Could not start training: \(error.localizedDescription)" }
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
