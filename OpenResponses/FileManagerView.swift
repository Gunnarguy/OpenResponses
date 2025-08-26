import SwiftUI
import UniformTypeIdentifiers
import Combine

/// View for managing files and vector stores with OpenAI
struct FileManagerView: View {
    @State private var files: [OpenAIFile] = []
    @State private var vectorStores: [VectorStore] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingFilePicker = false
    @State private var showingCreateVectorStore = false
    @State private var showingEditVectorStore = false
    @State private var selectedVectorStore: VectorStore?
    @State private var vectorStoreToEdit: VectorStore?
    @State private var vectorStoreFiles: [VectorStoreFile] = []
    
    @AppStorage("enableFileSearch") private var enableFileSearch: Bool = false
    @AppStorage("selectedVectorStore") private var selectedVectorStoreId: String = ""
    @AppStorage("selectedVectorStoreIds") private var selectedVectorStoreIds: String = "" // Comma-separated for multi-select
    @AppStorage("multiStoreMode") private var multiStoreMode: Bool = false // Persist multi-store toggle
    @State private var multiSelectVectorStores: Set<String> = []
    @State private var showSaveMultiSelect: Bool = false // Show save button when multi-select changes
    @State private var multiStoreInit: Bool = false // Track if we've initialized multi-store toggle
    
    // New state variables for delete confirmation
    @State private var fileToDelete: OpenAIFile?
    @State private var vectorStoreToDelete: VectorStore?
    @State private var showingDeleteFileConfirmation = false
    @State private var showingDeleteVectorStoreConfirmation = false
    
    private let api = OpenAIService()
    
    var body: some View {
        NavigationView {
            List {
                // File Search Toggle Section
                Section(header: Text("File Search Tool")) {
                    Toggle("Enable File Search", isOn: $enableFileSearch)
                        .accessibilityHint("Enables the AI to search through uploaded files and documents")
                        .onChange(of: enableFileSearch) { _, newValue in
                            if !newValue {
                                selectedVectorStoreId = ""
                                selectedVectorStoreIds = ""
                                multiSelectVectorStores.removeAll()
                                multiStoreMode = false
                            }
                        }
                    Toggle("Enable Multi-Store File Search", isOn: $multiStoreMode)
                        .disabled(!enableFileSearch)
                        .accessibilityHint("Allows searching across multiple vector stores simultaneously")
                        .onChange(of: multiStoreMode) { _, newValue in
                            if newValue {
                                // Restore selection from saved IDs
                                if !selectedVectorStoreIds.isEmpty {
                                    let ids = Set(selectedVectorStoreIds.split(separator: ",").map { String($0) })
                                    multiSelectVectorStores = ids
                                }
                            } else {
                                multiSelectVectorStores.removeAll()
                                selectedVectorStoreIds = ""
                            }
                        }
                    // Show save button if multi-select is enabled
                    if multiStoreMode {
                        Button("Save Selected Vector Stores") {
                            selectedVectorStoreIds = multiSelectVectorStores.joined(separator: ",")
                            showSaveMultiSelect = false
                        }
                        .disabled(multiSelectVectorStores.isEmpty)
                        .foregroundColor(.accentColor)
                        .opacity(showSaveMultiSelect ? 1 : 0.5)
                    }
                }
                // Vector Stores Section
                Section(header: Text(multiStoreMode ? "Vector Stores (Multi-Select)" : "Vector Stores")) {
                    if vectorStores.isEmpty && !isLoading {
                        Text("No vector stores found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(vectorStores) { store in
                            VectorStoreRow(
                                store: store,
                                isSelected: multiStoreMode ? multiSelectVectorStores.contains(store.id) : (store.id == selectedVectorStoreId),
                                onSelect: {
                                    if enableFileSearch {
                                        if multiStoreMode {
                                            if multiSelectVectorStores.contains(store.id) {
                                                multiSelectVectorStores.remove(store.id)
                                            } else {
                                                multiSelectVectorStores.insert(store.id)
                                            }
                                            showSaveMultiSelect = true
                                        } else {
                                            selectedVectorStoreId = store.id
                                            // Also clear multi-select if switching back
                                            multiSelectVectorStores.removeAll()
                                            selectedVectorStoreIds = ""
                                        }
                                    } else {
                                        selectedVectorStoreId = store.id
                                    }
                                },
                                onDelete: {
                                    vectorStoreToDelete = store
                                    showingDeleteVectorStoreConfirmation = true
                                },
                                onEdit: {
                                    vectorStoreToEdit = store
                                    showingEditVectorStore = true
                                },
                                onViewFiles: {
                                    selectedVectorStore = store
                                    Task {
                                        await loadVectorStoreFiles(store.id)
                                    }
                                }
                            )
                        }
                    }
                    Button("Create Vector Store") {
                        showingCreateVectorStore = true
                    }
                    .foregroundColor(.accentColor)
                    .accessibilityConfiguration(
                        hint: AccessibilityUtils.Hint.createVectorStore,
                        identifier: AccessibilityUtils.Identifier.createVectorStoreButton
                    )
                }
                // Files Section
                Section(header: Text("Uploaded Files")) {
                    if files.isEmpty && !isLoading {
                        Text("No files uploaded")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(files) { file in
                            FileRow(
                                file: file,
                                onDelete: {
                                    fileToDelete = file
                                    showingDeleteFileConfirmation = true
                                },
                                onAddToVectorStore: { vectorStore in
                                    Task {
                                        await addFileToVectorStore(file, vectorStore: vectorStore)
                                    }
                                },
                                vectorStores: vectorStores
                            )
                        }
                    }
                    
                    Button("Upload File") {
                        showingFilePicker = true
                    }
                    .foregroundColor(.accentColor)
                    .accessibilityConfiguration(
                        hint: AccessibilityUtils.Hint.uploadFile,
                        identifier: AccessibilityUtils.Identifier.uploadFileButton
                    )
                }
            }
            .navigationTitle("File Manager")
            .refreshable {
                await loadData()
            }
            .task {
                // Only initialize toggle/selection once per view appearance
                if !multiStoreInit {
                    multiStoreInit = true
                    if multiStoreMode {
                        if !selectedVectorStoreIds.isEmpty {
                            let ids = Set(selectedVectorStoreIds.split(separator: ",").map { String($0) })
                            multiSelectVectorStores = ids
                        }
                    } else {
                        multiSelectVectorStores.removeAll()
                    }
                }
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.plainText, .pdf, .json, .data],
                allowsMultipleSelection: false
            ) { result in
                Task {
                    await handleFileSelection(result)
                }
            }
            .sheet(isPresented: $showingCreateVectorStore) {
                CreateVectorStoreView { name, selectedFileIds, expiresAfterDays in
                    Task {
                        await createVectorStore(name: name, fileIds: selectedFileIds, expiresAfterDays: expiresAfterDays)
                    }
                }
                .environmentObject(FileManagerStore(files: files))
            }
            .sheet(item: $selectedVectorStore) { store in
                VectorStoreDetailView(
                    vectorStore: store,
                    files: vectorStoreFiles,
                    allFiles: files,
                    onRemoveFile: { fileId in
                        Task {
                            await removeFileFromVectorStore(store.id, fileId: fileId)
                        }
                    },
                    onAddFile: { fileURL in
                        Task {
                            await handleFileSelection(Result.success([fileURL]), for: store.id)
                        }
                    }
                )
            }
            .sheet(item: $vectorStoreToEdit) { store in
                EditVectorStoreView(
                    store: store,
                    onUpdate: { updatedStore in
                        Task {
                            await updateVectorStore(updatedStore)
                        }
                    }
                )
            }
            .alert("Confirm Deletion", isPresented: $showingDeleteFileConfirmation) {
                Button("Delete", role: .destructive) {
                    if let file = fileToDelete {
                        Task {
                            await deleteFile(file)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    fileToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete the file '\(fileToDelete?.filename ?? "this file")'? This action cannot be undone.")
            }
            .alert("Confirm Deletion", isPresented: $showingDeleteVectorStoreConfirmation) {
                Button("Delete", role: .destructive) {
                    if let store = vectorStoreToDelete {
                        Task {
                            await deleteVectorStore(store)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    vectorStoreToDelete = nil
                }
            } message: {
                Text("Are you sure you want to delete the vector store '\(vectorStoreToDelete?.name ?? "this store")'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let filesTask = api.listFiles(purpose: "assistants")
            async let vectorStoresTask = api.listVectorStores()
            
            files = try await filesTask
            vectorStores = try await vectorStoresTask
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadVectorStoreFiles(_ vectorStoreId: String) async {
        do {
            vectorStoreFiles = try await api.listVectorStoreFiles(vectorStoreId: vectorStoreId)
        } catch {
            errorMessage = "Failed to load vector store files: \(error.localizedDescription)"
        }
    }
    
    // MARK: - File Operations
    
    @MainActor
    private func handleFileSelection(_ result: Result<[URL], Error>, for vectorStoreId: String? = nil) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let uploadedFileId = try await api.uploadFile(from: url)
                
                if let vectorStoreId = vectorStoreId {
                    // If a vector store is specified, add the file directly to it
                    _ = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFileId)
                    // Refresh the files for that specific vector store
                    await loadVectorStoreFiles(vectorStoreId)
                } else {
                    // Otherwise, just add to the general list
                    await loadData() // Reload all data to see the new file
                }
            } catch {
                errorMessage = "Failed to upload and process file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func deleteFile(_ file: OpenAIFile) async {
        do {
            try await api.deleteFile(fileId: file.id)
            files.removeAll { $0.id == file.id }
        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func addFileToVectorStore(_ file: OpenAIFile, vectorStore: VectorStore) async {
        do {
            _ = try await api.addFileToVectorStore(vectorStoreId: vectorStore.id, fileId: file.id)
            // Refresh vector stores to update file counts
            await loadData()
        } catch {
            errorMessage = "Failed to add file to vector store: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Vector Store Operations
    
    @MainActor
    private func createVectorStore(name: String, fileIds: [String], expiresAfterDays: Int?) async {
        do {
            let newStore = try await api.createVectorStore(
                name: name.isEmpty ? nil : name,
                fileIds: fileIds.isEmpty ? nil : fileIds,
                expiresAfterDays: expiresAfterDays
            )
            vectorStores.append(newStore)
            showingCreateVectorStore = false
        } catch {
            errorMessage = "Failed to create vector store: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func updateVectorStore(_ store: VectorStore) async {
        do {
            let updatedStore = try await api.updateVectorStore(
                vectorStoreId: store.id,
                name: store.name,
                expiresAfter: store.expiresAfter,
                metadata: store.metadata
            )
            if let index = vectorStores.firstIndex(where: { $0.id == store.id }) {
                vectorStores[index] = updatedStore
            }
            vectorStoreToEdit = nil  // Clear the edit state to close the sheet
        } catch {
            errorMessage = "Failed to update vector store: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func deleteVectorStore(_ store: VectorStore) async {
        do {
            try await api.deleteVectorStore(vectorStoreId: store.id)
            vectorStores.removeAll { $0.id == store.id }
            
            // Clear selection if this was the selected store
            if selectedVectorStoreId == store.id {
                selectedVectorStoreId = ""
            }
        } catch {
            errorMessage = "Failed to delete vector store: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func removeFileFromVectorStore(_ vectorStoreId: String, fileId: String) async {
        do {
            try await api.removeFileFromVectorStore(vectorStoreId: vectorStoreId, fileId: fileId)
            await loadVectorStoreFiles(vectorStoreId)
        } catch {
            errorMessage = "Failed to remove file from vector store: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views

struct VectorStoreRow: View {
    let store: VectorStore
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onEdit: () -> Void
    let onViewFiles: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(store.name ?? "Unnamed Vector Store")
                    .font(.headline)
                Text("\(store.fileCounts.total) files • \(formatBytes(store.usageBytes))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Status: \(store.status)")
                    .font(.caption)
                    .foregroundColor(store.status == "completed" ? .green : .orange)
                if let expiresAfter = store.expiresAfter {
                    Text("Expires after: \(expiresAfter.days) days (\(expiresAfter.anchor))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                if let expiresAt = store.expiresAt {
                    Text("Expires at: \(Self.formatDate(expiresAt))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .contextMenu {
            Button("View Files") {
                onViewFiles()
            }
            Button("Edit") {
                onEdit()
            }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Formats a UNIX timestamp (seconds) to a short date string.
    private static func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Edit Vector Store View

struct EditVectorStoreView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var expiresAfterDays: String
    // Basic metadata editing (key-value pairs)
    @State private var metadata: [String: String]
    
    let store: VectorStore
    let onUpdate: (VectorStore) -> Void
    
    init(store: VectorStore, onUpdate: @escaping (VectorStore) -> Void) {
        self.store = store
        self.onUpdate = onUpdate
        
        _name = State(initialValue: store.name ?? "")
        _expiresAfterDays = State(initialValue: store.expiresAfter.map { String($0.days) } ?? "")
        
        // For simplicity, this example handles string values.
        // A more robust implementation would handle different value types.
        _metadata = State(initialValue: store.metadata?.compactMapValues { value in
            return String(describing: value)
        } ?? [:])
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vector Store Name")) {
                    TextField("Optional name", text: $name)
                }
                
                Section(header: Text("Expiration (days, optional)"), footer: Text("Leave blank for no expiration.")) {
                    TextField("e.g. 30", text: $expiresAfterDays)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Metadata")) {
                    // A simple way to edit metadata. For a real app, you might want a more complex UI.
                    ForEach(metadata.keys.sorted(), id: \.self) { key in
                        HStack {
                            Text(key)
                            Spacer()
                            TextField("Value", text: Binding(
                                get: { metadata[key] ?? "" },
                                set: { metadata[key] = $0 }
                            ))
                        }
                    }
                    Button("Add Metadata Field") {
                        let newKey = "key\(metadata.count + 1)"
                        metadata[newKey] = "value"
                    }
                }
                
                Section {
                    Button("Update") {
                        let days = Int(expiresAfterDays.trimmingCharacters(in: .whitespacesAndNewlines))
                        let expiresAfter = days.map { ExpiresAfter(anchor: "last_active_at", days: $0) }
                        
                        let updatedStore = VectorStore(
                            id: store.id,
                            object: store.object,
                            createdAt: store.createdAt,
                            name: name.isEmpty ? nil : name,
                            usageBytes: store.usageBytes,
                            fileCounts: store.fileCounts,
                            status: store.status,
                            expiresAfter: expiresAfter,
                            expiresAt: store.expiresAt,
                            lastActiveAt: store.lastActiveAt,
                            metadata: metadata.isEmpty ? nil : metadata
                        )
                        
                        onUpdate(updatedStore)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Vector Store")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


// MARK: - Vector Store Detail View

struct VectorStoreDetailView: View {
    let vectorStore: VectorStore
    let files: [VectorStoreFile]
    let allFiles: [OpenAIFile]
    let onRemoveFile: (String) -> Void
    let onAddFile: (URL) -> Void // Callback for adding a file
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    
    private func getFilename(for fileId: String) -> String {
        if let file = allFiles.first(where: { $0.id == fileId }) {
            return file.filename
        }
        return fileId // Fallback to ID
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Vector Store Info")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(vectorStore.name ?? "Unnamed Vector Store")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Status: \(vectorStore.status)")
                            .font(.subheadline)
                            .foregroundColor(vectorStore.status == "completed" ? .green : .orange)
                        Text("Total Size: \(formatBytes(vectorStore.usageBytes))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if let expiresAfter = vectorStore.expiresAfter {
                            Text("Expires after: \(expiresAfter.days) days (\(expiresAfter.anchor))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if let expiresAt = vectorStore.expiresAt {
                            Text("Expires at: \(Self.formatDate(expiresAt))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        if let metadata = vectorStore.metadata, !metadata.isEmpty {
                            ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \ .key) { key, value in
                                Text("\(key): \(value)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Files (\(files.count))")) {
                    if files.isEmpty {
                        Text("No files in this vector store")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(files) { file in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(getFilename(for: file.id))
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Text(file.status)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(statusColor(file.status))
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                
                                Text("ID: \(file.id)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)

                                Text("Size: \(formatBytes(file.usageBytes))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let error = file.lastError {
                                    Text("Error: \(error.message)")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                Button("Remove", role: .destructive) {
                                    onRemoveFile(file.id)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Vector Store Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add File") {
                        showingFilePicker = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .fileImporter(isPresented: $showingFilePicker, allowedContentTypes: [.plainText, .pdf, .json, .data]) { result in
                if case .success(let url) = result {
                    onAddFile(url)
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }

    /// Formats a UNIX timestamp (seconds) to a short date string.
    private static func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "completed":
            return .green
        case "in_progress":
            return .orange
        case "failed":
            return .red
        case "cancelled":
            return .gray
        default:
            return .blue
        }
    }
}

// MARK: - File Row View

struct FileRow: View {
    let file: OpenAIFile
    let onDelete: () -> Void
    let onAddToVectorStore: (VectorStore) -> Void
    let vectorStores: [VectorStore]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(file.filename)
                    .font(.headline)
                
                Text("\(formatBytes(file.bytes)) • \(file.purpose)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Created: \(formatDate(file.createdAt))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .contextMenu {
            Menu("Add to Vector Store") {
                ForEach(vectorStores) { store in
                    Button(store.name ?? "Unnamed Store") {
                        onAddToVectorStore(store)
                    }
                }
            }
            
            Button("Delete", role: .destructive) {
                onDelete()
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
    
    private func formatDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Create Vector Store View

class FileManagerStore: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    @Published var files: [OpenAIFile]
    
    init(files: [OpenAIFile]) {
        self.files = files
    }
}

struct CreateVectorStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var fileStore: FileManagerStore
    
    @State private var vectorStoreName = ""
    @State private var selectedFileIds: Set<String> = []
    @State private var expiresAfterDays: String = "" // For expiration
    
    let onCreate: (String, [String], Int?) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vector Store Name")) {
                    TextField("Optional name", text: $vectorStoreName)
                }
                Section(header: Text("Expiration (days, optional)"), footer: Text("Leave blank for no expiration. The store will expire after this many days from creation.")) {
                    TextField("e.g. 30", text: $expiresAfterDays)
                        .keyboardType(.numberPad)
                }
                Section(header: Text("Files to Include")) {
                    if fileStore.files.isEmpty {
                        Text("No files available")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(fileStore.files) { file in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(file.filename)
                                        .font(.headline)
                                    Text(formatBytes(file.bytes))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if selectedFileIds.contains(file.id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedFileIds.contains(file.id) {
                                    selectedFileIds.remove(file.id)
                                } else {
                                    selectedFileIds.insert(file.id)
                                }
                            }
                        }
                    }
                }
                Section {
                    Button("Create") {
                        let days = Int(expiresAfterDays.trimmingCharacters(in: .whitespacesAndNewlines))
                        onCreate(vectorStoreName, Array(selectedFileIds), days)
                        dismiss()
                    }
                    .disabled(selectedFileIds.isEmpty)
                }
            }
            .navigationTitle("Create Vector Store")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
