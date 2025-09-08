import SwiftUI

/// Enhanced image view for displaying generated images with animations and improved UX
struct EnhancedImageView: View {
    let image: UIImage
    @State private var isLoaded = false
    @State private var showFullscreen = false
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            .scaleEffect(isLoaded ? 1.0 : 0.8)
            .opacity(isLoaded ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isLoaded)
            .onAppear {
                withAnimation {
                    isLoaded = true
                }
            }
            .onTapGesture {
                showFullscreen = true
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                FullscreenImageView(image: image, isPresented: $showFullscreen)
            }
            .accessibilityLabel("Generated image")
            .accessibilityHint("Tap to view fullscreen")
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
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    SimultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, min(value, 4.0))
                            },
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
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .statusBarHidden()
        .accessibilityLabel("Fullscreen image view")
        .accessibilityHint("Double tap to zoom, drag to pan, tap X to close")
    }
}

#Preview {
    EnhancedImageView(image: UIImage(systemName: "photo") ?? UIImage())
}
