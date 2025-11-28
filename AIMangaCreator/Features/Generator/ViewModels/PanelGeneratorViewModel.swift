import Foundation
import AppKit
import Combine

@MainActor
class PanelGeneratorViewModel: ObservableObject {

    @Published var currentPrompt: String = ""
    @Published var selectedStyle: MangaStyle = MangaStyle.allCases.first!
    @Published var selectedCharacters: [CharacterReference] = []
    @Published var lastGeneratedImage: NSImage?
    @Published var generationProgress: Double = 0.0
    @Published var error: AppError?
    @Published var selectedProviderType: AIProviderType = .openAI {
        didSet {
            updateProvider()
        }
    }
    
    private var aiProvider: AIProvider
    private let factory: AIProviderFactory

    init(factory: AIProviderFactory = AIProviderFactory()) {
        self.factory = factory
        self.aiProvider = factory.provider(for: .openAI)
    }
    
    private func updateProvider() {
        self.aiProvider = factory.provider(for: selectedProviderType)
    }
    
    @MainActor
    func generatePanel() async {
        guard !currentPrompt.isEmpty else {
            self.error = .invalidInput("Prompt cannot be empty")
            return
        }
        
        generationProgress = 0.0
        
        do {
            let generatedImage = try await aiProvider.generateImage(
                prompt: currentPrompt,
                style: selectedStyle,
                characterGuides: selectedCharacters
            )
            
            self.lastGeneratedImage = NSImage(data: generatedImage.imageData)
            self.generationProgress = 1.0
            
            /// TODO: Uncomment when Logger is implemented
            /// Logger.info("Panel generated in \(Date().timeIntervalSince(startTime))s")
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    @MainActor
    func refinePrompt() async {
        guard !currentPrompt.isEmpty else { return }
        
        do {
            let refined = try await aiProvider.refinePrompt(
                original: currentPrompt,
                style: selectedStyle,
                context: selectedCharacters.map { $0.action }.joined(separator: ", ")
            )
            self.currentPrompt = refined
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
}
