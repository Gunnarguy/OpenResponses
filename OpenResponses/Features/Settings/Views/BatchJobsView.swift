import SwiftUI
import UniformTypeIdentifiers
struct BatchJobsView: View {
    @State private var jobs: [BatchJob] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var statusMessage: String? = nil
    @State private var isFileImporterPresented = false
    
    @AppStorage("batch_endpoint") private var endpoint: String = "/v1/chat/completions"
    
    var body: some View {
        List {
            Section("Submit New Batch Job") {
                HStack {
                    Text("Endpoint")
                    Spacer()
                    TextField("/v1/chat/completions", text: $endpoint)
                        .multilineTextAlignment(.trailing)
                        .autocapitalization(.none)
                }
                
                Button {
                    isFileImporterPresented = true
                } label: {
                    Label("Upload JSONL Batch", systemImage: "square.and.arrow.up.fill")
                }
                .foregroundColor(.blue)
                
                Text("Select a properly formatted JSONL file containing your batch requests. Asynchronous batching takes up to 24 hours to complete but is 50% cheaper.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Active and Historical Batches") {
                if isLoading && jobs.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Loading batch jobs...")
                        Spacer()
                    }
                } else if jobs.isEmpty {
                    Text("No batch jobs found. Use the button above to schedule your first batch execution.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.vertical, 20)
                } else {
                    ForEach(jobs, id: \.id) { job in
                        VStack(alignment: .leading, spacing: 10) {
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
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Created:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(formatTimestamp(job.createdAt))
                                        .font(.caption)
                                }
                                Spacer()
                                if let total = job.requestCounts?.total {
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Requests:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text("\(job.requestCounts?.completed ?? 0) / \(total)")
                                            .font(.caption)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                Button {
                                    refreshJob(job.id)
                                } label: {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                                
                                if job.status == "completed", let outputFileId = job.outputFileId {
                                    Button {
                                        downloadResults(fileId: outputFileId)
                                    } label: {
                                        Label("Get Results", systemImage: "arrow.down.doc.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                }
                                
                                if ["validating", "in_progress"].contains(job.status) {
                                    Button(role: .destructive) {
                                        cancelJob(job.id)
                                    } label: {
                                        Label("Cancel", systemImage: "xmark.circle")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .navigationTitle("Batch Jobs")
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
        .alert("Status Update", isPresented: Binding(
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
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.plainText, .json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    uploadAndSubmitBatch(fileURL: url)
                }
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadJobs() {
        isLoading = true
        Task {
            do {
                let fetchedJobs = try await BatchService.shared.listBatches()
                await MainActor.run {
                    self.jobs = fetchedJobs.sorted(by: { $0.createdAt > $1.createdAt })
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load batch jobs: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func refreshJob(_ id: String) {
        Task {
            do {
                let updated = try await BatchService.shared.retrieveBatch(batchId: id)
                await MainActor.run {
                    if let index = jobs.firstIndex(where: { $0.id == id }) {
                        jobs[index] = updated
                    }
                    self.statusMessage = "Job status refreshed successfully."
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to refresh job: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func cancelJob(_ id: String) {
        Task {
            do {
                let cancelled = try await BatchService.shared.cancelBatch(batchId: id)
                await MainActor.run {
                    if let index = jobs.firstIndex(where: { $0.id == id }) {
                        jobs[index] = cancelled
                    }
                    self.statusMessage = "Batch job cancellation requested."
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to cancel job: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func downloadResults(fileId: String) {
        Task {
            do {
                let results = try await BatchService.shared.downloadBatchResult(fileId: fileId)
                await MainActor.run {
                    self.statusMessage = "Results downloaded successfully:\n\n\(results.prefix(400))..."
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to download results: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func uploadAndSubmitBatch(fileURL: URL) {
        isLoading = true
        Task {
            do {
                guard fileURL.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "BatchJobsView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permission denied accessing file."])
                }
                defer { fileURL.stopAccessingSecurityScopedResource() }
                
                let fileData = try Data(contentsOf: fileURL)
                let filename = fileURL.lastPathComponent
                
                // Upload batch JSONL data
                let openaiFile = try await OpenAIService().uploadFile(
                    fileData: fileData,
                    filename: filename,
                    purpose: "batch"
                )
                
                // Submit batch job
                let job = try await BatchService.shared.submitBatch(inputFileId: openaiFile.id, endpoint: endpoint)
                
                await MainActor.run {
                    self.jobs.insert(job, at: 0)
                    self.isLoading = false
                    self.statusMessage = "Successfully uploaded '\(filename)' and submitted batch \(job.id)!"
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to submit batch: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status {
        case "completed": return .green
        case "failed": return .red
        case "in_progress": return .blue
        case "validating": return .orange
        default: return .gray
        }
    }
    
    private func formatTimestamp(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return date.formatted(date: .numeric, time: .shortened)
    }
}

#Preview {
    NavigationStack {
        BatchJobsView()
    }
}
