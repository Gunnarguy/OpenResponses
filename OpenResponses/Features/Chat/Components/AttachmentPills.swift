import SwiftUI

/// Playground-style attachment pills showing files and images with dismiss buttons
/// Compact, dismissible chips below the input field
struct AttachmentPills: View {
    @EnvironmentObject private var viewModel: ChatViewModel
    
    var body: some View {
        if !viewModel.pendingFileData.isEmpty || !viewModel.pendingImageAttachments.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // File pills
                    ForEach(Array(zip(viewModel.pendingFileData.indices, viewModel.pendingFileNames)), id: \.0) { index, name in
                        FilePill(
                            fileName: name,
                            onRemove: {
                                removeFile(at: index)
                            }
                        )
                    }
                    
                    // Image pills
                    ForEach(viewModel.pendingImageAttachments.indices, id: \.self) { index in
                        ImagePill(
                            image: viewModel.pendingImageAttachments[index],
                            onRemove: {
                                removeImage(at: index)
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color.secondary.opacity(0.05))
        }
    }
    
    // MARK: - Remove Actions
    
    private func removeFile(at index: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.pendingFileData.remove(at: index)
            viewModel.pendingFileNames.remove(at: index)
        }
    }
    
    private func removeImage(at index: Int) {
        _ = withAnimation(.easeInOut(duration: 0.2)) {
            viewModel.pendingImageAttachments.remove(at: index)
        }
    }
}

// MARK: - File Pill

struct FilePill: View {
    let fileName: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: fileIcon)
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(fileName)
                .font(.caption)
                .lineLimit(1)
                .frame(maxWidth: 150)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var fileIcon: String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "pdf":
            return "doc.fill"
        case "txt", "md":
            return "doc.text.fill"
        case "jpg", "jpeg", "png", "gif":
            return "photo.fill"
        case "zip", "tar", "gz":
            return "doc.zipper"
        case "py", "swift", "js", "ts":
            return "chevron.left.forwardslash.chevron.right"
        case "json", "xml":
            return "doc.badge.gearshape"
        default:
            return "doc.fill"
        }
    }
}

// MARK: - Image Pill

struct ImagePill: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 6) {
            // Show thumbnail
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            
            Text("Image")
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack {
        AttachmentPills()
            .environmentObject({
                let vm = ChatViewModel(api: OpenAIService())
                vm.pendingFileData = [Data(), Data()]
                vm.pendingFileNames = ["document.pdf", "code.swift"]
                vm.pendingImageAttachments = [UIImage(systemName: "photo")!]
                return vm
            }())
        
        Spacer()
    }
}
