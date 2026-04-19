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
    private let fallbackModels = [
        // Latest chat models (2025)
        "gpt-5.4",
        "gpt-5.4-mini",
        "gpt-5.4-nano",
        "gpt-5.2",
        "gpt-5.2-pro",
        "gpt-5.1",
        "gpt-5",
        "gpt-5-mini",
        "gpt-5-nano",
        "gpt-4.1",
        "gpt-4.1-mini",
        "gpt-4.1-nano",
    // Dedicated computer-use model
    "computer-use-preview",

        // Latest reasoning models
        "o3",
        "o4-mini",

        // Proven chat models
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-4-turbo",
        "gpt-4",
        "gpt-3.5-turbo",

        // Existing reasoning models
        "o1-preview",
        "o1-mini"
    ]

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
        if let model = availableModels.first(where: { $0.id == selectedModel }) {
            let id = model.id.lowercased()

            // Specific descriptions for each model type
            if id.contains("gpt-5") {
                if id.contains("gpt-5.4-pro") {
                    return "🧠 Maximum compute for the toughest work"
                } else if id.contains("gpt-5.4-mini") {
                    return "💨 Strong mini model with computer use"
                } else if id.contains("gpt-5.4-nano") {
                    return "⚡ Cheapest GPT‑5.4-class model"
                } else if id.contains("gpt-5.4") {
                    return "🚀 Latest flagship with computer use"
                } else if id.contains("gpt-5.2-pro") {
                    return "🧠 Extra compute for tougher problems"
                } else if id.contains("gpt-5.2") {
                    return "🚀 Flagship for coding + agentic tasks"
                } else if id.contains("gpt-5.1") {
                    return "🚀 Flagship (previous generation)"
                } else if id.contains("mini") {
                    return "💨 Faster, cost-efficient GPT‑5"
                } else if id.contains("nano") {
                    return "⚡ Fastest, most cost‑efficient GPT‑5"
                }

                return "🚀 GPT‑5 family"
            } else if id.contains("gpt-4.1") {
                if id.contains("nano") {
                    return "⚡ Ultra-fast, cost-efficient"
                } else if id.contains("mini") {
                    return "💨 Fast and affordable"
                } else {
                    return "🔥 Most advanced GPT model"
                }
            } else if id.contains("o4") {
                return "🧠 Advanced reasoning with efficiency"
            } else if id.contains("o3") {
                return "🤔 Deep reasoning and problem-solving"
            } else if id.contains("gpt-4o") {
                if id.contains("mini") {
                    return "⚡ Fast, cost-effective"
                } else {
                    return "🎯 Versatile and reliable"
                }
            } else if id.contains("o1") {
                return "🧩 Step-by-step reasoning"
            } else if id.contains("computer-use-preview") {
                return "🖥️ Legacy Computer Use preview"
            } else if id.contains("gpt-4") {
                return "💪 Powerful general-purpose"
            } else if id.contains("gpt-3.5") {
                return "💰 Budget-friendly option"
            }

            return model.isReasoningModel ? "🧠 Reasoning model" : "💬 Chat model"
        }

        // Fallback descriptions for when model isn't loaded yet
        let id = selectedModel.lowercased()
        if id.contains("gpt-5") {
            if id.contains("gpt-5.4-pro") {
                return "🧠 Maximum compute for the toughest work"
            } else if id.contains("gpt-5.4-mini") {
                return "💨 Strong mini model with computer use"
            } else if id.contains("gpt-5.4-nano") {
                return "⚡ Cheapest GPT‑5.4-class model"
            } else if id.contains("gpt-5.4") {
                return "🚀 Latest flagship with computer use"
            } else if id.contains("gpt-5.2-pro") {
                return "🧠 Extra compute for tougher problems"
            } else if id.contains("gpt-5.2") {
                return "🚀 Flagship for coding + agentic tasks"
            } else if id.contains("gpt-5.1") {
                return "🚀 Flagship (previous generation)"
            } else if id.contains("mini") {
                return "💨 Faster, cost-efficient GPT‑5"
            } else if id.contains("nano") {
                return "⚡ Fastest, most cost‑efficient GPT‑5"
            }

            return "🚀 GPT‑5 family"
        } else if id.contains("gpt-4.1") {
            return "🔥 Most advanced GPT model"
        } else if id.contains("o4") || id.contains("o3") {
            return "🧠 Advanced reasoning model"
        } else if id.contains("gpt-4o") {
            return "🎯 Versatile and reliable"
        } else if id.contains("o1") {
            return "🧩 Step-by-step reasoning"
        } else if id.contains("computer-use-preview") {
            return "🖥️ Legacy Computer Use preview"
        } else {
            return "💬 Chat model"
        }
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
                    // Ultra-strict filtering - only allow models that work with Responses API for chat
                    self.availableModels = models.filter { model in
                        let id = model.id.lowercased()

                        // Explicit allowlist of known working chat models
                        let allowedModels: Set<String> = [
                            // Latest models
                            "gpt-5.4", "gpt-5.4-mini", "gpt-5.4-nano",
                            "gpt-5.2", "gpt-5.2-pro",
                            "gpt-5.1",
                            "gpt-5", "gpt-5-mini", "gpt-5-nano",
                            "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano",
                            "gpt-4.1-2025-04-14",
                            // Dedicated CUA model
                            "computer-use-preview",

                            // Current GPT models
                            "gpt-4o", "gpt-4o-mini",
                            "gpt-4o-2024-08-06", "gpt-4o-mini-2024-07-18",
                            "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo",

                            // Reasoning models
                            "o3", "o4-mini", "o3-mini",
                            "o1-preview", "o1-mini"
                        ]

                        // Check if model is in allowlist
                        if allowedModels.contains(id) {
                            return true
                        }

                        // Allow GPT-5.2 / GPT-5.1 snapshots (but avoid ChatGPT-only aliases).
                        if id.hasPrefix("gpt-5.2-") || id.hasPrefix("gpt-5.1-"), !id.contains("chat-latest") {
                            return true
                        }

                        if id.hasPrefix("gpt-5.4-"), !id.contains("chat-latest") {
                            return true
                        }

                        // Allow o-series models that might have different naming
                        if (id.hasPrefix("o1-") || id.hasPrefix("o3-") || id.hasPrefix("o4-")) &&
                           !id.contains("image") && !id.contains("audio") && !id.contains("vision") { // exclude audio/vision-only variants
                            return true
                        }

                        // Allow gpt models that are clearly for chat
                        if id.hasPrefix("gpt-") &&
                           id.contains("turbo") &&
                           !id.contains("instruct") &&
                           !id.contains("image") &&
                           !id.contains("vision") &&
                           !id.contains("audio") { // exclude audio-only variants
                            return true
                        }

                        // Exclude everything else (all the junk)
                        return false
                    }

                    // Sort models intelligently by capability and recency
                    self.availableModels.sort { first, second in
                        let firstId = first.id.lowercased()
                        let secondId = second.id.lowercased()

                        // Priority order: gpt-5.2-pro > gpt-5.2 > gpt-5.1 > gpt-5 > gpt-4.1 > o4 > o3 > gpt-4o > CUA > o1 > gpt-4 > gpt-3.5
                        let modelPriority: [String: Int] = [
                            "gpt-5.4-pro": 1200,
                            "gpt-5.4": 1150,
                            "gpt-5.4-mini": 990,
                            "gpt-5.4-nano": 980,
                            "gpt-5.2-pro": 1100,
                            "gpt-5.2": 1090,
                            "gpt-5.1": 1080,
                            "gpt-5": 1000,
                            "gpt-5-mini": 960,
                            "gpt-5-nano": 950,
                            "gpt-4.1": 900,
                            "gpt-4.1-mini": 890,
                            "gpt-4.1-nano": 880,
                            "o4-mini": 800,
                            "o3": 700,
                            "o3-mini": 690,
                            "gpt-4o": 600,
                            "gpt-4o-mini": 590,
                            "computer-use-preview": 550,
                            "o1-preview": 500,
                            "o1-mini": 490,
                            "gpt-4-turbo": 400,
                            "gpt-4": 300,
                            "gpt-3.5-turbo": 200
                        ]

                        let firstPriority = modelPriority[firstId] ?? 0
                        let secondPriority = modelPriority[secondId] ?? 0

                        if firstPriority != secondPriority {
                            return firstPriority > secondPriority
                        }

                        // If same priority, sort alphabetically
                        return firstId < secondId
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

    var body: some View {
        List {
            if isOffline {
                let computerCapableFallbackModels = ["gpt-5.4", "gpt-5.4-mini", "computer-use-preview"]
                let latestFallbackModels = ["gpt-5.4-nano", "gpt-5.2", "gpt-5.2-pro", "gpt-5.1", "gpt-5", "gpt-5-mini", "gpt-5-nano", "gpt-4.1", "gpt-4.1-mini", "gpt-4.1-nano"]

                Section("🖥️ Computer Capable") {
                    ForEach(computerCapableFallbackModels, id: \.self) { modelId in
                        ModelPickerRow(
                            modelId: modelId,
                            displayName: tempModelDisplayName(for: modelId),
                            description: tempModelDescription(for: modelId),
                            isSelected: selectedModel == modelId
                        ) {
                            selectedModel = modelId
                            dismiss()
                        }
                    }
                }

                // Fallback models organized by category
                Section("🚀 Latest Models") {
                    ForEach(latestFallbackModels, id: \.self) { modelId in
                        ModelPickerRow(
                            modelId: modelId,
                            displayName: tempModelDisplayName(for: modelId),
                            description: tempModelDescription(for: modelId),
                            isSelected: selectedModel == modelId
                        ) {
                            selectedModel = modelId
                            dismiss()
                        }
                    }
                }

                Section("🧠 Reasoning Models") {
                    ForEach(["o3", "o4-mini", "o1-preview", "o1-mini"], id: \.self) { modelId in
                        ModelPickerRow(
                            modelId: modelId,
                            displayName: tempModelDisplayName(for: modelId),
                            description: tempModelDescription(for: modelId),
                            isSelected: selectedModel == modelId
                        ) {
                            selectedModel = modelId
                            dismiss()
                        }
                    }
                }

                Section("💬 Standard Models") {
                    ForEach(["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"], id: \.self) { modelId in
                        ModelPickerRow(
                            modelId: modelId,
                            displayName: tempModelDisplayName(for: modelId),
                            description: tempModelDescription(for: modelId),
                            isSelected: selectedModel == modelId
                        ) {
                            selectedModel = modelId
                            dismiss()
                        }
                    }
                }
            } else {
                // Live models organized by capability
                let computerCapableModels = models.filter {
                    isComputerCapableModel($0.id)
                }
                let latestModels = models.filter {
                    ($0.id.contains("gpt-5") || $0.id.contains("gpt-4.1") || $0.id.contains("o4")) &&
                    !isComputerCapableModel($0.id)
                }
                let reasoningModels = models.filter { 
                    ($0.id.contains("o3") || $0.id.contains("o1")) && !$0.id.contains("o4")
                }
                let standardModels = models.filter { 
                    ($0.id.contains("gpt-4o") || $0.id.contains("gpt-4") || $0.id.contains("gpt-3.5")) &&
                    !$0.id.contains("gpt-4.1")
                }

                if !computerCapableModels.isEmpty {
                    Section("🖥️ Computer Capable") {
                        ForEach(computerCapableModels) { model in
                            ModelPickerRow(
                                modelId: model.id,
                                displayName: model.displayName,
                                description: modelDescription(for: model.id),
                                isSelected: selectedModel == model.id
                            ) {
                                selectedModel = model.id
                                dismiss()
                            }
                        }
                    }
                }

                if !latestModels.isEmpty {
                    Section("🚀 Latest & Greatest") {
                        ForEach(latestModels) { model in
                            ModelPickerRow(
                                modelId: model.id,
                                displayName: model.displayName,
                                description: modelDescription(for: model.id),
                                isSelected: selectedModel == model.id
                            ) {
                                selectedModel = model.id
                                dismiss()
                            }
                        }
                    }
                }

                if !reasoningModels.isEmpty {
                    Section("🧠 Reasoning Specialists") {
                        ForEach(reasoningModels) { model in
                            ModelPickerRow(
                                modelId: model.id,
                                displayName: model.displayName,
                                description: modelDescription(for: model.id),
                                isSelected: selectedModel == model.id
                            ) {
                                selectedModel = model.id
                                dismiss()
                            }
                        }
                    }
                }

                if !standardModels.isEmpty {
                    Section("💬 Proven Performers") {
                        ForEach(standardModels) { model in
                            ModelPickerRow(
                                modelId: model.id,
                                displayName: model.displayName,
                                description: modelDescription(for: model.id),
                                isSelected: selectedModel == model.id
                            ) {
                                selectedModel = model.id
                                dismiss()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Select Model")
        .navigationBarTitleDisplayMode(.large)
    }

    private func isComputerCapableModel(_ modelId: String) -> Bool {
        ModelCompatibilityService.shared.isToolSupported(.computer, for: modelId, isStreaming: true)
    }

    private func tempModelDisplayName(for modelId: String) -> String {
        let tempModel = OpenAIModel(id: modelId, object: "model", created: 0, ownedBy: "openai")
        return tempModel.displayName
    }

    private func tempModelDescription(for modelId: String) -> String {
        let id = modelId.lowercased()
        if id.contains("gpt-5") {
            if id.contains("gpt-5.4-pro") {
                return "🧠 Maximum compute for the toughest work"
            } else if id.contains("gpt-5.4-mini") {
                return "💨 Strong mini model with computer use"
            } else if id.contains("gpt-5.4-nano") {
                return "⚡ Cheapest GPT‑5.4-class model"
            } else if id.contains("gpt-5.4") {
                return "🚀 Latest flagship with computer use"
            } else if id.contains("gpt-5.2-pro") {
                return "🧠 Extra compute for tougher problems"
            } else if id.contains("gpt-5.2") {
                return "🚀 Flagship for coding + agentic tasks"
            } else if id.contains("gpt-5.1") {
                return "🚀 Flagship (previous generation)"
            } else if id.contains("mini") {
                return "💨 Faster, cost-efficient GPT‑5"
            } else if id.contains("nano") {
                return "⚡ Fastest, most cost‑efficient GPT‑5"
            }

            return "🚀 GPT‑5 family"
        } else if id.contains("gpt-4.1") {
            if id.contains("nano") {
                return "⚡ Ultra-fast, cost-efficient"
            } else if id.contains("mini") {
                return "💨 Fast and affordable"
            } else {
                return "🔥 Most advanced GPT model"
            }
        } else if id.contains("o4") {
            return "🧠 Advanced reasoning with efficiency"
        } else if id.contains("o3") {
            return "🤔 Deep reasoning and problem-solving"
        } else if id.contains("gpt-4o") {
            if id.contains("mini") {
                return "⚡ Fast, cost-effective"
            } else {
                return "🎯 Versatile and reliable"
            }
        } else if id.contains("o1") {
            return "🧩 Step-by-step reasoning"
        } else if id.contains("computer-use-preview") {
            return "🖥️ Legacy Computer Use preview"
        } else if id.contains("gpt-4") {
            return "💪 Powerful general-purpose"
        } else if id.contains("gpt-3.5") {
            return "💰 Budget-friendly option"
        }
        return "💬 Chat model"
    }

    private func modelDescription(for modelId: String) -> String {
        return tempModelDescription(for: modelId)
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
