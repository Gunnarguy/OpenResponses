import SwiftUI

/// View that shows image generation suggestions and quick prompts
struct ImageSuggestionView: View {
    @Binding var inputText: String
    let onSuggestionTap: (String) -> Void
    
    private let suggestions = [
        "Generate an image of a sunset over mountains",
        "Create a minimalist logo design",
        "Draw a cute cartoon animal",
        "Make an abstract art piece",
        "Generate a futuristic cityscape",
        "Create a beautiful landscape painting"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo.badge.plus")
                    .foregroundColor(.blue)
                Text("Image Generation Suggestions")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.bottom, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTap(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#Preview {
    ImageSuggestionView(inputText: .constant("")) { suggestion in
        print("Selected: \(suggestion)")
    }
}
