import SwiftUI

/// A view that displays detailed API request and response information for debugging and transparency.
struct APIInspectorView: View {
    @ObservedObject var analyticsService = AnalyticsService.shared
    @State private var selectedRequestIndex: Int = 0
    @State private var showRequestDetails = true
    
    var body: some View {
        NavigationView {
            VStack {
                if analyticsService.apiRequestHistory.isEmpty {
                    Spacer()
                    Text("No API requests yet")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Spacer()
                } else {
                    // Request selection picker
                    Picker("Request", selection: $selectedRequestIndex) {
                        ForEach(0..<analyticsService.apiRequestHistory.count, id: \.self) { index in
                            let request = analyticsService.apiRequestHistory[index]
                            Text("Request \(index + 1) - \(request.timestamp.formatted(.dateTime.hour().minute().second()))")
                                .tag(index)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    // Toggle between request and response
                    Picker("View", selection: $showRequestDetails) {
                        Text("Request").tag(true)
                        Text("Response").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Content area
                    if selectedRequestIndex < analyticsService.apiRequestHistory.count {
                        let request = analyticsService.apiRequestHistory[selectedRequestIndex]
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                if showRequestDetails {
                                    // Request details
                                    DetailSection(title: "URL", content: request.url.absoluteString)
                                    DetailSection(title: "Method", content: request.method)
                                    DetailSection(title: "Headers", content: formatHeaders(request.headers))
                                    DetailSection(title: "Body", content: formatJSON(request.body))
                                } else {
                                    // Response details
                                    if let response = request.response {
                                        DetailSection(title: "Status Code", content: "\(response.statusCode)")
                                        DetailSection(title: "Headers", content: formatHeaders(response.headers))
                                        DetailSection(title: "Body", content: formatJSON(response.body))
                                    } else {
                                        Text("No response data available")
                                            .foregroundColor(.secondary)
                                            .padding()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("API Inspector")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        analyticsService.clearRequestHistory()
                    }
                }
            }
        }
    }
    
    private func formatHeaders(_ headers: [String: Any]) -> String {
        var formatted = ""
        for (key, value) in headers {
            if key.lowercased() == "authorization" {
                formatted += "\(key): Bearer sk-***REDACTED***\n"
            } else {
                formatted += "\(key): \(value)\n"
            }
        }
        return formatted
    }
    
    private func formatJSON(_ data: Data) -> String {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return String(data: data, encoding: .utf8) ?? "Unable to decode data"
        }
        return prettyString
    }
}

struct DetailSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    APIInspectorView()
}
