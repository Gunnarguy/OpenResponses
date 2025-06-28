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
    @State private var selectedVectorStore: VectorStore?
    @State private var vectorStoreFiles: [VectorStoreFile] = []
    
    @AppStorage("enableFileSearch") private var enableFileSearch: Bool = false
    @AppStorage("selectedVectorStore") private var selectedVectorStoreId: String = ""
    
    private let api = OpenAIService()
    
    var body: some View {
        NavigationView {
            List {
                // File Search Toggle Section
                Section(header: Text("File Search Tool")) {
                    Toggle("Enable File Search", isOn: $enableFileSearch)
                        .onChange(of: enableFileSearch) { _, newValue in
                            if !newValue {
                                selectedVectorStoreId = ""
                            }
                        }
                }
                
                // Vector Stores Section
                Section(header: Text("Vector Stores")) {
                    if vectorStores.isEmpty && !isLoading {
                        Text("No vector stores found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(vectorStores) { store in
                            VectorStoreRow(
                                store: store,
                                isSelected: store.id == selectedVectorStoreId,
                                onSelect: {
                                    if enableFileSearch {
                                        selectedVectorStoreId = store.id
                                    }
                                },
                                onDelete: {
                                    Task {
                                        await deleteVectorStore(store)
                                    }
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
                                    Task {
                                        await deleteFile(file)
                                    }
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
                }
            }
            .navigationTitle("File Manager")
            .refreshable {
                await loadData()
            }
            .task {
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
                CreateVectorStoreView { name, selectedFileIds in
                    Task {
                        await createVectorStore(name: name, fileIds: selectedFileIds)
                    }
                }
                .environmentObject(FileManagerStore(files: files))
            }
            .sheet(item: $selectedVectorStore) { store in
                VectorStoreDetailView(
                    vectorStore: store,
                    files: vectorStoreFiles,
                    onRemoveFile: { fileId in
                        Task {
                            await removeFileFromVectorStore(store.id, fileId: fileId)
                        }
                    }
                )
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
    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                let filename = url.lastPathComponent
                
                let uploadedFile = try await api.uploadFile(
                    fileData: data,
                    filename: filename,
                    purpose: "assistants"
                )
                
                files.append(uploadedFile)
            } catch {
                errorMessage = "Failed to upload file: \(error.localizedDescription)"
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
    private func createVectorStore(name: String, fileIds: [String]) async {
        do {
            let newStore = try await api.createVectorStore(
                name: name.isEmpty ? nil : name,
                fileIds: fileIds.isEmpty ? nil : fileIds
            )
            vectorStores.append(newStore)
            showingCreateVectorStore = false
        } catch {
            errorMessage = "Failed to create vector store: \(error.localizedDescription)"
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
}

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
    
    let onCreate: (String, [String]) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vector Store Details")) {
                    TextField("Name (optional)", text: $vectorStoreName)
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
            }
            .navigationTitle("Create Vector Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        onCreate(vectorStoreName, Array(selectedFileIds))
                        dismiss()
                    }
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

// MARK: - Vector Store Detail View

struct VectorStoreDetailView: View {
    let vectorStore: VectorStore
    let files: [VectorStoreFile]
    let onRemoveFile: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
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
                                    Text("File ID: \(file.id)")
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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
