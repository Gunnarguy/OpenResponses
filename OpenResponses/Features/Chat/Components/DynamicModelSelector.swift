import SwiftUI

/// A view that dynamically fetches and displays available OpenAI models for selection.
struct DynamicModelSelector: View {
    @Binding var selectedModel: String
    let openAIService: OpenAIServiceProtocol
    var isDisabled: Bool = false

    @State private var availableModels: [OpenAIModel] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showModelPicker = false

    // Fallback chat models in case the API call fails
    private let fallbackModels = CurrentModelCatalog.recommended + CurrentModelCatalog.legacy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with model info and refresh
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !availableModels.isEmpty {
                        Text("\(availableModels.count) chat models available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !isLoading {
                        HStack(spacing: 4) {
                            Image(systemName: "wifi.slash")
                                .font(.caption2)
                            Text("Using offline fallback models")
                        }
                        .font(.caption)
                        .foregroundColor(.orange)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    }

                    Button(action: fetchModels) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading || isDisabled)
                }
            }

            // Error message if any
            if let errorMessage = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)

                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            // Model picker with improved styling
            VStack(alignment: .leading, spacing: 0) {
                let usingFallback = availableModels.isEmpty && !isLoading
                Button(action: { showModelPicker = true }) {
                    ModelDisplayRow(
                        modelName: usingFallback ? modelDisplayName(for: selectedModel) : selectedModelDisplayName,
                        description: selectedModelDescription,
                        isOffline: usingFallback
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(isDisabled)
            }
        }
        .onAppear {
            if availableModels.isEmpty {
                fetchModels()
            }
        }
        .sheet(isPresented: $showModelPicker) {
            let usingFallback = availableModels.isEmpty && !isLoading
            let modelsToShow: [OpenAIModel] = usingFallback
                ? fallbackModels.map { OpenAIModel(id: $0, object: "model", created: 0, ownedBy: "openai") }
                : availableModels
            NavigationStack {
                ModelPickerView(
                    selectedModel: $selectedModel,
                    models: modelsToShow,
                    isOffline: usingFallback
                )
            }
        }
    }

    // Helper computed properties for better UI
    private var selectedModelDisplayName: String {
        if let model = availableModels.first(where: { $0.id == selectedModel }) {
            return model.displayName
        }
        return modelDisplayName(for: selectedModel)
    }

    private var selectedModelDescription: String {
        CurrentModelCatalog.description(for: selectedModel)
    }

    private func modelDisplayName(for modelId: String) -> String {
        // Create a temporary model to get display name
        let tempModel = OpenAIModel(id: modelId, object: "model", created: 0, ownedBy: "openai")
        return tempModel.displayName
    }

    private func fetchModels() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let models = try await openAIService.listModels()
                await MainActor.run {
                    self.availableModels = models.filter { model in
                        !CurrentModelCatalog.isRetired(model.id)
                            && ModelCompatibilityService.shared.getCapabilities(for: model.id) != nil
                    }.sorted {
                        let left = CurrentModelCatalog.priority($0.id)
                        let right = CurrentModelCatalog.priority($1.id)
                        return left == right ? $0.id < $1.id : left > right
                    }

                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch models: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ModelDisplayRow: View {
    let modelName: String
    let description: String
    let isOffline: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(modelName)
                    .font(.body)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    if isOffline {
                        Image(systemName: "wifi.slash")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct ModelPickerView: View {
    @Binding var selectedModel: String
    let models: [OpenAIModel]
    let isOffline: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""
    @State private var customModel = ""

    private var filtered: [OpenAIModel] {
        models.filter { search.isEmpty || $0.id.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        List {
            if isOffline {
                Section { Text("Offline catalog. Your API project's model access will be checked when you send a request.").font(.caption).foregroundStyle(.secondary) }
            }
            Section("Current models") {
                ForEach(filtered.filter { CurrentModelCatalog.isModern($0.id) }) { model in modelRow(model) }
            }
            Section("Other supported models") {
                ForEach(filtered.filter { !CurrentModelCatalog.isModern($0.id) }) { model in modelRow(model) }
            }
            Section("Model ID") {
                TextField("Enter a model or snapshot ID", text: $customModel).textInputAutocapitalization(.never).autocorrectionDisabled()
                Button("Use model ID") {
                    selectedModel = customModel.trimmingCharacters(in: .whitespacesAndNewlines)
                    dismiss()
                }.disabled(customModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                Text("Unrecognized models use text-only defaults. Use API Workbench to configure capabilities not yet in the catalog.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .searchable(text: $search, prompt: "Find a model")
        .navigationTitle("Choose Model")
        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
    }

    private func modelRow(_ model: OpenAIModel) -> some View {
        ModelPickerRow(modelId: model.id, displayName: model.displayName,
                       description: CurrentModelCatalog.description(for: model.id), isSelected: selectedModel == model.id) {
            selectedModel = model.id
            dismiss()
        }
    }
}

struct ModelPickerRow: View {
    let modelId: String
    let displayName: String
    let description: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedModel = "gpt-4o"

        var body: some View {
            NavigationStack {
                Form {
                    DynamicModelSelector(
                        selectedModel: $selectedModel,
                        openAIService: OpenAIService()
                    )
                }
                .navigationTitle("Model Selection")
            }
        }
    }

    return PreviewWrapper()
}
