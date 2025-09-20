import SwiftUI
import Combine

/// Debug view to test MCP Discovery Service
struct MCPDebugView: View {
    @StateObject private var discoveryService = MCPDiscoveryService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MCP Discovery Debug")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Available Servers: \(discoveryService.availableServers.count)")
                .font(.headline)
            
            if discoveryService.availableServers.isEmpty {
                Text("No servers loaded - this might be the issue!")
                    .foregroundColor(.red)
                
                Button("Force Reload") {
                    // Force reload servers
                    Task { @MainActor in
                        discoveryService.objectWillChange.send()
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                ForEach(discoveryService.availableServers, id: \.name) { server in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(server.displayName)
                            .fontWeight(.medium)
                        Text(server.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Category: \(server.category.displayName)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(6)
                }
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            print("MCPDebugView appeared - server count: \(discoveryService.availableServers.count)")
        }
    }
}

#Preview {
    MCPDebugView()
}
