import SwiftUI

/// Smart tool selector for Notion MCP that reduces context window usage
/// by letting users choose only the specific Notion API tools they need
struct NotionToolSelectorView: View {
    @Binding var selectedTools: String // Comma-separated tool names
    @Environment(\.dismiss) private var dismiss
    
    @State private var toolSelection: Set<String> = []
    @State private var showingPresets = false
    
    // Organized Notion API tools by category
    private let toolCategories: [(String, [NotionTool])] = [
        ("📄 Pages", [
            NotionTool(name: "API-post-search", description: "Search all pages", icon: "magnifyingglass"),
            NotionTool(name: "API-retrieve-a-page", description: "Get page details", icon: "doc.text"),
            NotionTool(name: "API-patch-page", description: "Update page properties", icon: "pencil"),
            NotionTool(name: "API-post-page", description: "Create new page", icon: "plus.square")
        ]),
        ("🗄️ Databases", [
            NotionTool(name: "API-post-database-query", description: "Query database", icon: "tablecells"),
            NotionTool(name: "API-retrieve-a-database", description: "Get database info", icon: "square.grid.2x2"),
            NotionTool(name: "API-create-a-database", description: "Create database", icon: "square.grid.2x2.fill"),
            NotionTool(name: "API-update-a-database", description: "Update database", icon: "slider.horizontal.3")
        ]),
        ("📝 Blocks", [
            NotionTool(name: "API-get-block-children", description: "Get block content", icon: "list.bullet"),
            NotionTool(name: "API-patch-block-children", description: "Add blocks", icon: "plus.circle"),
            NotionTool(name: "API-retrieve-a-block", description: "Get block details", icon: "square"),
            NotionTool(name: "API-update-a-block", description: "Update block", icon: "pencil.circle"),
            NotionTool(name: "API-delete-a-block", description: "Delete block", icon: "trash")
        ]),
        ("👥 Users & Comments", [
            NotionTool(name: "API-get-self", description: "Get bot info", icon: "person.circle"),
            NotionTool(name: "API-get-user", description: "Get user info", icon: "person"),
            NotionTool(name: "API-get-users", description: "List all users", icon: "person.2"),
            NotionTool(name: "API-retrieve-a-comment", description: "Get comment", icon: "bubble.left"),
            NotionTool(name: "API-create-a-comment", description: "Add comment", icon: "bubble.left.fill")
        ]),
        ("🔍 Properties", [
            NotionTool(name: "API-retrieve-a-page-property", description: "Get page property", icon: "tag")
        ])
    ]
    
    // Smart presets for common tasks
    private let presets: [ToolPreset] = [
        ToolPreset(
            name: "📊 Page Counter",
            description: "Just count pages",
            tools: ["API-post-search"],
            icon: "number.circle"
        ),
        ToolPreset(
            name: "📚 Content Reader",
            description: "Read page content",
            tools: ["API-post-search", "API-retrieve-a-page", "API-get-block-children"],
            icon: "book"
        ),
        ToolPreset(
            name: "✏️ Content Editor",
            description: "Read and modify content",
            tools: ["API-post-search", "API-retrieve-a-page", "API-patch-page", "API-patch-block-children"],
            icon: "pencil.line"
        ),
        ToolPreset(
            name: "🗃️ Database Manager",
            description: "Query and manage databases",
            tools: ["API-post-database-query", "API-retrieve-a-database", "API-update-a-database"],
            icon: "externaldrive"
        ),
        ToolPreset(
            name: "🎯 Full Access",
            description: "All Notion tools (uses more tokens)",
            tools: [], // Empty means all tools
            icon: "star.circle.fill"
        )
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header with explanation
                    headerSection
                    
                    // Quick presets
                    presetsSection
                    
                    Divider()
                    
                    // Manual tool selection
                    toolCategoriesSection
                    
                    // Selection summary
                    selectionSummary
                }
                .padding()
            }
            .navigationTitle("Notion Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applySelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentSelection()
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Save Context Window Space")
                        .font(.headline)
                    
                    Text("Only enable the tools you need to reduce token usage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.cyan.opacity(0.1))
            .cornerRadius(12)
            
            Text("💡 Tip: Start with a preset, then customize")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Presets")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(presets) { preset in
                    PresetCard(preset: preset) {
                        applyPreset(preset)
                    }
                }
            }
        }
    }
    
    private var toolCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Custom Selection")
                .font(.headline)
            
            ForEach(toolCategories, id: \.0) { category, tools in
                VStack(alignment: .leading, spacing: 12) {
                    Text(category)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(tools) { tool in
                        ToolToggleRow(
                            tool: tool,
                            isSelected: toolSelection.contains(tool.name)
                        ) { isSelected in
                            if isSelected {
                                toolSelection.insert(tool.name)
                            } else {
                                toolSelection.remove(tool.name)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var selectionSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(toolSelection.count) tools selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if toolSelection.isEmpty {
                    Text("All tools will be enabled")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else {
                    Text("Context window optimized ✨")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button("Clear All") {
                toolSelection.removeAll()
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .disabled(toolSelection.isEmpty)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func loadCurrentSelection() {
        if !selectedTools.isEmpty {
            toolSelection = Set(selectedTools.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) })
        }
    }
    
    private func applySelection() {
        if toolSelection.isEmpty {
            selectedTools = ""
        } else {
            selectedTools = Array(toolSelection).sorted().joined(separator: ", ")
        }
    }
    
    private func applyPreset(_ preset: ToolPreset) {
        if preset.tools.isEmpty {
            // "Full Access" preset - clear selection to enable all tools
            toolSelection.removeAll()
        } else {
            toolSelection = Set(preset.tools)
        }
    }
}

// MARK: - Supporting Views

private struct PresetCard: View {
    let preset: ToolPreset
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: preset.icon)
                        .font(.title3)
                        .foregroundColor(.cyan)
                    Spacer()
                }
                
                Text(preset.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(preset.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

private struct ToolToggleRow: View {
    let tool: NotionTool
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .cyan : .secondary)
                
                Image(systemName: tool.icon)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.displayName)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(tool.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.cyan.opacity(0.05) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Models

private struct NotionTool: Identifiable {
    let name: String
    let description: String
    let icon: String
    
    var id: String { name }
    
    var displayName: String {
        name.replacingOccurrences(of: "API-", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .capitalized
    }
}

private struct ToolPreset: Identifiable {
    let name: String
    let description: String
    let tools: [String]
    let icon: String
    
    var id: String { name }
}
