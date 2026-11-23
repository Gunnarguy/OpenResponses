import Combine
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// The OpenResponses entry in the share sheet (3.1).
///
/// It reads what was shared (text, a web link, images, PDFs and other files), lets the person add a
/// question, and puts all of it in `SharedInbox`. The app opens it as a new chat the next time it comes
/// forward, with the text in the message field and the files attached. Nothing is sent from here: the
/// API key stays in the app's Keychain and the first-send consent stays in the app.
final class ShareViewController: UIViewController {
    private let model = ShareModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        model.finish = { [weak self] in self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil) }
        model.cancel = { [weak self] in
            self?.extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
        }
        let host = UIHostingController(rootView: ShareView(model: model))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)

        let items = (extensionContext?.inputItems as? [NSExtensionItem]) ?? []
        Task { await model.load(items) }
    }
}

// MARK: - What was shared

@MainActor
final class ShareModel: ObservableObject {
    struct Piece: Identifiable {
        let id = UUID()
        var title: String
        var systemImage: String
    }

    /// Files over this size are left out: a share extension has far less memory than the app.
    static let maxFileBytes = 25 * 1024 * 1024

    @Published var pieces: [Piece] = []
    @Published var question = ""
    @Published var isLoading = true
    @Published var skipped: [String] = []
    @Published var saved = false
    @Published var errorMessage: String?
    /// OpenResponses Pro (3.1) unlocks this sheet. The app records the purchase in the App Group; this process only reads it.
    let isUnlocked = ProAccess.isUnlocked

    var finish: () -> Void = {}
    var cancel: () -> Void = {}

    private var texts: [String] = []
    private var files: [(SharedInbox.File, Data)] = []

    var canSave: Bool { !isLoading && (!texts.isEmpty || !files.isEmpty || !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) }

    func load(_ items: [NSExtensionItem]) async {
        for item in items {
            if let text = item.attributedContentText?.string.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
                add(text: text)
            }
            for provider in item.attachments ?? [] {
                await load(provider)
            }
        }
        isLoading = false
    }

    private func load(_ provider: NSItemProvider) async {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
           !provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let url = await loadObject(provider, as: URL.self) {
            add(text: url.absoluteString, title: url.host() ?? url.absoluteString, image: "link")
            return
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier),
           let (data, name) = await loadFile(provider, type: .image) {
            add(file: .init(name: name, kind: .image), data: data, image: "photo")
            return
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
           !provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier),
           let text = await loadObject(provider, as: String.self) {
            add(text: text)
            return
        }
        if let (data, name) = await loadFile(provider, type: .item) {
            let isPDF = UTType(filenameExtension: (name as NSString).pathExtension)?.conforms(to: .pdf) == true
            add(file: .init(name: name, kind: .file), data: data, image: isPDF ? "doc.richtext" : "doc")
        }
    }

    private func add(text: String, title: String? = nil, image: String = "text.quote") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !texts.contains(trimmed) else { return }
        texts.append(trimmed)
        pieces.append(Piece(title: title ?? String(trimmed.prefix(120)), systemImage: image))
    }

    private func add(file: SharedInbox.File, data: Data, image: String) {
        guard data.count <= Self.maxFileBytes else {
            skipped.append(file.name)
            return
        }
        files.append((file, data))
        pieces.append(Piece(title: file.name, systemImage: image))
    }

    func save() {
        guard isUnlocked else { errorMessage = ProAccess.Feature.shareSheet.lockedMessage; return }
        let note = question.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = ([note] + texts).filter { !$0.isEmpty }.joined(separator: "\n\n")
        do {
            try SharedInbox.shared.deliver(text: text, files: files, source: "share")
            saved = true
        } catch {
            errorMessage = "Could not save for OpenResponses: \(error.localizedDescription)"
        }
    }

    // MARK: Loading from item providers

    private func loadObject<T: _ObjectiveCBridgeable>(_ provider: NSItemProvider, as type: T.Type) async -> T? where T._ObjectiveCType: NSItemProviderReading {
        await withCheckedContinuation { continuation in
            _ = provider.loadObject(ofClass: type) { value, _ in continuation.resume(returning: value) }
        }
    }

    private func loadFile(_ provider: NSItemProvider, type: UTType) async -> (Data, String)? {
        await withCheckedContinuation { continuation in
            _ = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
                guard let url, let data = try? Data(contentsOf: url) else {
                    continuation.resume(returning: nil)
                    return
                }
                var name = provider.suggestedName ?? url.lastPathComponent
                if (name as NSString).pathExtension.isEmpty, !url.pathExtension.isEmpty {
                    name += ".\(url.pathExtension)"
                }
                continuation.resume(returning: (data, name))
            }
        }
    }
}

// MARK: - The sheet

struct ShareView: View {
    @ObservedObject var model: ShareModel
    @FocusState private var questionFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                if !model.isUnlocked {
                    Section {
                        Label("OpenResponses Pro", systemImage: "lock.fill")
                            .font(.headline)
                        Text(ProAccess.Feature.shareSheet.lockedMessage)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else if model.saved {
                    Section {
                        Label("Saved for a new chat", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Open OpenResponses: it starts a new chat with this in the message field, ready to send. Nothing has been sent yet.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        TextField("Add a question (optional)", text: $model.question, axis: .vertical)
                            .lineLimit(2...6)
                            .focused($questionFocused)
                    } footer: {
                        Text("This opens as a new chat in OpenResponses. Nothing is sent until you tap Send there.")
                    }
                    Section("Shared") {
                        if model.isLoading {
                            ProgressView()
                        } else if model.pieces.isEmpty {
                            Text("Nothing here OpenResponses can read.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(model.pieces) { piece in
                            Label {
                                Text(piece.title).lineLimit(3)
                            } icon: {
                                Image(systemName: piece.systemImage)
                            }
                        }
                        ForEach(model.skipped, id: \.self) { name in
                            Label("\(name) is over 25 MB, left out", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                    if let error = model.errorMessage {
                        Section { Text(error).foregroundStyle(.red) }
                    }
                }
            }
            .navigationTitle("OpenResponses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !model.isUnlocked {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { model.cancel() }
                    }
                } else if model.saved {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { model.finish() }
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { model.cancel() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { model.save() }
                            .disabled(!model.canSave)
                    }
                }
            }
        }
    }
}
