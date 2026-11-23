import PhotosUI
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A playground for POST /v1/decisions: write input, ask typed questions, read the probabilities.
/// Questions are saved on this device in UserDefaults; the input text and image are not saved.
struct DecisionsView: View {
    @AppStorage("exploreModeEnabled") private var exploreModeEnabled = false
    @AppStorage(AppFeatureFlags.aiDataSharingConsentVersionKey) private var consentVersion = 0
    @AppStorage("decisionsQuestions.v1") private var savedQuestions = Data()

    @State private var request = DecisionsRequest.example
    @State private var photo: PhotosPickerItem?
    @State private var thumbnail: UIImage?
    @State private var result: DecisionsResult?
    @State private var status = ""
    @State private var running: Task<Void, Never>?
    @State private var showingConsent = false
    @State private var editing: DecisionQuestion.ID?
    @State private var restored = false

    var body: some View {
        Form {
            Section {
                TextField("Text to evaluate", text: $request.input, axis: .vertical)
                    .lineLimit(3...12)
                    .accessibilityIdentifier("decisions.input")
                if let thumbnail {
                    HStack {
                        Image(uiImage: thumbnail).resizable().scaledToFit().frame(maxHeight: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityLabel("Attached image")
                        Spacer()
                        Button("Remove", role: .destructive) { removeImage() }
                    }
                }
                PhotosPicker(selection: $photo, matching: .images) {
                    Label(thumbnail == nil ? "Add Image" : "Replace Image", systemImage: "photo")
                }
            } header: {
                Text("Input")
            } footer: {
                Text("Every question is asked about this input.")
            }

            Section {
                ForEach(Array(request.questions.enumerated()), id: \.element.id) { index, question in
                    Button { editing = question.id } label: {
                        QuestionRow(question: question, index: index)
                    }
                    .tint(.primary)
                }
                .onDelete { request.questions.remove(atOffsets: $0) }
                .onMove { request.questions.move(fromOffsets: $0, toOffset: $1) }
                Menu {
                    ForEach(DecisionQuestionKind.allCases, id: \.self) { kind in
                        Button(kind.title) { addQuestion(kind) }
                    }
                } label: {
                    Label("Add Question", systemImage: "plus.circle")
                }
                .disabled(request.questions.count >= DecisionsRequest.maxQuestions)
            } header: {
                Text("Questions")
            } footer: {
                Text("Up to \(DecisionsRequest.maxQuestions) questions run in one request. A question that depends on another answer needs its own request.")
            }

            Section {
                Button {
                    if running == nil { requestRun() } else { stop() }
                } label: {
                    HStack {
                        Label(running == nil ? "Ask" : "Stop", systemImage: running == nil ? "checkmark.seal" : "stop.circle")
                        Spacer()
                        if running != nil { ProgressView() }
                    }
                }
                .disabled(running == nil && request.problem != nil)
                .accessibilityIdentifier("decisions.ask")
                if let problem = request.problem {
                    Text(problem).font(.footnote).foregroundStyle(.secondary)
                } else if !status.isEmpty {
                    Text(status).font(.footnote).foregroundStyle(.red).textSelection(.enabled)
                }
            } footer: {
                Text("Model: \(CurrentModelCatalog.decisionsModel), the only one Decisions accepts. Input costs $0.10 per million tokens and answers are not charged.")
            }

            if let result {
                Section {
                    ForEach(Array(result.answers.enumerated()), id: \.offset) { index, answer in
                        AnswerView(answer: answer, question: question(for: answer, at: index))
                    }
                } header: {
                    Text("Answers")
                } footer: {
                    Text(usageText(result))
                }
            }
        }
        .navigationTitle("Decisions")
        .navigationDestination(item: $editing) { id in
            if let index = request.questions.firstIndex(where: { $0.id == id }) {
                DecisionQuestionEditor(question: $request.questions[index])
            }
        }
        .toolbar {
            ToolbarItem(placement: .trailingBar) {
                Menu {
                    Section("Examples") {
                        ForEach(DecisionsRequest.examples, id: \.title) { example in
                            Button(example.title) { load(example.request) }
                        }
                    }
                    Button {
                        UIPasteboard.general.string = ResponsesAPIClient.pretty(request.body)
                        status = ""
                    } label: {
                        Label("Copy Request JSON", systemImage: "doc.on.doc")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle").accessibilityLabel("More")
                }
            }
            #if !os(macOS)
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            #endif
        }
        .onAppear(perform: restore)
        .onChange(of: request.questions) { _, questions in
            guard restored else { return }
            savedQuestions = (try? JSONEncoder().encode(questions)) ?? Data()
        }
        .onChange(of: photo) { _, item in loadImage(item) }
        .onDisappear { stop() }
        .alert("Before You Send", isPresented: $showingConsent) {
            Button("Allow & Send") {
                consentVersion = AppFeatureFlags.aiDataSharingConsentVersion
                run()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("OpenAI will receive your input, any image, and your questions, and normal API usage charges apply. Your API key is stored in this device’s Keychain and sent to OpenAI to authenticate the request.")
        }
    }

    // MARK: Actions

    private func restore() {
        guard !restored else { return }
        if let questions = try? JSONDecoder().decode([DecisionQuestion].self, from: savedQuestions), !questions.isEmpty {
            request.questions = questions
            request.input = ""
        }
        restored = true
    }

    private func load(_ example: DecisionsRequest) {
        stop()
        removeImage()
        request = example
        result = nil
        status = ""
    }

    private func addQuestion(_ kind: DecisionQuestionKind) {
        var question = DecisionQuestion(kind: kind)
        switch kind {
        case .predicate: break
        case .choice: question.options = [DecisionOption(value: ""), DecisionOption(value: "")]
        case .score: question.options = [DecisionOption(value: "Low"), DecisionOption(value: "High")]
        }
        request.questions.append(question)
        editing = question.id
    }

    private func removeImage() {
        photo = nil
        thumbnail = nil
        request.imageDataURL = nil
    }

    private func loadImage(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            guard let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data),
                  let encoded = Self.dataURL(for: image) else {
                status = "That image could not be read."
                return
            }
            thumbnail = image
            request.imageDataURL = encoded
            status = ""
        }
    }

    /// A JPEG data URL no larger than 1,536 pixels on its longest side, which keeps the request small.
    static func dataURL(for image: UIImage, maxSide: CGFloat = 1536) -> String? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let size = CGSize(width: (image.size.width * scale).rounded(), height: (image.size.height * scale).rounded())
        #if os(macOS)
        // A 1x bitmap of exactly `size` pixels; Retina backing would double it.
        guard let source = image.cgImage,
              let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return nil }
        context.interpolationQuality = .high
        context.draw(source, in: CGRect(origin: .zero, size: size))
        guard let resized = context.makeImage().map({ NSImage(cgImage: $0) }),
              let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        #else
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
        guard let jpeg = resized.jpegData(compressionQuality: 0.8) else { return nil }
        #endif
        return "data:image/jpeg;base64," + jpeg.base64EncodedString()
    }

    private func requestRun() {
        guard !exploreModeEnabled else {
            status = "Demo Mode is offline. Turn off Demo Mode at the top of Settings to make live requests."
            return
        }
        guard let key = KeychainService.shared.load(forKey: "openAIKey"), !key.isEmpty else {
            status = OpenAIServiceError.missingAPIKey.localizedDescription
            return
        }
        guard consentVersion >= AppFeatureFlags.aiDataSharingConsentVersion else {
            showingConsent = true
            return
        }
        run()
    }

    private func run() {
        let snapshot = request
        status = ""
        running = Task {
            defer { running = nil }
            do {
                let answer = try await DecisionsService().run(snapshot)
                guard !Task.isCancelled else { return }
                result = answer
            } catch {
                guard !Task.isCancelled else { return }
                status = error.localizedDescription
            }
        }
    }

    private func stop() {
        running?.cancel()
        running = nil
    }

    // MARK: Presentation

    /// Answers come back in question order; the name confirms the match when the questions changed since the run.
    private func question(for answer: DecisionsResult.Answer, at index: Int) -> DecisionQuestion? {
        if let name = answer.name, let match = request.questions.enumerated().first(where: { $0.element.resolvedName(index: $0.offset) == name }) {
            return match.element
        }
        return request.questions.indices.contains(index) ? request.questions[index] : nil
    }

    private func usageText(_ result: DecisionsResult) -> String {
        var text = "\(result.inputTokens.formatted()) input tokens"
        if result.cachedTokens > 0 { text += ", \(result.cachedTokens.formatted()) from the prompt cache" }
        if let cost = result.estimatedCost { text += ", about $\(String(format: "%.6f", cost))" }
        return text + " on \(result.model)."
    }
}

// MARK: - Rows

private struct QuestionRow: View {
    let question: DecisionQuestion
    let index: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(question.resolvedName(index: index)).font(.body.monospaced())
                Spacer()
                Text(question.kind.title).font(.caption).foregroundStyle(.secondary)
            }
            Text(question.instructions.isEmpty ? "No instructions yet" : question.instructions)
                .font(.footnote).foregroundStyle(.secondary).lineLimit(2)
        }
        .accessibilityElement(children: .combine)
    }
}

struct AnswerView: View {
    let answer: DecisionsResult.Answer
    let question: DecisionQuestion?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(answer.name ?? "Unnamed question").font(.subheadline.monospaced())
            switch answer {
            case .predicate(_, let probability):
                ProbabilityBar(label: "True", probability: probability, highlighted: probability >= 0.5)
            case .choice(_, let choice, let confidence, let bars):
                Text(choice).font(.headline).fixedSize(horizontal: false, vertical: true)
                Text("Confidence \(percent(confidence))").font(.footnote).foregroundStyle(.secondary)
                ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                    ProbabilityBar(label: bar.label, probability: bar.probability, highlighted: bar.label == choice)
                }
            case .score(_, let score, let confidence, let bars):
                Text(scoreText(score, levels: bars.count)).font(.headline).fixedSize(horizontal: false, vertical: true)
                Text("Confidence \(percent(confidence))").font(.footnote).foregroundStyle(.secondary)
                ForEach(Array(bars.enumerated()), id: \.offset) { index, bar in
                    ProbabilityBar(label: "\(index) \(bar.label)", probability: bar.probability,
                                   highlighted: index == Int(score.rounded()))
                }
            case .refusal:
                Label("The model declined to answer this question.", systemImage: "hand.raised").foregroundStyle(.orange)
            case .unknown(_, let type):
                Text("Answer type \(type) is new to this version of the app.").foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func percent(_ value: Double) -> String { value.formatted(.percent.precision(.fractionLength(0))) }

    /// The score is a probability-weighted average of level indices, so it can fall between levels.
    private func scoreText(_ score: Double, levels: Int) -> String {
        let nearest = question?.options.indices.contains(Int(score.rounded())) == true ? question!.options[Int(score.rounded())].value : nil
        let base = "Score \(score.formatted(.number.precision(.fractionLength(2)))) on 0–\(max(levels - 1, 0))"
        return nearest.map { "\(base), nearest \($0)" } ?? base
    }
}

private struct ProbabilityBar: View {
    let label: String
    let probability: Double
    let highlighted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(label).font(.footnote).lineLimit(1)
                Spacer()
                Text(probability.formatted(.percent.precision(.fractionLength(0)))).font(.footnote.monospacedDigit())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule().fill(highlighted ? Color.accentColor : Color.secondary.opacity(0.5))
                        .frame(width: proxy.size.width * min(max(probability, 0), 1))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityValue(probability.formatted(.percent.precision(.fractionLength(0))))
    }
}

// MARK: - Editor

struct DecisionQuestionEditor: View {
    @Binding var question: DecisionQuestion

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $question.kind) {
                    ForEach(DecisionQuestionKind.allCases, id: \.self) { Text($0.title).tag($0) }
                }
                TextField("Name (optional)", text: $question.name)
                    .platformCapitalization(.never).autocorrectionDisabled()
                    .font(.body.monospaced())
                TextField("Instructions", text: $question.instructions, axis: .vertical).lineLimit(2...8)
            } footer: {
                Text(question.kind.summary + " Write the instructions around something you can observe in the input.")
            }

            if question.kind != .predicate {
                Section {
                    ForEach($question.options) { $option in
                        VStack(alignment: .leading) {
                            TextField(question.kind == .choice ? "Value" : "Label", text: $option.value)
                                .platformCapitalization(.never)
                            TextField("When it applies (optional)", text: $option.detail, axis: .vertical)
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { question.options.remove(atOffsets: $0) }
                    .onMove { question.options.move(fromOffsets: $0, toOffset: $1) }
                    Button {
                        question.options.append(DecisionOption(value: ""))
                    } label: {
                        Label(question.kind == .choice ? "Add Choice" : "Add Level", systemImage: "plus")
                    }
                    .disabled(question.options.count >= (question.kind == .choice ? DecisionsRequest.choiceRange : DecisionsRequest.levelRange).upperBound)
                } header: {
                    Text(question.kind == .choice ? "Choices" : "Levels, lowest first")
                } footer: {
                    Text(question.kind == .choice
                         ? "2 to 255 choices with different values. Add a fallback such as other when the choices may not cover every input."
                         : "2 to 10 levels. Level 0 is the first one; the answer is a weighted average of the level numbers.")
                }
            }
        }
        .navigationTitle(question.kind.title)
        #if !os(macOS)
        .toolbar { if question.kind != .predicate { EditButton() } }
        #endif
    }
}

#Preview("Answers") {
    // The answers from OpenAI's Decisions API reference examples, so the bars can be checked without a key.
    let result = DecisionsResult(json: [
        "model": "gpt-6-luna",
        "answers": [
            ["type": "choice", "name": "department", "choice": "billing", "confidence": 0.93,
             "probabilities": [["value": "billing", "probability": 0.95], ["value": "technical", "probability": 0.02],
                               ["value": "shipping", "probability": 0.01], ["value": "other", "probability": 0.02]]],
            ["type": "predicate", "name": "asks_for_refund", "probability": 0.92],
            ["type": "score", "name": "urgency", "score": 1.1, "confidence": 0.55,
             "probabilities": [["value": 0, "label": "Low", "probability": 0.1], ["value": 1, "label": "Medium", "probability": 0.7],
                               ["value": 2, "label": "High", "probability": 0.2]]],
            ["type": "refusal", "name": "declined_example"]
        ],
        "usage": ["input_tokens": 42, "input_tokens_details": ["cached_tokens": 0]]
    ])
    return Form {
        Section("Answers") {
            ForEach(Array(result.answers.enumerated()), id: \.offset) { index, answer in
                AnswerView(answer: answer, question: DecisionsRequest.example.questions.indices.contains(index) ? DecisionsRequest.example.questions[index] : nil)
            }
        }
    }
}
