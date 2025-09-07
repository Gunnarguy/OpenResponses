import SwiftUI
import PhotosUI

/// A SwiftUI wrapper for PHPickerViewController that allows users to select images
struct ImagePickerView: UIViewControllerRepresentable {
    let onImagesSelected: ([UIImage]) -> Void
    @Environment(\.dismiss) private var dismiss
    
    /// Maximum number of images that can be selected
    let selectionLimit: Int
    
    init(selectionLimit: Int = 10, onImagesSelected: @escaping ([UIImage]) -> Void) {
        self.selectionLimit = selectionLimit
        self.onImagesSelected = onImagesSelected
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard !results.isEmpty else { return }
            
            // Convert PHPickerResults to UIImages
            let group = DispatchGroup()
            var images: [UIImage] = []
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            images.append(image)
                        } else if let error = error {
                            print("Error loading image: \(error)")
                        }
                        group.leave()
                    }
                }
            }
            
            group.notify(queue: .main) {
                self.parent.onImagesSelected(images)
            }
        }
    }
}

/// A view for displaying and managing selected images before sending
struct SelectedImagesView: View {
    @Binding var images: [UIImage]
    @Binding var detailLevel: String
    let onRemove: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !images.isEmpty {
                HStack {
                    Text("Selected Images (\(images.count))")
                        .font(.headline)
                    
                    Spacer()
                    
                    // Image detail level picker
                    Picker("Detail Level", selection: $detailLevel) {
                        Text("Auto").tag("auto")
                        Text("High").tag("high")
                        Text("Low").tag("low")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 140)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(images.enumerated()), id: \.offset) { index, image in
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .cornerRadius(8)
                                
                                Button(action: {
                                    onRemove(index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Color.black.opacity(0.6))
                                        .clipShape(Circle())
                                }
                                .padding(4)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 88)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

/// Preview provider for testing
struct ImagePickerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            SelectedImagesView(
                images: .constant([UIImage(systemName: "photo")!]),
                detailLevel: .constant("auto"),
                onRemove: { _ in }
            )
        }
    }
}
