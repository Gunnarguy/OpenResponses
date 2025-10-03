import SwiftUI
import UniformTypeIdentifiers

/// Smart, context-aware view for uploading files to vector stores
/// Adapts UI based on how many vector stores are currently selected (0, 1, or 2)
struct VectorStoreSmartUploadView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Completion callback
    let onUploadComplete: ((Int, Int) -> Void)? // (successCount, failedCount)
    
    // API Service
    private let api = OpenAIService()
    
    // Vector Store State
    @State private var vectorStores: [VectorStore] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @State private var selectedFiles: [URL] = []
    @State private var targetVectorStore: VectorStore?
    @State private var showingCreateStore = false
    
    // Chunking configuration (advanced)
    @State private var showAdvancedOptions = false
    @State private var useCustomChunking = false
    @State private var chunkSize: Double = 800 // Default
    @State private var chunkOverlap: Double = 400 // Default
    
    // Upload Progress Tracking
    @State private var isUploading = false
    @State private var uploadProgress: [UploadProgress] = []
    @State private var currentFileIndex = 0
    @State private var totalFiles = 0
    
    init(onUploadComplete: ((Int, Int) -> Void)? = nil) {
        self.onUploadComplete = onUploadComplete
    }
    
    private var currentStoreCount: Int {
        viewModel.activePrompt.selectedVectorStoreIds?.split(separator: ",").count ?? 0
    }
    
    private var selectedStoreIds: [String] {
        viewModel.activePrompt.selectedVectorStoreIds?.split(separator: ",").map { String($0) } ?? []
    }
    
    private var selectedStores: [VectorStore] {
        vectorStores.filter { selectedStoreIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading vector stores...")
                } else if isUploading {
                    uploadProgressView
                } else {
                    contentView
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !isUploading {
                            dismiss()
                        }
                    }
                    .disabled(isUploading)
                }
                
                // Add quick create button for when user has 1 or 2 stores (making it easy to add another)
                if currentStoreCount > 0 && currentStoreCount < 2 && !isUploading {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingCreateStore = true
                        } label: {
                            Image(systemName: "plus")
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .task {
            await loadVectorStores()
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.pdf, .plainText, .json, .data, .text, .rtf, .spreadsheet, .presentation, .zip, .commaSeparatedText],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await handleFileSelection(result)
            }
        }
        .sheet(isPresented: $showingCreateStore) {
            CreateVectorStoreSimpleView()
                .environmentObject(viewModel)
        }
    }
    
    private var navigationTitle: String {
        if isUploading {
            return "Uploading Files"
        }
        switch currentStoreCount {
        case 0: return "Add Files to Vector Store"
        case 1: return "Upload to Vector Store"
        case 2: return "Choose Vector Store"
        default: return "Upload Files"
        }
    }
    
    // MARK: - Upload Progress View
    
    private var uploadProgressView: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Overall Progress
                    ProgressView(value: Double(currentFileIndex), total: Double(totalFiles))
                        .progressViewStyle(.linear)
                        .tint(.blue)
                    
                    Text("Uploading \(currentFileIndex) of \(totalFiles) files")
                        .font(.headline)
                    
                    if let targetStore = targetVectorStore {
                        Text("to \(targetStore.name ?? targetStore.id)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section("File Progress") {
                ForEach(uploadProgress) { progress in
                    HStack(spacing: 12) {
                        Image(systemName: progress.status.icon)
                            .foregroundColor(progress.status.color)
                            .font(.title3)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(progress.filename)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Text(progress.status.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            // Show conversion method if file was converted
                            if progress.wasConverted, let method = progress.conversionMethod {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.caption2)
                                    Text("Converted via \(method)")
                                        .font(.caption2)
                                }
                                .foregroundColor(.orange)
                            }
                            
                            if let error = progress.errorMessage {
                                Text(error)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        if progress.status == .converting || progress.status == .uploading || progress.status == .processing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch currentStoreCount {
        case 0:
            noStoresView
        case 1:
            oneStoreView
        case 2:
            twoStoresView
        default:
            noStoresView
        }
    }
    
    // MARK: - No Vector Stores Selected
    
    private var noStoresView: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("No Vector Store Selected")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("To use file search, you need to select at least one vector store. You can create a new one or select from your existing stores.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }
            
            Section("Quick Actions") {
                Button {
                    showingCreateStore = true
                } label: {
                    Label("Create New Vector Store", systemImage: "folder.badge.plus")
                        .foregroundColor(.accentColor)
                }
                
                Button {
                    // Navigate to File Manager to select existing stores
                    dismiss()
                    // TODO: Could programmatically open Settings > File Manager
                } label: {
                    Label("Select Existing Stores", systemImage: "folder.fill")
                        .foregroundColor(.accentColor)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Tip")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("You can select up to 2 vector stores for comprehensive file search across different document collections.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - One Vector Store Selected
    
    private var oneStoreView: some View {
        List {
            Section {
                if let store = selectedStores.first {
                    VectorStoreCard(store: store)
                }
            }
            
            Section("Upload Files") {
                Button {
                    targetVectorStore = selectedStores.first
                    showingFilePicker = true
                } label: {
                    Label("Select Files to Upload", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.accentColor)
                .font(.headline)
            }
            
            Section("Advanced Options") {
                DisclosureGroup("Chunking Configuration", isExpanded: $showAdvancedOptions) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Custom Chunking", isOn: $useCustomChunking)
                        
                        if useCustomChunking {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chunk Size: \(Int(chunkSize)) tokens")
                                    .font(.caption)
                                Slider(value: $chunkSize, in: 100...4096, step: 100)
                                
                                Text("Chunk Overlap: \(Int(chunkOverlap)) tokens")
                                    .font(.caption)
                                Slider(value: $chunkOverlap, in: 0...(chunkSize/2), step: 50)
                            }
                        }
                        
                        Text("Default: 800 token chunks with 400 token overlap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Vector Store Management") {
                Button {
                    // Navigate to add second store
                    dismiss()
                } label: {
                    Label("Add 2nd Vector Store", systemImage: "folder.badge.plus")
                }
                
                Button {
                    // Navigate to File Manager
                    dismiss()
                } label: {
                    Label("Manage Vector Stores", systemImage: "folder.fill")
                }
            }
        }
    }
    
    // MARK: - Two Vector Stores Selected
    
    private var twoStoresView: some View {
        List {
            Section("Select Destination") {
                Text("Choose which vector store to upload files to:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Section {
                ForEach(selectedStores) { store in
                    Button {
                        targetVectorStore = store
                        showingFilePicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name ?? "Unnamed Vector Store")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    Label("\(store.fileCounts.total) files", systemImage: "doc.fill")
                                        .font(.caption)
                                    Label(formatBytes(store.usageBytes), systemImage: "externaldrive")
                                        .font(.caption)
                                }
                                .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section("Advanced Options") {
                DisclosureGroup("Chunking Configuration", isExpanded: $showAdvancedOptions) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Custom Chunking", isOn: $useCustomChunking)
                        
                        if useCustomChunking {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Chunk Size: \(Int(chunkSize)) tokens")
                                    .font(.caption)
                                Slider(value: $chunkSize, in: 100...4096, step: 100)
                                
                                Text("Chunk Overlap: \(Int(chunkOverlap)) tokens")
                                    .font(.caption)
                                Slider(value: $chunkOverlap, in: 0...(chunkSize/2), step: 50)
                            }
                        }
                        
                        Text("Default: 800 token chunks with 400 token overlap")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    @MainActor
    private func loadVectorStores() async {
        AppLogger.log("📂 Loading vector stores list", category: .fileManager, level: .info)
        isLoading = true
        do {
            vectorStores = try await api.listVectorStores()
            AppLogger.log("✅ Successfully loaded \(vectorStores.count) vector stores", category: .fileManager, level: .info)
        } catch {
            AppLogger.log("❌ Failed to load vector stores: \(error.localizedDescription)", category: .fileManager, level: .error)
            errorMessage = "Failed to load vector stores: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        guard let targetStore = targetVectorStore else {
            AppLogger.log("⚠️ No target vector store selected", category: .fileManager, level: .warning)
            return
        }
        
        AppLogger.log("🎯 Target vector store: \(targetStore.name ?? targetStore.id) (ID: \(targetStore.id))", category: .fileManager, level: .info)
        
        switch result {
        case .success(let urls):
            AppLogger.log("📁 User selected \(urls.count) file(s) for upload", category: .fileManager, level: .info)
            
            // Initialize progress tracking
            isUploading = true
            totalFiles = urls.count
            currentFileIndex = 0
            uploadProgress = []
            
            // Create progress entries for each file
            for url in urls {
                let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
                let progress = UploadProgress(
                    filename: url.lastPathComponent,
                    status: .pending,
                    fileSize: fileSize
                )
                uploadProgress.append(progress)
                AppLogger.log("   📄 \(url.lastPathComponent) (\(formatBytes(fileSize)))", category: .fileManager, level: .debug)
            }
            
            if useCustomChunking {
                AppLogger.log("⚙️ Using custom chunking: \(Int(chunkSize)) tokens with \(Int(chunkOverlap)) overlap", category: .fileManager, level: .info)
            } else {
                AppLogger.log("⚙️ Using default chunking strategy", category: .fileManager, level: .info)
            }
            
            // Process each file
            for (index, url) in urls.enumerated() {
                currentFileIndex = index
                
                AppLogger.log("📤 [\(index + 1)/\(urls.count)] Starting upload: \(url.lastPathComponent)", category: .fileManager, level: .info)
                
                // Update status to uploading
                uploadProgress[index].status = .uploading
                
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                        AppLogger.log("🔓 Released security-scoped resource for: \(url.lastPathComponent)", category: .fileManager, level: .debug)
                    }
                }
                
                do {
                    // Validate and convert file if necessary
                    AppLogger.log("   � Validating file: \(url.lastPathComponent)", category: .fileManager, level: .debug)
                    
                    // Process file through converter (validates size and converts if needed)
                    let conversionResult = try await FileConverterService.processFile(url: url)
                    
                    let fileData = conversionResult.convertedData
                    let filename = conversionResult.filename
                    
                    if conversionResult.wasConverted {
                        AppLogger.log("   🔄 File converted: \(conversionResult.originalFilename) → \(filename)", category: .fileManager, level: .info)
                        AppLogger.log("   📝 Method: \(conversionResult.conversionMethod)", category: .fileManager, level: .debug)
                        
                        // Update progress with conversion info
                        uploadProgress[index].wasConverted = true
                        uploadProgress[index].conversionMethod = conversionResult.conversionMethod
                    }
                    
                    AppLogger.log("   ✅ Prepared \(formatBytes(fileData.count)) from \(filename)", category: .fileManager, level: .info)
                    
                    // Update to uploading status
                    uploadProgress[index].status = .uploading
                    
                    // Upload file to OpenAI
                    AppLogger.log("   ☁️ Uploading \(filename) to OpenAI API...", category: .openAI, level: .info)
                    let uploadedFile = try await api.uploadFile(fileData: fileData, filename: filename)
                    AppLogger.log("   ✅ File uploaded! ID: \(uploadedFile.id)", category: .openAI, level: .info)
                    
                    uploadProgress[index].fileId = uploadedFile.id
                    uploadProgress[index].status = .processing
                    
                    // Prepare chunking strategy if custom
                    let chunkingStrategy: ChunkingStrategy? = useCustomChunking ?
                        ChunkingStrategy.staticStrategy(maxTokens: Int(chunkSize), overlapTokens: Int(chunkOverlap)) : nil
                    
                    // Add to vector store
                    AppLogger.log("   🔗 Adding file to vector store '\(targetStore.name ?? targetStore.id)'...", category: .openAI, level: .info)
                    if let strategy = chunkingStrategy {
                        AppLogger.log("   ⚙️ Chunking: \(Int(chunkSize)) tokens, \(Int(chunkOverlap)) overlap", category: .openAI, level: .debug)
                    }
                    
                    let vectorStoreFile = try await api.addFileToVectorStore(
                        vectorStoreId: targetStore.id,
                        fileId: uploadedFile.id,
                        chunkingStrategy: chunkingStrategy
                    )
                    
                    AppLogger.log("   ✅ File added to vector store! Status: \(vectorStoreFile.status)", category: .openAI, level: .info)
                    
                    uploadProgress[index].status = .completed
                    currentFileIndex = index + 1
                    
                    AppLogger.log("🎉 [\(index + 1)/\(urls.count)] Successfully processed: \(filename)", category: .fileManager, level: .info)
                    
                } catch {
                    AppLogger.log("❌ [\(index + 1)/\(urls.count)] Failed to upload '\(url.lastPathComponent)': \(error.localizedDescription)", category: .fileManager, level: .error)
                    AppLogger.log("   Error details: \(error)", category: .fileManager, level: .debug)
                    
                    uploadProgress[index].status = .failed
                    uploadProgress[index].errorMessage = error.localizedDescription
                    
                    // Continue with other files instead of stopping
                    continue
                }
            }
            
            // All files processed
            let successCount = uploadProgress.filter { $0.status == .completed }.count
            let failedCount = uploadProgress.filter { $0.status == .failed }.count
            
            AppLogger.log("🏁 Upload batch complete: \(successCount) succeeded, \(failedCount) failed", category: .fileManager, level: .info)
            
            // Wait a moment to show final state
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Dismiss if at least one file succeeded
            if successCount > 0 {
                AppLogger.log("✅ Dismissing upload view - at least one file succeeded", category: .fileManager, level: .info)
                
                // Call completion handler before dismissing
                onUploadComplete?(successCount, failedCount)
                
                dismiss()
            } else {
                AppLogger.log("⚠️ All files failed - keeping upload view open", category: .fileManager, level: .warning)
                errorMessage = "All \(urls.count) file(s) failed to upload. Check the console for details."
                isUploading = false
            }
            
        case .failure(let error):
            AppLogger.log("❌ File selection failed: \(error.localizedDescription)", category: .fileManager, level: .error)
            errorMessage = "Failed to select files: \(error.localizedDescription)"
            isUploading = false
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Vector Store Card

struct VectorStoreCard: View {
    let store: VectorStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "folder.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.name ?? "Unnamed Vector Store")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label("\(store.fileCounts.total) files", systemImage: "doc.fill")
                            .font(.caption)
                        Label(formatBytes(store.usageBytes), systemImage: "externaldrive")
                            .font(.caption)
                        Text(store.status)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(store.status).opacity(0.2))
                            .foregroundColor(statusColor(store.status))
                            .cornerRadius(4)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("Created: \(formatDate(store.createdAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed": return .green
        case "in_progress": return .orange
        case "failed": return .red
        default: return .blue
        }
    }
}

// MARK: - Simple Create Vector Store View

struct CreateVectorStoreSimpleView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var storeName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    private let api = OpenAIService()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField("Vector Store Name", text: $storeName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Give your vector store a descriptive name to identify it later")
                }
                
                Section {
                    Button {
                        Task { await createStore() }
                    } label: {
                        if isCreating {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            Text("Create & Select")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(storeName.isEmpty || isCreating)
                }
            }
            .navigationTitle("New Vector Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    @MainActor
    private func createStore() async {
        isCreating = true
        do {
            let newStore = try await api.createVectorStore(name: storeName, fileIds: nil, expiresAfterDays: nil)
            // Automatically select it
            viewModel.activePrompt.selectedVectorStoreIds = newStore.id
            viewModel.saveActivePrompt()
            dismiss()
        } catch {
            errorMessage = "Failed to create vector store: \(error.localizedDescription)"
        }
        isCreating = false
    }
}

// MARK: - Upload Progress Model

/// Represents the upload progress for a single file
struct UploadProgress: Identifiable {
    let id = UUID()
    let filename: String
    var status: UploadStatus
    var fileId: String?
    var errorMessage: String?
    var fileSize: Int
    var wasConverted: Bool = false
    var conversionMethod: String?
    
    enum UploadStatus {
        case pending
        case converting // Converting unsupported file type
        case uploading
        case processing // Adding to vector store
        case completed
        case failed
        
        var icon: String {
            switch self {
            case .pending: return "clock"
            case .converting: return "arrow.triangle.2.circlepath"
            case .uploading: return "arrow.up.circle.fill"
            case .processing: return "gearshape.2.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .pending: return .gray
            case .converting: return .orange
            case .uploading: return .blue
            case .processing: return .purple
            case .completed: return .green
            case .failed: return .red
            }
        }
        
        var description: String {
            switch self {
            case .pending: return "Waiting..."
            case .converting: return "Converting file format..."
            case .uploading: return "Uploading..."
            case .processing: return "Adding to vector store..."
            case .completed: return "Complete!"
            case .failed: return "Failed"
            }
        }
    }
}
