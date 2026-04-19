//
//  ConversationExportView.swift
//  OpenResponses
//
//  Power user tools for exporting/importing conversations as JSON.
//  Enables backup, sharing, and advanced workflows.
//

import SwiftUI
import UniformTypeIdentifiers

struct ConversationTransferDocument: Codable {
    let exportVersion: String
    let exportedAt: Date
    let conversation: Conversation
    let cumulativeTokenUsage: TokenUsage
}

enum ConversationTransferError: LocalizedError {
    case invalidFormat

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "This file is not a valid OpenResponses conversation export."
        }
    }
}

enum ConversationTransferCodec {
    static let currentVersion = "2.0"

    static func exportConversation(_ conversation: Conversation, cumulativeTokenUsage: TokenUsage) throws -> Data {
        let encoder = makeISO8601Encoder()
        let document = ConversationTransferDocument(
            exportVersion: currentVersion,
            exportedAt: Date(),
            conversation: conversation,
            cumulativeTokenUsage: cumulativeTokenUsage
        )
        return try encoder.encode(document)
    }

    static func importConversation(from data: Data) throws -> Conversation {
        let iso8601Decoder = makeISO8601Decoder()

        if let document = try? iso8601Decoder.decode(ConversationTransferDocument.self, from: data) {
            return sanitizeImportedConversation(document.conversation)
        }

        if let conversation = try? iso8601Decoder.decode(Conversation.self, from: data) {
            return sanitizeImportedConversation(conversation)
        }

        if let conversation = try? JSONDecoder().decode(Conversation.self, from: data) {
            return sanitizeImportedConversation(conversation)
        }

        return try decodeLegacyConversation(from: data)
    }

    private static func sanitizeImportedConversation(_ conversation: Conversation) -> Conversation {
        var sanitizedConversation = conversation

        let trimmedTitle = sanitizedConversation.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedTitle.isEmpty {
            sanitizedConversation.title = "Imported Conversation"
        } else {
            sanitizedConversation.title = trimmedTitle
        }

        sanitizedConversation.remoteId = nil
        sanitizedConversation.lastResponseId = nil
        sanitizedConversation.lastSyncedAt = nil
        sanitizedConversation.shouldStoreRemotely = false
        sanitizedConversation.syncState = .localOnly

        return sanitizedConversation
    }

    private static func decodeLegacyConversation(from data: Data) throws -> Conversation {
        guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ConversationTransferError.invalidFormat
        }

        let messages = decodeLegacyMessages(from: payload["messages"] as? [[String: Any]] ?? [])
        let title = (payload["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let conversation = Conversation(
            id: UUID(uuidString: payload["id"] as? String ?? "") ?? UUID(),
            remoteId: nil,
            title: (title?.isEmpty == false ? title : "Imported Conversation") ?? "Imported Conversation",
            messages: messages,
            lastResponseId: nil,
            lastModified: decodeLegacyDate(payload["lastModified"]) ?? Date(),
            metadata: nil,
            lastSyncedAt: nil,
            shouldStoreRemotely: false,
            syncState: .localOnly
        )

        return sanitizeImportedConversation(conversation)
    }

    private static func decodeLegacyMessages(from payload: [[String: Any]]) -> [ChatMessage] {
        payload.compactMap { message in
            let role = ChatMessage.Role(rawValue: message["role"] as? String ?? "") ?? .system
            let tokenUsage = decodeLegacyTokenUsage(message["tokenUsage"] as? [String: Any])

            return ChatMessage(
                id: UUID(uuidString: message["id"] as? String ?? "") ?? UUID(),
                role: role,
                text: message["text"] as? String,
                toolsUsed: message["toolsUsed"] as? [String],
                tokenUsage: tokenUsage
            )
        }
    }

    private static func decodeLegacyTokenUsage(_ payload: [String: Any]?) -> TokenUsage? {
        guard let payload else { return nil }

        return TokenUsage(
            estimatedOutput: payload["estimatedOutput"] as? Int,
            input: payload["input"] as? Int,
            output: payload["output"] as? Int,
            total: payload["total"] as? Int
        )
    }

    private static func decodeLegacyDate(_ rawValue: Any?) -> Date? {
        if let seconds = rawValue as? TimeInterval {
            return Date(timeIntervalSince1970: seconds)
        }

        if let seconds = rawValue as? Double {
            return Date(timeIntervalSince1970: seconds)
        }

        if let seconds = rawValue as? Int {
            return Date(timeIntervalSince1970: TimeInterval(seconds))
        }

        guard let stringValue = rawValue as? String else { return nil }

        let formatters: [ISO8601DateFormatter] = [
            {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return formatter
            }(),
            {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                return formatter
            }(),
        ]

        for formatter in formatters {
            if let date = formatter.date(from: stringValue) {
                return date
            }
        }

        return nil
    }

    private static func makeISO8601Encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static func makeISO8601Decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

struct ConversationExportView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showingExportSuccess = false
    @State private var showingImportPicker = false
    @State private var exportedURL: URL?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
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
            .fileImporter(isPresented: $showingImportPicker, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
                do {
                    guard let url = try result.get().first else { return }
                    importConversation(from: url)
                } catch {
                    errorMessage = "Failed to import file: \(error.localizedDescription)"
                }
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
        let conversation = viewModel.activeConversation ?? Conversation(
            id: UUID(),
            remoteId: nil,
            title: "Exported Session",
            messages: viewModel.messages,
            lastResponseId: nil,
            lastModified: Date(),
            metadata: nil,
            lastSyncedAt: nil,
            shouldStoreRemotely: false,
            syncState: .localOnly
        )

        let jsonData: Data
        do {
            jsonData = try ConversationTransferCodec.exportConversation(
                conversation,
                cumulativeTokenUsage: viewModel.cumulativeTokenUsage
            )
        } catch {
            errorMessage = "Failed to serialize conversation data: \(error.localizedDescription)"
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
    
    // MARK: - Import Logic
    
    private func importConversation(from url: URL) {
        let didAccessSecurityScopedResource = url.startAccessingSecurityScopedResource()
        defer {
            if didAccessSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try Data(contentsOf: url)
            let conversation = try ConversationTransferCodec.importConversation(from: data)
            viewModel.importConversation(conversation)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
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
