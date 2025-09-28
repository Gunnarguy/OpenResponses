import SwiftUI

/// Enhanced image view for displaying generated images with animations and improved UX
struct EnhancedImageView: View {
    let image: UIImage
    @State private var isLoaded = false
    @State private var showFullscreen = false
    @State private var lastSavedPath: String? = nil
    private var maxDisplayWidth: CGFloat {
        min(UIScreen.main.bounds.width * 0.70, 360)
    }
    
    /// Reconstructs the UIImage to ensure it has a valid CGImage for robust rendering
    private func reconstructedImage() -> UIImage {
        // If the image already has a CGImage, return it as-is
        if image.cgImage != nil {
            return image
        }
        
        // If no CGImage, reconstruct from PNG data to ensure proper rendering
        guard let data = image.pngData(),
              let reconstructed = UIImage(data: data) else {
            // Fallback: create a simple placeholder if reconstruction fails
            let size = CGSize(width: max(image.size.width, 100), height: max(image.size.height, 100))
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.systemGray4.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
        }
        
        return reconstructed
    }
    
    /// Save the current image as PNG to the app's Documents directory for debugging visibility issues.
    private func savePNGDebug() {
        guard let data = image.pngData() else {
            return
        }
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filename = "screenshot_\(Int(Date().timeIntervalSince1970)).png"
        let url = docs.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            lastSavedPath = url.path
        } catch {
            // Silent failure for debug function
        }
    }
    
    var body: some View {
        let displayImage = reconstructedImage()
        
        return VStack(spacing: 4) {
            // Compute an explicit display size to avoid collapsed heights in complex layouts
            let displayWidth = maxDisplayWidth
            let heightRatio = max(0.1, displayImage.size.height / max(displayImage.size.width, 0.1))
            let displayHeight = displayWidth * heightRatio
            
            Image(uiImage: displayImage)
                .renderingMode(.original)
                .resizable()
                // If the source is extremely small (like a 3x3 placeholder), avoid smoothing
                .interpolation(displayImage.size.width < 50 || displayImage.size.height < 50 ? Image.Interpolation.none : Image.Interpolation.medium)
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: displayWidth, maxHeight: displayHeight)
                .clipped()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .scaleEffect(isLoaded ? 1.0 : 0.8)
                .opacity(isLoaded ? 1.0 : 0.0)
                .animation(Animation.spring(response: 0.6, dampingFraction: 0.8), value: isLoaded)
                .onAppear {
                    withAnimation { isLoaded = true }
                }
                .onTapGesture {
                    showFullscreen = true
                }
                .fullScreenCover(isPresented: $showFullscreen) {
                    FullscreenImageView(image: displayImage, isPresented: $showFullscreen)
                }
                .accessibilityLabel("Generated image")
                .accessibilityHint("Tap to view fullscreen")
                .contextMenu {
                    Button("Save PNG to Documents (debug)") { savePNGDebug() }
                    if let path = lastSavedPath {
                        Text("Saved: \(path)").font(.caption2)
                    }
                }
        }
    }
}

/// Fullscreen image viewer with zoom and pan capabilities
struct FullscreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .renderingMode(.original)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = max(1.0, min(value, 5.0))
                        }
                        .simultaneously(with:
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                )
                .onTapGesture(count: 2) {
                    withAnimation(.spring()) {
                        if scale > 1.0 {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        } else {
                            scale = 2.0
                        }
                    }
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                Spacer()
            }
        }
    }
}
