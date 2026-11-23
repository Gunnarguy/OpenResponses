import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if os(macOS)
/// The Mac has no photo-taking picker; the chat hides the camera there, and this stands in so the shared code builds.
struct CameraPickerView: View {
    let onImageCaptured: (UIImage) -> Void
    var body: some View { EmptyView() }
}

func isCameraAvailable() -> Bool { false }
#else
/// A SwiftUI wrapper for UIImagePickerController to capture photos using the camera
struct CameraPickerView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView

        init(_ parent: CameraPickerView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.dismiss()

            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

/// Check if camera is available on the device
func isCameraAvailable() -> Bool {
    UIImagePickerController.isSourceTypeAvailable(.camera)
}

#endif

#if !os(macOS)
// MARK: - Preview

#Preview {
    Text("Camera Preview")
        .sheet(isPresented: .constant(true)) {
            Group {
                if isCameraAvailable() {
                    CameraPickerView { image in
                        print("Captured image: \(image.size)")
                    }
                } else {
                    Text("Camera not available on this device")
                }
            }
            .macSheetFrame(width: 560, height: 620)
        }
}
#endif
