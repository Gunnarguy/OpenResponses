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
    
    // Initialize with a specific tab (useful for deep linking)
    init(initialTab: FileManagerTab = .quickActions) {
        _selectedTab = State(initialValue: initialTab)
    }
    
    // Vector store selection state
    @State private var multiSelectVectorStores: Set<String> = []
    @State private var showSaveMultiSelect: Bool = false
    @State private var multiStoreInit: Bool = false
    @State private var multiStoreMode: Bool = false
    
    // Search and filter state
    @State private var searchText: String = ""
    @State private var showOnlyActiveStores: Bool = false
    
    // Sheet presentation state - consolidated to prevent conflicts
    @State private var showingFilePicker = false
    @State private var showingCreateVectorStore = false
    @State private var showingEditVectorStore = false
    @State private var showingQuickUpload = false
    @State private var selectedVectorStore: VectorStore?
    @State private var vectorStoreToEdit: VectorStore?
    @State private var vectorStoreFiles: [VectorStoreFile] = []
    @State private var targetVectorStoreForUpload: VectorStore?
    
    // Presentation coordination to prevent conflicts
    @State private var isPresentingAnySheet = false
    @State private var pendingFilePickerRequest: VectorStore? = nil
    
    // Pagination state for vector stores
    @State private var isLoadingMore = false
    @State private var hasMoreVectorStores = false
    @State private var vectorStoreAfterCursor: String?
    
    // DocumentPicker state
    @State private var selectedFileData: [Data] = []
    @State private var selectedFilenames: [String] = []
    
    // Delete confirmation state
    @State private var fileToDelete: OpenAIFile?
    @State private var vectorStoreToDelete: VectorStore?
    @State private var showingDeleteFileConfirmation = false
    @State private var showingDeleteVectorStoreConfirmation = false
    
    // Refresh debouncing
    @State private var pendingRefreshTask: Task<Void, Never>?
    
    private let api = OpenAIService()
    
    // Presentation coordination
    @State private var isPresentationLocked = false
    
    // Computed property to check if any presentation is active
    private var isAnySheetPresented: Bool {
        showingFilePicker || showingCreateVectorStore || showingEditVectorStore || 
        showingQuickUpload || selectedVectorStore != nil || vectorStoreToEdit != nil ||
        showingDeleteFileConfirmation || showingDeleteVectorStoreConfirmation || 
        isPresentationLocked || (errorMessage != nil)
    }
    
    /// Safely presents the file picker with debouncing
    @MainActor
    private func presentFilePicker(for vectorStore: VectorStore? = nil) {
        // Check current state BEFORE making any changes
        let currentlyPresented = showingFilePicker || showingCreateVectorStore || showingEditVectorStore || 
                                showingQuickUpload || selectedVectorStore != nil || vectorStoreToEdit != nil
        
        guard !currentlyPresented && !isPresentationLocked else {
            AppLogger.log("⚠️ Cannot present file picker - another sheet is already presented (currentlyPresented: \(currentlyPresented), locked: \(isPresentationLocked))", category: .fileManager, level: .warning)
            return
        }
        
        // Lock presentations immediately to prevent race conditions
        isPresentationLocked = true
        
        AppLogger.log("📂 Preparing to present file picker for vector store: \(vectorStore?.name ?? "none")", category: .fileManager, level: .info)
        
        // Set target immediately but delay the actual presentation
        targetVectorStoreForUpload = vectorStore
        
        Task { @MainActor in
            // Wait for any existing presentations to fully dismiss
            try? await Task.sleep(for: .milliseconds(500))
            
            // Double-check state after delay
            guard !showingFilePicker && !showingCreateVectorStore && !showingEditVectorStore && 
                  !showingQuickUpload && selectedVectorStore == nil && vectorStoreToEdit == nil else {
                AppLogger.log("⚠️ Cannot present file picker after delay - another sheet became active", category: .fileManager, level: .warning)
                isPresentationLocked = false
                return
            }
            
            AppLogger.log("📂 Actually presenting file picker now", category: .fileManager, level: .info)
            showingFilePicker = true
            
            // Extended unlock time to prevent rapid successive presentations
            try? await Task.sleep(for: .milliseconds(2000))
            isPresentationLocked = false
            AppLogger.log("🔓 Presentation lock released", category: .fileManager, level: .debug)
        }
    }
    
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
                    guard !isAnySheetPresented else { return }
                    showingQuickUpload = true
                } label: {
                    Label("Upload File to Vector Store", systemImage: "doc.badge.plus")
                }
                .foregroundColor(.accentColor)
                
                Button {
                    presentFilePicker()
                } label: {
                    Label("Upload File Only", systemImage: "doc.fill")
                }
                .foregroundColor(.accentColor)
                .disabled(isAnySheetPresented)
                
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
                    presentFilePicker()
                } label: {
                    Label("Upload New File", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .foregroundColor(.accentColor)
                .font(.headline)
                .disabled(isAnySheetPresented)
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
                                presentFilePicker(for: store)
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
                        .onAppear {
                            // Load more when approaching the end (last 5 items)
                            if let lastFilteredStore = filteredVectorStores.last,
                               let lastOverallStore = vectorStores.last,
                               store.id == lastFilteredStore.id,
                               lastFilteredStore.id == lastOverallStore.id,
                               hasMoreVectorStores && !isLoadingMore {
                                Task {
                                    await loadMoreVectorStores()
                                }
                            }
                        }
                    }
                    
                    // Show loading indicator when loading more
                    if isLoadingMore {
                        HStack {
                            Spacer()
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading more...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.vertical, 8)
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
                onRequestFileUpload: {
                    // Use pending mechanism to avoid presentation conflicts
                    AppLogger.log("📤 VectorStore detail requested file upload - queuing request", category: .fileManager, level: .info)
                    pendingFilePickerRequest = store
                    selectedVectorStore = nil // This will trigger the dismissal
                },
                onUpdate: { updatedStore in
                    Task {
                        await updateVectorStore(updatedStore)
                    }
                },
                onDelete: {
                    Task {
                        await deleteVectorStore(store)
                    }
                },
                onAddExistingFiles: { fileIds in
                    Task {
                        // Add each selected file to the vector store
                        for fileId in fileIds {
                            if let file = files.first(where: { $0.id == fileId }) {
                                await addFileToVectorStore(file, vectorStore: store)
                            }
                        }
                        // Refresh the vector store files list
                        await loadVectorStoreFiles(store.id)
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
                    // Use onChange to sequence the presentation properly
                }
            )
        }
        .onChange(of: showingQuickUpload) { _, newValue in
            if !newValue, let targetStore = targetVectorStoreForUpload {
                Task { @MainActor in
                    // Wait for QuickUpload sheet to fully dismiss
                    try? await Task.sleep(for: .milliseconds(600))
                    
                    AppLogger.log("📤 QuickUpload dismissed, proceeding with file picker", category: .fileManager, level: .info)
                    presentFilePicker(for: targetStore)
                }
            }
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
        .onChange(of: showingFilePicker) { _, newValue in
            AppLogger.log("🎯 showingFilePicker changed to: \(newValue)", category: .fileManager, level: .debug)
            // Note: Don't unlock here - let presentFilePicker manage its own lock timing
        }
        .onChange(of: isAnySheetPresented) { _, newValue in
            AppLogger.log("🎯 isAnySheetPresented changed to: \(newValue)", category: .fileManager, level: .debug)
            
            // Handle pending file picker requests when all sheets are dismissed
            if !newValue, let pendingStore = pendingFilePickerRequest {
                AppLogger.log("🎯 All sheets dismissed, processing pending file picker request for: \(pendingStore.name ?? "unknown")", category: .fileManager, level: .info)
                pendingFilePickerRequest = nil
                
                Task { @MainActor in
                    // Small delay to ensure animations complete
                    try? await Task.sleep(for: .milliseconds(300))
                    
                    // Double-check that nothing else started presenting
                    guard !isAnySheetPresented && !isPresentationLocked else {
                        AppLogger.log("⚠️ Cannot process pending file picker - state changed", category: .fileManager, level: .warning)
                        return
                    }
                    
                    AppLogger.log("📂 Presenting file picker for pending request", category: .fileManager, level: .info)
                    targetVectorStoreForUpload = pendingStore
                    showingFilePicker = true
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
            // Load files and first page of vector stores concurrently
            async let filesTask = api.listFiles(purpose: "assistants")
            async let vectorStoresTask = api.listVectorStoresPaginated(limit: 20, after: nil)
            
            files = try await filesTask
            let vectorStoresResponse = try await vectorStoresTask
            
            // Reset pagination state and load first page
            vectorStores = vectorStoresResponse.data
            hasMoreVectorStores = vectorStoresResponse.hasMore
            vectorStoreAfterCursor = vectorStoresResponse.lastId
            
            AppLogger.log("📊 Loaded \(vectorStores.count) vector stores (hasMore: \(hasMoreVectorStores))", category: .fileManager, level: .info)
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            AppLogger.log("❌ Failed to load data: \(error.localizedDescription)", category: .fileManager, level: .error)
        }
        
        isLoading = false
    }
    
    @MainActor
    private func loadMoreVectorStores() async {
        guard hasMoreVectorStores, !isLoadingMore, let cursor = vectorStoreAfterCursor else { return }
        
        isLoadingMore = true
        
        do {
            let response = try await api.listVectorStoresPaginated(limit: 20, after: cursor)
            
            // Append new data
            vectorStores.append(contentsOf: response.data)
            hasMoreVectorStores = response.hasMore
            vectorStoreAfterCursor = response.lastId
            
            AppLogger.log("📊 Loaded \(response.data.count) more vector stores. Total: \(vectorStores.count) (hasMore: \(hasMoreVectorStores))", category: .fileManager, level: .info)
            
        } catch {
            errorMessage = "Failed to load more vector stores: \(error.localizedDescription)"
            AppLogger.log("❌ Failed to load more vector stores: \(error.localizedDescription)", category: .fileManager, level: .error)
        }
        
        isLoadingMore = false
    }
    
    @MainActor
    private func loadVectorStoreFiles(_ vectorStoreId: String) async {
        do {
            vectorStoreFiles = try await api.listVectorStoreFiles(vectorStoreId: vectorStoreId)
        } catch {
            errorMessage = "Failed to load vector store files: \(error.localizedDescription)"
        }
    }
    
    /// Debounced refresh to prevent multiple rapid refreshes during batch operations
    @MainActor
    private func scheduleRefresh(for vectorStoreId: String, delay: TimeInterval = 0.5) {
        // Cancel any pending refresh
        pendingRefreshTask?.cancel()
        
        // Schedule a new refresh after the delay
        pendingRefreshTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            // Only proceed if not cancelled
            guard !Task.isCancelled else { return }
            
            AppLogger.log("🔄 Executing debounced refresh for vector store \(vectorStoreId)", category: .fileManager, level: .info)
            await loadVectorStoreFiles(vectorStoreId)
        }
    }
    
    /// Polls for file processing completion and refreshes the UI when done
    private func pollForFileCompletion(vectorStoreId: String, fileId: String, maxAttempts: Int = 30, interval: TimeInterval = 2.0) async {
        var attempts = 0
        
        while attempts < maxAttempts {
            attempts += 1
            
            do {
                // Small delay before checking
                try await Task.sleep(for: .seconds(interval))
                
                // Check if the file has completed processing
                let files = try await api.listVectorStoreFiles(vectorStoreId: vectorStoreId)
                if let file = files.first(where: { $0.id == fileId }) {
                    AppLogger.log("📊 Polling attempt \(attempts): File \(fileId) status = \(file.status)", category: .fileManager, level: .debug)
                    
                    if file.status == "completed" {
                        AppLogger.log("✅ File processing completed! Refreshing UI...", category: .fileManager, level: .info)
                        _ = await MainActor.run {
                            Task {
                                await loadVectorStoreFiles(vectorStoreId)
                            }
                        }
                        return
                    } else if file.status == "failed" {
                        AppLogger.log("❌ File processing failed: \(file.lastError?.message ?? "Unknown error")", category: .fileManager, level: .error)
                        return
                    }
                    // Continue polling if status is still "in_progress"
                }
            } catch {
                AppLogger.log("⚠️ Polling attempt \(attempts) failed: \(error.localizedDescription)", category: .fileManager, level: .warning)
            }
        }
        
        AppLogger.log("⏰ Polling timed out after \(maxAttempts) attempts. File may still be processing.", category: .fileManager, level: .warning)
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
                    AppLogger.log("📤 Processing file for upload: \(url.lastPathComponent)", category: .fileManager, level: .info)
                    
                    // IMPORTANT: Use FileConverterService for validation and conversion
                    AppLogger.log("   🔍 Validating and converting file...", category: .fileManager, level: .info)
                    let conversionResult = try await FileConverterService.processFile(url: url)
                    
                    let fileData = conversionResult.convertedData
                    let filename = conversionResult.filename
                    
                    if conversionResult.wasConverted {
                        AppLogger.log("   🔄 File converted: \(conversionResult.originalFilename) → \(filename)", category: .fileManager, level: .info)
                        AppLogger.log("   📝 Method: \(conversionResult.conversionMethod)", category: .fileManager, level: .debug)
                    } else {
                        AppLogger.log("   ✅ File natively supported, no conversion needed", category: .fileManager, level: .info)
                    }
                    
                    // Upload the file (possibly converted)
                    AppLogger.log("   ☁️ Uploading to OpenAI...", category: .fileManager, level: .info)
                    let uploadedFile = try await api.uploadFile(fileData: fileData, filename: filename)
                    AppLogger.log("   ✅ Upload complete! File ID: \(uploadedFile.id)", category: .fileManager, level: .info)
                    
                    // If we have a target vector store, add the file to it
                    if let vectorStoreId = targetVectorStoreForUpload?.id {
                        AppLogger.log("   🔗 Adding file to vector store...", category: .fileManager, level: .info)
                        let vectorStoreFile = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                        AppLogger.log("   ✅ File added to vector store (Status: \(vectorStoreFile.status))", category: .fileManager, level: .info)
                        
                        // If the file is still processing, start polling for completion
                        if vectorStoreFile.status == "in_progress" {
                            AppLogger.log("   🔄 File is processing, will poll for completion...", category: .fileManager, level: .info)
                            Task {
                                await pollForFileCompletion(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                            }
                        }
                    }
                    
                    AppLogger.log("🎉 Successfully processed: \(conversionResult.originalFilename)", category: .fileManager, level: .info)
                    
                } catch {
                    AppLogger.log("❌ Failed to process '\(url.lastPathComponent)': \(error.localizedDescription)", category: .fileManager, level: .error)
                    errorMessage = "Failed to upload '\(url.lastPathComponent)': \(error.localizedDescription)"
                    break // Stop processing on first error
                }
            }
            
            // Refresh data after all uploads
            if let vectorStoreId = targetVectorStoreForUpload?.id {
                await loadVectorStoreFiles(vectorStoreId)
            }
            await loadData()
            
            // Smoothly reopen the vector store detail view after uploads
            if let targetStore = targetVectorStoreForUpload {
                AppLogger.log("🔄 Reopening vector store detail view after upload", category: .fileManager, level: .info)
                
                // Small delay to ensure data is refreshed
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(200))
                    
                    // Find the updated vector store from the refreshed list
                    if let updatedStore = vectorStores.first(where: { $0.id == targetStore.id }) {
                        selectedVectorStore = updatedStore
                    } else {
                        // Fallback to original if not found in refreshed list
                        selectedVectorStore = targetStore
                    }
                    
                    // Clear the target after reopening
                    targetVectorStoreForUpload = nil
                }
            } else {
                // Clear the target if no vector store context
                targetVectorStoreForUpload = nil
            }
            
        case .failure(let error):
            AppLogger.log("❌ File selection failed: \(error.localizedDescription)", category: .fileManager, level: .error)
            errorMessage = "Failed to select files: \(error.localizedDescription)"
        }
    }
    
    /// Universal multi-file upload handler with FileConverterService integration
    /// Handles Data-based uploads by writing to temporary files for validation and conversion
    @MainActor
    private func handleMultipleFileUploads() async {
        guard !selectedFileData.isEmpty else { return }
        
        errorMessage = nil
        let totalFiles = selectedFileData.count
        AppLogger.log("📤 Processing \(totalFiles) file(s) for upload with FileConverterService", category: .fileManager, level: .info)
        
        var successCount = 0
        var failedCount = 0
        
        // Upload all selected files with conversion support
        for (index, fileData) in selectedFileData.enumerated() {
            let filename = selectedFilenames[safe: index] ?? "document_\(index + 1)"
            
            AppLogger.log("   📄 [\(index + 1)/\(totalFiles)] Processing: \(filename)", category: .fileManager, level: .info)
            
            // Write Data to temporary file for FileConverterService processing
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            
            do {
                try fileData.write(to: tempURL)
                AppLogger.log("   💾 Wrote to temp file: \(tempURL.lastPathComponent)", category: .fileManager, level: .debug)
                
                // Process with FileConverterService
                AppLogger.log("   🔍 Validating and converting if needed...", category: .fileManager, level: .info)
                let conversionResult = try await FileConverterService.processFile(url: tempURL)
                
                if conversionResult.wasConverted {
                    AppLogger.log("   🔄 File converted: \(conversionResult.originalFilename) → \(conversionResult.filename)", category: .fileManager, level: .info)
                    AppLogger.log("   📝 Method: \(conversionResult.conversionMethod)", category: .fileManager, level: .debug)
                } else {
                    AppLogger.log("   ✅ File natively supported, no conversion needed", category: .fileManager, level: .info)
                }
                
                // Upload the converted file
                AppLogger.log("   ☁️ Uploading to OpenAI...", category: .fileManager, level: .info)
                let uploadedFile = try await api.uploadFile(
                    fileData: conversionResult.convertedData,
                    filename: conversionResult.filename
                )
                AppLogger.log("   ✅ Upload complete! File ID: \(uploadedFile.id)", category: .fileManager, level: .info)
                
                // If we have a target vector store, add the file to it
                if let vectorStoreId = targetVectorStoreForUpload?.id {
                    AppLogger.log("   🔗 Adding file to vector store...", category: .fileManager, level: .info)
                    _ = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                    AppLogger.log("   ✅ File added to vector store", category: .fileManager, level: .info)
                }
                
                successCount += 1
                AppLogger.log("🎉 [\(index + 1)/\(totalFiles)] Successfully processed: \(conversionResult.filename)", category: .fileManager, level: .info)
                
            } catch {
                failedCount += 1
                AppLogger.log("❌ [\(index + 1)/\(totalFiles)] Failed to process '\(filename)': \(error.localizedDescription)", category: .fileManager, level: .error)
            }
            
            // Clean up temp file
            try? FileManager.default.removeItem(at: tempURL)
            AppLogger.log("   🗑️ Cleaned up temp file", category: .fileManager, level: .debug)
        }
        
        AppLogger.log("🏁 Batch upload complete: \(successCount) succeeded, \(failedCount) failed", category: .fileManager, level: .info)
        
        // Clear the selections and target
        selectedFileData.removeAll()
        selectedFilenames.removeAll()
        
        // Refresh data
        if let vectorStoreId = targetVectorStoreForUpload?.id {
            await loadVectorStoreFiles(vectorStoreId)
        }
        await loadData()
        
        targetVectorStoreForUpload = nil
        
        // Show success message if any files succeeded
        if successCount > 0 {
            // You can add a success alert here if desired
        }
    }
    
    @MainActor
    private func handleFileSelection(_ result: Result<[URL], Error>, for vectorStoreId: String? = nil) async {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            do {
                AppLogger.log("📤 Processing file: \(url.lastPathComponent)", category: .fileManager, level: .info)
                
                // Use FileConverterService for validation and conversion
                let conversionResult = try await FileConverterService.processFile(url: url)
                
                if conversionResult.wasConverted {
                    AppLogger.log("   🔄 Converted: \(conversionResult.originalFilename) → \(conversionResult.filename)", category: .fileManager, level: .info)
                }
                
                // Upload the processed file
                let uploadedFile = try await api.uploadFile(fileData: conversionResult.convertedData, filename: conversionResult.filename)
                AppLogger.log("   ✅ Uploaded! File ID: \(uploadedFile.id)", category: .fileManager, level: .info)
                
                if let vectorStoreId = vectorStoreId {
                    // If a vector store is specified, add the file directly to it
                    let vectorStoreFile = try await api.addFileToVectorStore(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                    AppLogger.log("   ✅ Added to vector store (Status: \(vectorStoreFile.status))", category: .fileManager, level: .info)
                    
                    // If the file is still processing, start polling for completion
                    if vectorStoreFile.status == "in_progress" {
                        AppLogger.log("   🔄 File is processing, will poll for completion...", category: .fileManager, level: .info)
                        Task {
                            await pollForFileCompletion(vectorStoreId: vectorStoreId, fileId: uploadedFile.id)
                        }
                    }
                    
                    // Refresh the files for that specific vector store
                    await loadVectorStoreFiles(vectorStoreId)
                } else {
                    // Otherwise, just add to the general list
                    await loadData() // Reload all data to see the new file
                }
            } catch {
                AppLogger.log("❌ Failed to process file: \(error.localizedDescription)", category: .fileManager, level: .error)
                errorMessage = "Failed to upload and process file: \(error.localizedDescription)"
            }
            
        case .failure(let error):
            AppLogger.log("❌ File selection failed: \(error.localizedDescription)", category: .fileManager, level: .error)
            errorMessage = "Failed to select file: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func deleteFile(_ file: OpenAIFile) async {
        do {
            try await api.deleteFile(fileId: file.id)
            files.removeAll { $0.id == file.id }
            AppLogger.log("✅ Successfully deleted file \(file.id)", category: .fileManager, level: .info)
        } catch {
            let errorDesc = error.localizedDescription
            // Check if it's a 404 error (file already deleted)
            if errorDesc.contains("404") || errorDesc.contains("No such File") {
                // File was already deleted - just remove from UI
                AppLogger.log("⚠️ File \(file.id) not found - removing from UI", category: .fileManager, level: .warning)
                files.removeAll { $0.id == file.id }
                self.errorMessage = "File was already deleted."
                // Clear error after a short delay
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    self.errorMessage = nil
                }
            } else {
                AppLogger.log("❌ Failed to delete file: \(errorDesc)", category: .fileManager, level: .error)
                self.errorMessage = "Failed to delete file: \(errorDesc)"
            }
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
            AppLogger.log("✅ Successfully removed file \(fileId) from vector store \(vectorStoreId)", category: .fileManager, level: .info)
            
            // Use debounced refresh to handle batch deletions gracefully
            scheduleRefresh(for: vectorStoreId)
        } catch {
            let errorMessage = error.localizedDescription
            // Check if it's a 404 error (file already removed)
            if errorMessage.contains("404") || errorMessage.contains("No file found") {
                // File was already removed or never existed
                // Just schedule a refresh without showing an error (this is expected during batch operations)
                AppLogger.log("⚠️ File \(fileId) not found in vector store \(vectorStoreId) - already removed", category: .fileManager, level: .info)
                scheduleRefresh(for: vectorStoreId)
            } else {
                AppLogger.log("❌ Failed to remove file from vector store: \(errorMessage)", category: .fileManager, level: .error)
                self.errorMessage = "Failed to remove file: \(errorMessage)"
                scheduleRefresh(for: vectorStoreId)
            }
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


// MARK: - Enhanced Vector Store Detail View with Full Management

struct VectorStoreDetailView: View {
    let vectorStore: VectorStore
    let files: [VectorStoreFile]
    let allFiles: [OpenAIFile]
    let onRemoveFile: (String) -> Void
    let onRequestFileUpload: () -> Void
    let onUpdate: ((VectorStore) -> Void)?
    let onDelete: (() -> Void)?
    let onAddExistingFiles: (([String]) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    // State for editing
    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false
    @State private var showingAssociateFiles = false
    
    // State for adding existing files
    @State private var selectedExistingFiles: Set<String> = []
    
    private func getFilename(for fileId: String) -> String {
        if let file = allFiles.first(where: { $0.id == fileId }) {
            return file.filename
        }
        return fileId // Fallback to ID
    }
    
    // Get files that are NOT already in this vector store
    private var availableFiles: [OpenAIFile] {
        let currentFileIds = Set(files.map { $0.id })
        return allFiles.filter { !currentFileIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Settings Section
                Section {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit Settings", systemImage: "slider.horizontal.3")
                            .foregroundColor(.accentColor)
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Delete Vector Store", systemImage: "trash")
                    }
                } header: {
                    Text("Management")
                }
                
                // MARK: - Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(vectorStore.name ?? "Unnamed Vector Store")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(vectorStore.status)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor(vectorStore.status).opacity(0.2))
                                .foregroundColor(statusColor(vectorStore.status))
                                .cornerRadius(8)
                        }
                        
                        Divider()
                        
                        HStack {
                            Label("\(files.count) files", systemImage: "doc.fill")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Label(formatBytes(vectorStore.usageBytes), systemImage: "externaldrive")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let expiresAfter = vectorStore.expiresAfter {
                            Text("Expires after: \(expiresAfter.days) days (\(expiresAfter.anchor))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        if let expiresAt = vectorStore.expiresAt {
                            Text("Expires at: \(Self.formatDate(expiresAt))")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        
                        if let metadata = vectorStore.metadata, !metadata.isEmpty {
                            Divider()
                            Text("Metadata")
                                .font(.caption)
                                .fontWeight(.semibold)
                            ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(value)")
                                        .font(.caption2)
                                        .foregroundColor(.primary)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Information")
                }
                
                // MARK: - File Management Section
                Section {
                    Button {
                        onRequestFileUpload()
                    } label: {
                        Label("Upload New Files", systemImage: "doc.badge.plus")
                            .foregroundColor(.accentColor)
                            .font(.headline)
                    }
                    
                    Button {
                        showingAssociateFiles = true
                    } label: {
                        Label("Add Existing Files", systemImage: "link.badge.plus")
                            .foregroundColor(.accentColor)
                            .font(.headline)
                    }
                    .disabled(availableFiles.isEmpty)
                } header: {
                    Text("Add Files")
                } footer: {
                    if availableFiles.isEmpty {
                        Text("All your uploaded files are already in this vector store.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Files List Section
                Section {
                    if files.isEmpty {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: "folder")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                                Text("No files yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical)
                            Spacer()
                        }
                    } else {
                        ForEach(files) { file in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(getFilename(for: file.id))
                                        .font(.headline)
                                        .lineLimit(2)
                                    
                                    Spacer()
                                    
                                    Text(file.status)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(statusColor(file.status))
                                        .foregroundColor(.white)
                                        .cornerRadius(6)
                                }
                                
                                HStack(spacing: 12) {
                                    Label(formatBytes(file.usageBytes), systemImage: "doc.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let error = file.lastError {
                                        Label(error.message, systemImage: "exclamationmark.triangle.fill")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    onRemoveFile(file.id)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    onRemoveFile(file.id)
                                } label: {
                                    Label("Remove from Vector Store", systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Text("Files (\(files.count))")
                }
            }
            .navigationTitle("Vector Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                EditVectorStoreView(store: vectorStore) { updatedStore in
                    onUpdate?(updatedStore)
                }
            }
            .sheet(isPresented: $showingAssociateFiles) {
                NavigationView {
                    AssociateExistingFilesView(
                        availableFiles: availableFiles,
                        selectedFileIds: $selectedExistingFiles,
                        onAssociate: {
                            onAddExistingFiles?(Array(selectedExistingFiles))
                            selectedExistingFiles.removeAll()
                        }
                    )
                }
            }
            .confirmationDialog(
                "Delete Vector Store",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete '\(vectorStore.name ?? "this vector store")'? This action cannot be undone.")
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

// MARK: - Associate Existing Files View

struct AssociateExistingFilesView: View {
    let availableFiles: [OpenAIFile]
    @Binding var selectedFileIds: Set<String>
    let onAssociate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredFiles: [OpenAIFile] {
        if searchText.isEmpty {
            return availableFiles
        }
        return availableFiles.filter { $0.filename.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
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
            
            Section {
                if filteredFiles.isEmpty {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "doc.questionmark")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text(searchText.isEmpty ? "No files available" : "No matching files")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical)
                        Spacer()
                    }
                } else {
                    ForEach(filteredFiles) { file in
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
                            
                            if selectedFileIds.contains(file.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                    .font(.title3)
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
            } header: {
                Text("Select Files (\(selectedFileIds.count) selected)")
            } footer: {
                Text("Tap files to select them for addition to the vector store.")
                    .font(.caption)
            }
        }
        .navigationTitle("Add Existing Files")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    onAssociate()
                    dismiss()
                }
                .disabled(selectedFileIds.isEmpty)
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
        return formatter.string(from: date)
    }
}


// MARK: - Vector Store Selector View
struct VectorStoreSelectorView: View {
    let vectorStores: [VectorStore]
    let onSelect: (VectorStore) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if vectorStores.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("No Available Vector Stores")
                            .font(.headline)
                        
                        Text("All vector stores are already active, or you haven't created any yet.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    ForEach(vectorStores) { store in
                        Button {
                            onSelect(store)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(store.name ?? "Unnamed Vector Store")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    Label("\(store.fileCounts.total) files", systemImage: "doc.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Label(formatBytes(store.usageBytes), systemImage: "externaldrive")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text(store.status)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(statusColor(store.status).opacity(0.2))
                                    .foregroundColor(statusColor(store.status))
                                    .cornerRadius(6)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Vector Store")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
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
        default:
            return .blue
        }
    }
}

// MARK: - Array Extension for Safe Subscripting
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}




