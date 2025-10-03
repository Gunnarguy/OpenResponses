import SwiftUI
import UniformTypeIdentifiers
import Combine

/// Redesigned view for managing files and vector stores with OpenAI
/// Features:
/// - Tabbed interface for better organization
/// - Quick actions for common workflows
/// - Search and filter capabilities
/// - Inline file management
/// - Intuitive vector store selection
struct FileManagerView: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var files: [OpenAIFile] = []
    @State private var vectorStores: [VectorStore] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab: FileManagerTab = .quickActions
    
    // Vector store selection state
    @State private var multiSelectVectorStores: Set<String> = []
    @State private var showSaveMultiSelect: Bool = false
    @State private var multiStoreInit: Bool = false
    @State private var multiStoreMode: Bool = false
    
    // Search and filter state
    @State private var searchText: String = ""
    @State private var showOnlyActiveStores: Bool = false
    
    // Sheet presentation state
    @State private var showingFilePicker = false
    @State private var showingCreateVectorStore = false
    @State private var showingEditVectorStore = false
    @State private var showingQuickUpload = false
    @State private var selectedVectorStore: VectorStore?
    @State private var vectorStoreToEdit: VectorStore?
    @State private var vectorStoreFiles: [VectorStoreFile] = []
    @State private var targetVectorStoreForUpload: VectorStore?
    
    // DocumentPicker state
    @State private var selectedFileData: [Data] = []
    @State private var selectedFilenames: [String] = []
    
    // Delete confirmation state
    @State private var fileToDelete: OpenAIFile?
    @State private var vectorStoreToDelete: VectorStore?
    @State private var showingDeleteFileConfirmation = false
    @State private var showingDeleteVectorStoreConfirmation = false
    
    private let api = OpenAIService()
    
    enum FileManagerTab: String, CaseIterable {
        case quickActions = "Quick Actions"
        case files = "Files"
        case vectorStores = "Vector Stores"
        
        var icon: String {
            switch self {
            case .quickActions: return "bolt.fill"
            case .files: return "doc.fill"
            case .vectorStores: return "folder.fill"
            }
        }
    }
    
    // MARK: - Quick Actions Tab
    
    private var quickActionsView: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Text("Quick Actions")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Common workflows for managing files and vector stores")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowBackground(Color.clear)
            }
            
            Section("File Search Configuration") {
                Toggle("Enable File Search", isOn: $viewModel.activePrompt.enableFileSearch)
                    .accessibilityHint("Enables the AI to search through uploaded files and documents")
                    .onChange(of: viewModel.activePrompt.enableFileSearch) { _, newValue in
                        if !newValue {
                            viewModel.activePrompt.selectedVectorStoreIds = nil
                            multiSelectVectorStores.removeAll()
                        }
                        viewModel.saveActivePrompt()
                    }
                
                if viewModel.activePrompt.enableFileSearch {
                    Toggle("Multi-Store Search (Max 2)", isOn: $multiStoreMode)
                        .accessibilityHint("Search across multiple vector stores simultaneously")
                        .onChange(of: multiStoreMode) { _, newValue in
                            if newValue {
                                if let savedIds = viewModel.activePrompt.selectedVectorStoreIds, !savedIds.isEmpty {
                                    let ids = Set(savedIds.split(separator: ",").map { String($0) })
                                    multiSelectVectorStores = ids
                                }
                            } else {
                                multiSelectVectorStores.removeAll()
                                viewModel.activePrompt.selectedVectorStoreIds = nil
                                viewModel.saveActivePrompt()
                            }
                        }
                }
            }
            
            Section("Active Vector Stores") {
                if !viewModel.activePrompt.enableFileSearch {
                    Text("Enable File Search to select vector stores")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else if vectorStores.isEmpty {
                    Text("No vector stores available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(selectedVectorStoresList, id: \.id) { store in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name ?? "Unnamed Store")
                                    .font(.headline)
                                Text("\(store.fileCounts.total) files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button {
                                if multiStoreMode {
                                    multiSelectVectorStores.remove(store.id)
                                    showSaveMultiSelect = true
                                } else {
                                    viewModel.activePrompt.selectedVectorStoreIds = nil
                                    viewModel.saveActivePrompt()
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    if multiStoreMode && showSaveMultiSelect {
                        Button("Save Changes") {
                            viewModel.activePrompt.selectedVectorStoreIds = multiSelectVectorStores.isEmpty ? nil : multiSelectVectorStores.joined(separator: ",")
                            viewModel.saveActivePrompt()
                            showSaveMultiSelect = false
                        }
                        .foregroundColor(.accentColor)
                        .font(.headline)
                    }
                }
            }
            
            Section("Quick Upload") {
                Button {
                    showingQuickUpload = true
                } label: {
                    Label("Upload File to Vector Store", systemImage: "doc.badge.plus")
                }
                .foregroundColor(.accentColor)
                
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Upload File Only", systemImage: "doc.fill")
                }
                .foregroundColor(.accentColor)
                
                Button {
                    showingCreateVectorStore = true
                } label: {
                    Label("Create New Vector Store", systemImage: "folder.badge.plus")
                }
                .foregroundColor(.accentColor)
            }
            
            Section("Statistics") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Total Files")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(files.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Vector Stores")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(vectorStores.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Active")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(selectedVectorStoresList.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    // MARK: - Files Tab
    
    private var filesView: some View {
        List {
            Section {
                HStack {
                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Uploaded Files (\(filteredFiles.count))")) {
                if filteredFiles.isEmpty {
                    if isLoading {
                        ProgressView("Loading files...")
                    } else if files.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Files Uploaded")
                                .font(.headline)
                            Text("Upload your first file to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Text("No files match your search")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(filteredFiles) { file in
                        ImprovedFileRow(
                            file: file,
                            vectorStores: vectorStores,
                            onDelete: {
                                fileToDelete = file
                                showingDeleteFileConfirmation = true
                            },
                            onAddToVectorStore: { store in
                                Task {
                                    await addFileToVectorStore(file, vectorStore: store)
                                }
                            }
                        )
                    }
                }
            }
            
            Section {
                Button {
                    showingFilePicker = true
                } label: {
                    Label("Upload New File", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.accentColor)
                .font(.headline)
            }
        }
    }
    
    // MARK: - Vector Stores Tab
    
    private var vectorStoresView: some View {
        List {
            Section {
                HStack {
                    TextField("Search vector stores...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if viewModel.activePrompt.enableFileSearch {
                    Toggle("Show Only Active Stores", isOn: $showOnlyActiveStores)
                        .font(.caption)
                }
            }
            
            Section(header: Text("Vector Stores (\(filteredVectorStores.count))")) {
                if filteredVectorStores.isEmpty {
                    if isLoading {
                        ProgressView("Loading vector stores...")
                    } else if vectorStores.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("No Vector Stores")
                                .font(.headline)
                            Text("Create your first vector store to organize files")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    } else {
                        Text("No vector stores match your criteria")
                            .foregroundColor(.secondary)
                    }
                } else {
                    ForEach(filteredVectorStores) { store in
                        ImprovedVectorStoreRow(
                            store: store,
                            isSelected: isStoreSelected(store),
                            multiStoreMode: multiStoreMode && viewModel.activePrompt.enableFileSearch,
                            onSelect: {
                                handleStoreSelection(store)
                            },
                            onAddFiles: {
                                targetVectorStoreForUpload = store
                                showingFilePicker = true
                            },
                            onViewDetails: {
                                selectedVectorStore = store
                                Task {
                                    await loadVectorStoreFiles(store.id)
                                }
                            },
                            onEdit: {
                                vectorStoreToEdit = store
                                showingEditVectorStore = true
                            },
                            onDelete: {
                                vectorStoreToDelete = store
                                showingDeleteVectorStoreConfirmation = true
                            }
                        )
                    }
                }
            }
            
            Section {
                Button {
                    showingCreateVectorStore = true
                } label: {
                    Label("Create New Vector Store", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.accentColor)
                .font(.headline)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var selectedVectorStoresList: [VectorStore] {
        if multiStoreMode {
            return vectorStores.filter { multiSelectVectorStores.contains($0.id) }
        } else if let selectedId = viewModel.activePrompt.selectedVectorStoreIds {
            return vectorStores.filter { $0.id == selectedId }
        }
        return []
    }
    
    private var filteredFiles: [OpenAIFile] {
        if searchText.isEmpty {
            return files
        }
        return files.filter { file in
            file.filename.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredVectorStores: [VectorStore] {
        var result = vectorStores
        
        // Apply search filter
        if !searchText.isEmpty {
            result = result.filter { store in
                (store.name ?? "Unnamed").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply active filter
        if showOnlyActiveStores {
            result = result.filter { isStoreSelected($0) }
        }
        
        return result
    }
    
    // MARK: - Helper Methods
    
    private func isStoreSelected(_ store: VectorStore) -> Bool {
        if multiStoreMode {
            return multiSelectVectorStores.contains(store.id)
        } else {
            return store.id == viewModel.activePrompt.selectedVectorStoreIds
        }
    }
    
    private func handleStoreSelection(_ store: VectorStore) {
        guard viewModel.activePrompt.enableFileSearch else { return }
        
        if multiStoreMode {
            if multiSelectVectorStores.contains(store.id) {
                multiSelectVectorStores.remove(store.id)
            } else {
                // Limit to 2 stores maximum
                if multiSelectVectorStores.count < 2 {
                    multiSelectVectorStores.insert(store.id)
                } else {
                    errorMessage = "Maximum of 2 vector stores can be selected for multi-store search"
                    return
                }
            }
            showSaveMultiSelect = true
        } else {
            viewModel.activePrompt.selectedVectorStoreIds = store.id
            viewModel.saveActivePrompt()
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Picker
                Picker("View", selection: $selectedTab) {
                    ForEach(FileManagerTab.allCases, id: \.self) { tab in
                        Label(tab.rawValue, systemImage: tab.icon)
                            .tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Tab Content
                Group {
                    switch selectedTab {
                    case .quickActions:
                        quickActionsView
                    case .files:
                        filesView
                    case .vectorStores:
                        vectorStoresView
                    }
                }
            }
            .navigationTitle("File Manager")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await loadData() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                // Initialize on first appearance
                if !multiStoreInit {
                    multiStoreInit = true
                    if multiStoreMode {
                        if let savedIds = viewModel.activePrompt.selectedVectorStoreIds, !savedIds.isEmpty {
                            let ids = Set(savedIds.split(separator: ",").map { String($0) })
                            multiSelectVectorStores = ids
                        }
                    }
                }
                await loadData()
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
            .confirmationDialog("Delete File", isPresented: $showingDeleteFileConfirmation, presenting: fileToDelete) { file in
                Button("Delete", role: .destructive) {
                    Task { await deleteFile(file) }
                }
                Button("Cancel", role: .cancel) {
                    fileToDelete = nil
                }
            } message: { file in
                Text("Are you sure you want to delete '\(file.filename)'? This action cannot be undone.")
            }
            .confirmationDialog("Delete Vector Store", isPresented: $showingDeleteVectorStoreConfirmation, presenting: vectorStoreToDelete) { store in
                Button("Delete", role: .destructive) {
                    Task { await deleteVectorStore(store) }
                }
                Button("Cancel", role: .cancel) {
                    vectorStoreToDelete = nil
                }
            } message: { store in
                Text("Are you sure you want to delete '\(store.name ?? "this vector store")'? This action cannot be undone.")
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
            .sheet(isPresented: $showingQuickUpload) {
                QuickUploadView(
                    vectorStores: vectorStores,
                    onUpload: { vectorStore in
                        targetVectorStoreForUpload = vectorStore
                        showingQuickUpload = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showingFilePicker = true
                        }
                    }
                )
            }
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.pdf, .plainText, .json, .data, .text, .rtf, .spreadsheet, .presentation, .zip, .commaSeparatedText],
                allowsMultipleSelection: true
            ) { result in
                Task {
                    await handleFileImporterResult(result)
                }
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
    
    /// Handler for fileImporter with proper security-scoped resource management
    @MainActor
    private func handleFileImporterResult(_ result: Result<[URL], Error>) async {
        switch result {
        case .success(let urls):
            errorMessage = nil
            
            for url in urls {
                // Start accessing the security-scoped resource
                let isAccessing = url.startAccessingSecurityScopedResource()
                
                defer {
                    // Always stop accessing when done
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                
                do {
                    // Read the file data
                    let fileData = try Data(contentsOf: url)
                    let filename = url.lastPathComponent
                    
                    // Upload the file
                    let uploadedFile = try await api.uploadFile(fileData: fileData, filename: filename)
                    
                    // If we have a target vector store, add the file to it
                    if let vectorStoreId = targetVectorStoreForUpload?.id {
                        _ = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                    }
                } catch {
                    errorMessage = "Failed to upload '\(url.lastPathComponent)': \(error.localizedDescription)"
                    break // Stop processing on first error
                }
            }
            
            // Refresh data after all uploads
            if let vectorStoreId = targetVectorStoreForUpload?.id {
                await loadVectorStoreFiles(vectorStoreId)
            }
            await loadData()
            
            // Clear the target
            targetVectorStoreForUpload = nil
            
        case .failure(let error):
            errorMessage = "Failed to select files: \(error.localizedDescription)"
        }
    }
    
    /// New handler for multi-file uploads using DocumentPicker with security-scoped resources
    @MainActor
    private func handleMultipleFileUploads() async {
        guard !selectedFileData.isEmpty else { return }
        
        errorMessage = nil
        
        do {
            // Upload all selected files
            for (index, fileData) in selectedFileData.enumerated() {
                let filename = selectedFilenames[safe: index] ?? "document_\(index + 1)"
                let uploadedFile = try await api.uploadFile(fileData: fileData, filename: filename)
                
                // If we have a target vector store, add the file to it
                if let vectorStoreId = targetVectorStoreForUpload?.id {
                    _ = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                }
            }
            
            // Clear the selections and target
            selectedFileData.removeAll()
            selectedFilenames.removeAll()
            
            // Refresh data
            if let vectorStoreId = targetVectorStoreForUpload?.id {
                await loadVectorStoreFiles(vectorStoreId)
            }
            await loadData()
            
            targetVectorStoreForUpload = nil
        } catch {
            errorMessage = "Failed to upload and process files: \(error.localizedDescription)"
        }
    }
    
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
            if viewModel.activePrompt.selectedVectorStoreIds == store.id {
                viewModel.activePrompt.selectedVectorStoreIds = nil
                viewModel.saveActivePrompt()
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

// MARK: - Quick Upload View
struct QuickUploadView: View {
    let vectorStores: [VectorStore]
    let onUpload: (VectorStore) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredStores: [VectorStore] {
        if searchText.isEmpty {
            return vectorStores
        }
        return vectorStores.filter { store in
            (store.name ?? "Unnamed").localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.up.doc.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.accentColor)
                        Text("Upload File to Vector Store")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Select a vector store to upload your file to")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .listRowBackground(Color.clear)
                }
                
                Section {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search vector stores...", text: $searchText)
                    }
                }
                
                Section(header: Text("Select Vector Store")) {
                    if filteredStores.isEmpty {
                        Text("No vector stores found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredStores) { store in
                            Button {
                                onUpload(store)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(store.name ?? "Unnamed Vector Store")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        Text("\(store.fileCounts.total) files")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quick Upload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Improved File Row
struct ImprovedFileRow: View {
    let file: OpenAIFile
    let vectorStores: [VectorStore]
    let onDelete: () -> Void
    let onAddToVectorStore: (VectorStore) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(file.filename)
                        .font(.headline)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        Label(formatBytes(file.bytes), systemImage: "doc.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label(formatDate(file.createdAt), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                
                Menu {
                    Menu("Add to Vector Store") {
                        ForEach(vectorStores) { store in
                            Button {
                                onAddToVectorStore(store)
                            } label: {
                                Label(store.name ?? "Unnamed Store", systemImage: "folder")
                            }
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding(.vertical, 4)
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
        return formatter.string(from: date)
    }
}

// MARK: - Improved Vector Store Row
struct ImprovedVectorStoreRow: View {
    let store: VectorStore
    let isSelected: Bool
    let multiStoreMode: Bool
    let onSelect: () -> Void
    let onAddFiles: () -> Void
    let onViewDetails: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with selection indicator
            HStack {
                if isSelected {
                    Image(systemName: multiStoreMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .foregroundColor(.green)
                        .font(.title3)
                }
                
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
                
                Button {
                    onSelect()
                } label: {
                    Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                        .font(.title3)
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                }
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                Button {
                    onAddFiles()
                } label: {
                    Label("Add Files", systemImage: "plus.circle")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundColor(.accentColor)
                        .cornerRadius(8)
                }
                
                Button {
                    onViewDetails()
                } label: {
                    Label("View Files", systemImage: "list.bullet")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Menu {
                    Button {
                        onEdit()
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
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
        default:
            return .blue
        }
    }
}

// MARK: - Old Vector Store Row (for backward compatibility)

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

// MARK: - Array Extension for Safe Subscripting
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
