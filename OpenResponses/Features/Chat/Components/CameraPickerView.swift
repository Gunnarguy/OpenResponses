import SwiftUI
import UIKit

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

// MARK: - Preview

#Preview {
    Text("Camera Preview")
        .sheet(isPresented: .constant(true)) {
            if isCameraAvailable() {
                CameraPickerView { image in
                    print("Captured image: \(image.size)")
                }
            } else {
                Text("Camera not available on this device")
            }
        }
}
