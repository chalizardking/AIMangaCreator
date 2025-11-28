import SwiftUI

struct GeneratorView: View {
    @ObservedObject var viewModel: PanelGeneratorViewModel
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 16) {
            /// Prompt input
            PromptInputView(
                prompt: $viewModel.currentPrompt,
                characterGuides: viewModel.selectedCharacters
            )
            
            /// Style selector
            Picker("Manga Style", selection: $viewModel.selectedStyle) {
                ForEach(MangaStyle.allCases, id: \.self) { style in
                    Text(style.name).tag(style)
                }
            }
            
            /// Provider selector
            Picker("AI Provider", selection: $viewModel.selectedProviderType) {
                ForEach(AIProviderType.allCases) { provider in
                    Text(provider.rawValue).tag(provider)
                }
            }
            
            /// Generation button
            Button(action: { Task { await generatePanel() } }) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Panel")
                }
            }
            .disabled(isGenerating || viewModel.currentPrompt.isEmpty)
            .buttonStyle(.borderedProminent)
            
            /// Results preview
            if let generatedImage = viewModel.lastGeneratedImage {
                VStack {
                    Text("Generated Panel")
                        .font(.headline)
                    Image(nsImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func generatePanel() async {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            try await viewModel.generatePanel()
        } catch {
            viewModel.error = error as? AppError ?? .unknown(error)
        }
    }
}

struct PromptInputView: View {
    @Binding var prompt: String
    let characterGuides: [CharacterReference]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Panel Description", systemImage: "square.and.pencil")
                .font(.headline)
            
            TextEditor(text: $prompt)
                .frame(minHeight: 100)
                .border(Color.gray, width: 1)
                .cornerRadius(4)
            
            if !characterGuides.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Characters in this panel:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(characterGuides, id: \.characterID) { guide in
                        Text("• \(guide.action)")
                            .font(.caption)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
}
