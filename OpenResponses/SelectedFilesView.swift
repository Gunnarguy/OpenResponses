import SwiftUI

/// A view that displays a preview of selected files with the ability to remove them.
struct SelectedFilesView: View {
    let fileNames: [String]
    var onRemove: (Int) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(fileNames.enumerated()), id: \.offset) { index, fileName in
                    FilePreviewCard(
                        fileName: fileName,
                        onRemove: {
                            onRemove(index)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 80)
        .background(Color(UIColor.systemGray6))
    }
}

/// A card that displays a file preview with its name and a remove button.
private struct FilePreviewCard: View {
    let fileName: String
    var onRemove: () -> Void
    
    private var fileExtension: String {
        URL(fileURLWithPath: fileName).pathExtension.lowercased()
    }
    
    private var fileIcon: String {
        switch fileExtension {
        case "pdf":
            return "doc.richtext"
        case "txt", "md":
            return "doc.text"
        case "json":
            return "doc.badge.gearshape"
        case "csv":
            return "tablecells"
        case "zip", "tar", "gz":
            return "doc.zipper"
        case "rtf":
            return "doc.richtext"
        default:
            return "doc"
        }
    }
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                VStack(spacing: 4) {
                    Image(systemName: fileIcon)
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text(fileName)
                        .font(.caption2)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: 60)
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: 6, y: -6)
            }
        }
    }
}

#Preview {
    SelectedFilesView(
        fileNames: ["document.pdf", "data.csv", "report.txt"],
        onRemove: { _ in }
    )
}
