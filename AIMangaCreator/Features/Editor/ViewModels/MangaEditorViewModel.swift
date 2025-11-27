import Foundation
import Combine
import SwiftUI

@MainActor
class MangaEditorViewModel: NSObject, ObservableObject {
    @Published var manga: Manga
    @Published var error: AppError?
    @Published var isSaving = false
    @Published var undoManager = UndoManager()
    @Published var selectedProviderType: AIProviderType = .openAI {
        didSet {
            updateProvider()
        }
    }
    
    private let repository: MangaRepository
    private var aiProvider: AIProvider
    
    // Initialization
    init(
        manga: Manga,
        repository: MangaRepository = LocalMangaRepository.shared
    ) {
        self.manga = manga
        self.repository = repository
        self.aiProvider = OpenAIProvider(apiKey: Config.openAIKey)
        super.init()
    }
    
    private func updateProvider() {
        switch selectedProviderType {
        case .openAI:
            self.aiProvider = OpenAIProvider(apiKey: Config.openAIKey)
        case .gemini:
            self.aiProvider = GeminiProvider(apiKey: Config.geminiKey)
        case .openRouter:
            self.aiProvider = OpenRouterProvider(apiKey: Config.openRouterKey)
        }
    }
    
    // MARK: - Panel Management
    func addPanel(after panelID: UUID? = nil) {
        let newPanel = Panel(
            id: UUID(),
            order: manga.panels.count,
            panelType: .quarterPage,
            prompt: "",
            generatedImageURL: nil,
            characterGuide: [],
            dialogueBox: nil,
            soundEffect: nil,
            generationStatus: .pending
        )
        
        if let afterID = panelID,
           let index = manga.panels.firstIndex(where: { $0.id == afterID }) {
            manga.panels.insert(newPanel, at: index + 1)
        } else {
            manga.panels.append(newPanel)
        }
        
        updatePanelOrders()
        
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                target.removePanel(newPanel.id)
            }
        }
    }
    
    func removePanel(_ id: UUID) {
        guard let index = manga.panels.firstIndex(where: { $0.id == id }) else { return }
        let removed = manga.panels.remove(at: index)
        
        updatePanelOrders()
        
        undoManager.registerUndo(withTarget: self) { target in
            Task { @MainActor in
                // This is a simplified undo, ideally we restore the exact panel object
                // For now, we just add a new one or we should capture 'removed'
                // But 'removed' is a struct, so it's copied.
                target.restorePanel(removed, at: index)
            }
        }
    }
    
    func restorePanel(_ panel: Panel, at index: Int) {
        if index <= manga.panels.count {
            manga.panels.insert(panel, at: index)
            updatePanelOrders()
        }
    }
    
    func reorderPanels(from: IndexSet, to: Int) {
        manga.panels.move(fromOffsets: from, toOffset: to)
        updatePanelOrders()
    }
    
    func updatePanel(_ panel: Panel) {
        if let index = manga.panels.firstIndex(where: { $0.id == panel.id }) {
            manga.panels[index] = panel
        }
    }
    
    private func updatePanelOrders() {
        for (index, _) in manga.panels.enumerated() {
            manga.panels[index].order = index
        }
    }
    
    // MARK: - Generation
    func generatePanel(_ panelID: UUID) async {
        guard var panel = manga.panels.first(where: { $0.id == panelID }) else { return }
        
        panel.generationStatus = .generating
        updatePanel(panel)
        
        do {
            let generatedImage = try await aiProvider.generateImage(
                prompt: panel.prompt,
                style: manga.metadata.style,
                characterGuides: panel.characterGuide
            )
            
            panel.generatedImageURL = generatedImage.imageURL
            panel.generationStatus = .completed
            updatePanel(panel)
        } catch {
            panel.generationStatus = .failed(error.localizedDescription)
            self.error = error as? AppError ?? .unknown(error)
            updatePanel(panel)
        }
    }
    
    func generateBatch(panelIDs: [UUID]) async {
        for panelID in panelIDs {
            await generatePanel(panelID)
        }
    }
    
    // MARK: - Persistence
    func save() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await repository.save(manga)
            manga.modifiedDate = Date()
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    func autoSave() async {
        // Debounced auto-save every 30 seconds
        try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
        await save()
    }
}

// MARK: - Undo/Redo Support
extension MangaEditorViewModel {
    func undo() {
        undoManager.undo()
    }
    
    func redo() {
        undoManager.redo()
    }
    
    var canUndo: Bool {
        undoManager.canUndo
    }
    
    var canRedo: Bool {
        undoManager.canRedo
    }
}
