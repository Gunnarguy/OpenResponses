//
//  ConversationExportView.swift
//  OpenResponses
//
//  Power user tools for exporting/importing conversations as JSON.
//  Enables backup, sharing, and advanced workflows.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConversationExportView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingExportSuccess = false
    @State private var showingImportPicker = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - Export Section
                Section {
                    Button {
                        exportCurrentConversation()
                    } label: {
                        Label("Export Current Conversation", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.messages.isEmpty)
                    
                    if let conversation = viewModel.activeConversation {
                        Text("Export \(conversation.messages.count) messages as JSON")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Export \(viewModel.messages.count) messages as JSON")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Label("Export", systemImage: "arrow.up.doc")
                }
                
                // MARK: - Import Section
                Section {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Conversation", systemImage: "square.and.arrow.down")
                    }
                    
                    Text("Import a previously exported conversation JSON file")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Label("Import", systemImage: "arrow.down.doc")
                }
                
                // MARK: - Metadata Section
                Section {
                    if let conversation = viewModel.activeConversation {
                        MetadataRow(label: "Conversation ID", value: conversation.id.uuidString)
                        MetadataRow(label: "Messages", value: "\(conversation.messages.count)")
                        MetadataRow(label: "Last Modified", value: formatDate(conversation.lastModified))
                        
                        if let tokens = viewModel.cumulativeTokenUsage.total, tokens > 0 {
                            MetadataRow(label: "Total Tokens", value: "\(tokens)")
                        }
                    } else if !viewModel.messages.isEmpty {
                        MetadataRow(label: "Messages", value: "\(viewModel.messages.count)")
                        
                        if let tokens = viewModel.cumulativeTokenUsage.total, tokens > 0 {
                            MetadataRow(label: "Total Tokens", value: "\(tokens)")
                        }
                    }
                } header: {
                    Label("Conversation Metadata", systemImage: "info.circle")
                }
                
                // MARK: - Info Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Export Format")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text("Conversations are exported as JSON containing all messages, metadata, and token usage. Exported files can be imported back into the app or used with external tools.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Export & Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImportPicker) {
                // Use a file picker for JSON imports
                // Since DocumentPicker requires bindings, we'll use a simple file importer
                Text("Import not yet implemented")
                    .padding()
            }
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                if let url = exportedURL {
                    Button("Share") {
                        shareFile(url: url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Conversation exported successfully")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Export Logic
    
    private func exportCurrentConversation() {
        let exportData: [String: Any]
        
        if let conversation = viewModel.activeConversation {
            // Export full conversation object
            exportData = [
                "id": conversation.id.uuidString,
                "title": conversation.title,
                "lastModified": ISO8601DateFormatter().string(from: conversation.lastModified),
                "messages": conversation.messages.map { messageToDict($0) },
                "tokenUsage": tokenUsageToDict(viewModel.cumulativeTokenUsage),
                "exportVersion": "1.0",
                "exportedAt": ISO8601DateFormatter().string(from: Date())
            ]
        } else {
            // Export current session messages
            exportData = [
                "id": UUID().uuidString,
                "title": "Exported Session",
                "lastModified": ISO8601DateFormatter().string(from: Date()),
                "messages": viewModel.messages.map { messageToDict($0) },
                "tokenUsage": tokenUsageToDict(viewModel.cumulativeTokenUsage),
                "exportVersion": "1.0",
                "exportedAt": ISO8601DateFormatter().string(from: Date())
            ]
        }
        
        // Convert to JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportData, options: [.prettyPrinted, .sortedKeys]) else {
            errorMessage = "Failed to serialize conversation data"
            return
        }
        
        // Save to temporary file
        let filename = "conversation_\(Date().timeIntervalSince1970).json"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try jsonData.write(to: tempURL)
            exportedURL = tempURL
            showingExportSuccess = true
        } catch {
            errorMessage = "Failed to write export file: \(error.localizedDescription)"
        }
    }
    
    private func messageToDict(_ message: ChatMessage) -> [String: Any] {
        var dict: [String: Any] = [
            "id": message.id.uuidString,
            "role": message.role.rawValue
        ]
        
        if let text = message.text {
            dict["text"] = text
        }
        
        if let usage = message.tokenUsage {
            dict["tokenUsage"] = tokenUsageToDict(usage)
        }
        
        if let tools = message.toolsUsed, !tools.isEmpty {
            dict["toolsUsed"] = tools
        }
        
        return dict
    }
    
    private func tokenUsageToDict(_ usage: TokenUsage) -> [String: Any] {
        var dict: [String: Any] = [:]
        if let input = usage.input { dict["input"] = input }
        if let output = usage.output { dict["output"] = output }
        if let total = usage.total { dict["total"] = total }
        return dict
    }
    
    // MARK: - Import Logic
    
    private func importConversation(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Failed to access file"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            guard (try JSONSerialization.jsonObject(with: data) as? [String: Any]) != nil else {
                errorMessage = "Invalid JSON format"
                return
            }
            
            // TODO: Implement conversation import logic
            // This would require adding methods to ChatViewModel to load imported messages
            errorMessage = "Import feature coming soon"
            
        } catch {
            errorMessage = "Failed to read file: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helpers
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Metadata Row

private struct MetadataRow: View {
    let label: String
    let value: String
    @State private var showCopied = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Button {
                UIPasteboard.general.string = value
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCopied = false
                }
            } label: {
                Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                    .font(.caption)
                    .foregroundColor(showCopied ? .green : .secondary)
            }
            .buttonStyle(BorderlessButtonStyle())
        }
    }
}

// MARK: - Preview

#Preview {
    ConversationExportView()
        .environmentObject({
            let vm = ChatViewModel()
            vm.messages = [
                ChatMessage(id: UUID(), role: .user, text: "Test message"),
                ChatMessage(id: UUID(), role: .assistant, text: "Test response")
            ]
            return vm
        }())
}
