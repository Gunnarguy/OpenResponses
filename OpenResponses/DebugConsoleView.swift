import SwiftUI
import OSLog
import Combine

/// A view that displays real-time debug logs from the app for transparency and debugging.
struct DebugConsoleView: View {
    @StateObject private var consoleLogger = ConsoleLogger.shared
    @State private var filterLevel: OSLogType = .debug
    @State private var filterCategory: String = "All"
    @State private var autoScroll = true
    
    private let availableCategories = ["All", "UI", "Network", "OpenAI", "Streaming", "General"]
    
    var filteredLogs: [LogEntry] {
        consoleLogger.logs.filter { log in
            let matchesLevel = log.level.rawValue >= filterLevel.rawValue
            let matchesCategory = filterCategory == "All" || log.category.rawValue == filterCategory.lowercased()
            return matchesLevel && matchesCategory
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter controls
                HStack {
                    Picker("Level", selection: $filterLevel) {
                        Text("Debug").tag(OSLogType.debug)
                        Text("Info").tag(OSLogType.info)
                        Text("Warning").tag(OSLogType.error)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(maxWidth: 200)
                    
                    Spacer()
                    
                    Picker("Category", selection: $filterCategory) {
                        ForEach(availableCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: 100)
                    
                    Toggle("Auto-scroll", isOn: $autoScroll)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                Divider()
                
                // Console log display
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(filteredLogs) { log in
                                LogEntryView(log: log)
                                    .id(log.id)
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                    .onChange(of: filteredLogs.count) { _, _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Debug Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        consoleLogger.clearLogs()
                    }
                }
            }
        }
    }
}

struct LogEntryView: View {
    let log: LogEntry
    
    private var levelColor: Color {
        switch log.level {
        case .debug:
            return .secondary
        case .info:
            return .blue
        case .error:
            return .orange
        default:
            return .primary
        }
    }
    
    private var levelIcon: String {
        switch log.level {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .error:
            return "⚠️"
        default:
            return "📝"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(levelIcon)
                Text(log.timestamp.formatted(.dateTime.hour().minute().second().secondFraction(.fractional(3))))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                Text("[\(log.category.rawValue.uppercased())]")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(levelColor)
                    .padding(.horizontal, 4)
                    .background(levelColor.opacity(0.1))
                    .cornerRadius(3)
            }
            
            Text(log.message)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .padding(.leading, 20)
        }
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A singleton logger that captures log entries for display in the debug console.
class ConsoleLogger: ObservableObject {
    static let shared = ConsoleLogger()
    
    @Published var logs: [LogEntry] = []
    private let maxLogCount = 500 // Keep last 500 logs
    
    private init() {}
    
    func addLog(_ entry: LogEntry) {
        DispatchQueue.main.async {
            self.logs.append(entry)
            // Keep only the most recent logs
            if self.logs.count > self.maxLogCount {
                self.logs.removeFirst(self.logs.count - self.maxLogCount)
            }
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}

/// Represents a single log entry for the debug console.
struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let level: OSLogType
    let category: AppLogger.Category
    let message: String
}

#Preview {
    DebugConsoleView()
}
