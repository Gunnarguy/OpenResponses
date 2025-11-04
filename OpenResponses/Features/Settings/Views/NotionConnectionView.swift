import SwiftUI
import Combine

/// A view for managing a direct connection to the Notion API using an integration token.
struct NotionConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = NotionConnectionViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    
                    if viewModel.isConnected {
                        connectedSection
                    } else {
                        connectionSection
                    }
                    
                    instructionsSection
                    
                    if let status = viewModel.statusMessage {
                        statusSection(status)
                    }
                }
                .padding()
            }
            .navigationTitle("Notion Integration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            viewModel.checkConnection()
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.largeTitle)
                    .foregroundColor(.black)
                Text("Notion")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            Text("Connect to your Notion workspace using a standard Integration Token for direct access to your databases and pages.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connect Your Integration")
                .font(.headline)
            
            SecureField("Paste your Integration Token (e.g. ntn_…)", text: $viewModel.tokenInput)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            Button {
                viewModel.connect()
            } label: {
                HStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "link")
                        Text("Connect to Notion")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(viewModel.isTokenValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!viewModel.isTokenValid || viewModel.isLoading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var connectedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                Text("Connected to Notion")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            Button {
                viewModel.testSearch()
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Run a Test Search")
                    Spacer()
                    if viewModel.isLoading {
                        ProgressView()
                    }
                }
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isLoading)
            
            Button(role: .destructive) {
                viewModel.disconnect()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Disconnect")
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How to Get Your Token")
                .font(.headline)
            
            InstructionStep(number: "1", text: "Go to notion.so/my-integrations.")
            InstructionStep(number: "2", text: "Click '+ New integration'.")
            InstructionStep(number: "3", text: "Copy the 'Internal Integration Token'.")
            InstructionStep(number: "4", text: "Paste it above and connect.")
            
            Link(destination: URL(string: "https://www.notion.so/my-integrations")!) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text("Open Notion Integrations")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private func statusSection(_ message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: viewModel.hasError ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundColor(viewModel.hasError ? .red : .blue)
            
            Text(message)
                .font(.caption)
                .foregroundColor(viewModel.hasError ? .red : .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(viewModel.hasError ? Color.red.opacity(0.1) : Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views

private struct InstructionStep: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            Text(text).font(.subheadline)
        }
    }
}

// MARK: - ViewModel

@MainActor
class NotionConnectionViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var tokenInput = ""
    @Published var statusMessage: String?
    @Published var hasError = false
    @Published var isLoading = false
    
    private let notionService = NotionService.shared
    private let keychainKey = "notionApiKey"
    
    var isTokenValid: Bool {
        !tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func checkConnection() {
        isConnected = KeychainService.shared.load(forKey: keychainKey) != nil
        if isConnected {
            setStatus("Already connected to Notion.", isError: false)
        }
    }
    
    func connect() {
        guard isTokenValid else {
            setStatus("Please enter a valid Notion integration token.", isError: true)
            return
        }
        
        let token = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if KeychainService.shared.save(value: token, forKey: keychainKey) {
            isConnected = true
            setStatus("Notion token saved successfully! You can now use Notion features.", isError: false)
            tokenInput = ""
        } else {
            setStatus("Failed to save token securely.", isError: true)
        }
    }
    
    func disconnect() {
        if KeychainService.shared.delete(forKey: keychainKey) {
            isConnected = false
            setStatus("Disconnected from Notion.", isError: false)
        } else {
            setStatus("Failed to disconnect.", isError: true)
        }
    }
    
    func testSearch() {
        isLoading = true
        setStatus("Running test search...", isError: false)
        
        Task {
            do {
                let results = try await notionService.search(query: "Test")
                let resultCount = (results["results"] as? [Any])?.count ?? 0
                setStatus("Test search successful! Found \(resultCount) items. Your connection is working.", isError: false)
            } catch let error as NotionService.NotionError {
                switch error {
                case .notConfigured:
                    setStatus("Notion API key is not configured.", isError: true)
                case .requestFailed(let statusCode, let message):
                    setStatus("Test search failed (HTTP \(statusCode)): \(message). Make sure your integration has access to some pages.", isError: true)
                default:
                    setStatus("Test search failed: \(error.localizedDescription)", isError: true)
                }
            } catch {
                setStatus("An unexpected error occurred: \(error.localizedDescription)", isError: true)
            }
            isLoading = false
        }
    }
    
    private func setStatus(_ message: String, isError: Bool) {
        self.statusMessage = message
        self.hasError = isError
    }
}

// MARK: - Preview

#Preview {
    NotionConnectionView()
}