//
//  VectorStoreQuickToggle.swift
//  OpenResponses
//
//  Playground-style inline vector store selector.
//  Shows active vector stores with their names in real-time.
//

import SwiftUI

struct VectorStoreQuickToggle: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showFileManager = false
    @State private var isExpanded = false
    @State private var vectorStores: [VectorStore] = []
    private let api = OpenAIService()
    
    private var activeVectorStoreIds: [String] {
        guard let ids = viewModel.activePrompt.selectedVectorStoreIds else { return [] }
        return ids.split(separator: ",").map { String($0) }
    }
    
    private var activeVectorStores: [VectorStore] {
        vectorStores.filter { activeVectorStoreIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Header button - always visible
            Button {
                if !activeVectorStores.isEmpty {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } else {
                    showFileManager = true
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "folder.badge.plus")
                        .font(.caption)
                    
                    Text("Vector Stores")
                        .font(.caption)
                    
                    // Active count badge
                    if !activeVectorStoreIds.isEmpty {
                        Text("\(activeVectorStoreIds.count)/2")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    } else {
                        Text("0/2")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            // Expandable list of active vector stores
            if isExpanded && !activeVectorStores.isEmpty {
                VStack(spacing: 4) {
                    ForEach(activeVectorStores) { store in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.name ?? "Unnamed Store")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                
                                Text("\(store.fileCounts.total) files • \(formatBytes(store.usageBytes))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                removeVectorStore(store.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    
                    // Manage button at bottom of expanded list
                    Button {
                        showFileManager = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .font(.caption)
                            Text("Manage Vector Stores")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .sheet(isPresented: $showFileManager) {
            FileManagerView(initialTab: .vectorStores)
                .environmentObject(viewModel)
        }
        .onAppear {
            loadVectorStores()
        }
        .onChange(of: viewModel.activePrompt.selectedVectorStoreIds) { _, _ in
            loadVectorStores()
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadVectorStores() {
        guard !activeVectorStoreIds.isEmpty else {
            vectorStores = []
            return
        }
        
        Task {
            do {
                let allStores = try await api.listVectorStores()
                await MainActor.run {
                    vectorStores = allStores
                }
            } catch {
                AppLogger.log("Failed to load vector stores: \(error.localizedDescription)", category: .fileManager, level: .error)
            }
        }
    }
    
    private func removeVectorStore(_ storeId: String) {
        var ids = activeVectorStoreIds
        ids.removeAll { $0 == storeId }
        
        if ids.isEmpty {
            viewModel.activePrompt.selectedVectorStoreIds = nil
        } else {
            viewModel.activePrompt.selectedVectorStoreIds = ids.joined(separator: ",")
        }
        
        viewModel.saveActivePrompt()
        loadVectorStores()
    }
    
    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Preview

#Preview {
    VectorStoreQuickToggle()
        .environmentObject(ChatViewModel())
        .padding()
}

// MARK: - Preview

#Preview {
    VectorStoreQuickToggle()
        .environmentObject(ChatViewModel())
        .padding()
}
