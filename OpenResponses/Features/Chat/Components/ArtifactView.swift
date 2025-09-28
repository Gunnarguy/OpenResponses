import SwiftUI

/// Displays code interpreter artifacts (files, logs, data outputs)
struct ArtifactView: View {
    let artifact: CodeInterpreterArtifact
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with file info and expand toggle
            HStack {
                Image(systemName: artifact.iconName)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(artifact.filename)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text(artifact.displayName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Show expand/collapse button for text content
                if case .text(_) = artifact.content {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
            
            // Content display based on artifact type
            if isExpanded || artifact.artifactType == .image {
                contentView
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch artifact.content {
        case .image(let image):
            EnhancedImageView(image: image)
                .padding(.horizontal, 4)
                
        case .text(let text):
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView(.vertical) {
                        Text(text)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                    }
                    .frame(maxHeight: 200)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(UIColor.separator), lineWidth: 1)
                    )
                    
                    HStack {
                        Button("Copy") {
                            UIPasteboard.general.string = text
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Text("\(text.count) characters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            
        case .data(let data):
            VStack(alignment: .leading, spacing: 4) {
                Text("Binary Data")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(formatByteCount(data.count))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if artifact.artifactType == .data {
                    Button("View Raw Data") {
                        // Could show hex viewer or data preview
                        if let string = String(data: data, encoding: .utf8) {
                            UIPasteboard.general.string = string
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 4)
            
        case .error(let message):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Error Loading Artifact")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
                
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private func formatByteCount(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

/// Container view for multiple artifacts
struct ArtifactsView: View {
    let artifacts: [CodeInterpreterArtifact]
    
    var body: some View {
        if !artifacts.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.secondary)
                    Text("Generated Files (\(artifacts.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                ForEach(artifacts) { artifact in
                    ArtifactView(artifact: artifact)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        // Text artifact example
        ArtifactView(artifact: CodeInterpreterArtifact(
            fileId: "cfile_123",
            filename: "analysis.log",
            containerId: "container_456",
            mimeType: "text/plain",
            content: .text("Starting analysis...\nProcessing data...\nCompleted successfully!")
        ))
        
        // Error artifact example  
        ArtifactView(artifact: CodeInterpreterArtifact(
            fileId: "cfile_789",
            filename: "output.csv",
            containerId: "container_456", 
            mimeType: "text/csv",
            content: .error("Network timeout")
        ))
    }
    .padding()
}