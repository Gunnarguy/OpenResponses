import SwiftUI

/// Compatibility entry point for existing navigation routes.
struct MCPConnectorGalleryView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            MCPConnectionsView(viewModel: viewModel)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
}
