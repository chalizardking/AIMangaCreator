import Foundation
import Combine

@MainActor
class ProjectManagerViewModel: ObservableObject {
    nonisolated var objectWillChange: ObservableObjectPublisher {
        ObservableObjectPublisher()
    }
    
    @Published var projects: [Manga] = []
    @Published var selectedProject: Manga?
    @Published var error: AppError?
    @Published var isLoading = false
    
    private let repository: MangaRepository
    
    init(repository: MangaRepository = LocalMangaRepository.shared) {
        self.repository = repository
        Task {
            await loadProjects()
        }
    }
    
    func loadProjects() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            projects = try repository.listAll()
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    func createProject(title: String, style: MangaStyle) async {
        let newProject = Manga(
            id: UUID(),
            title: title,
            description: "",
            creator: NSUserName(),
            createdDate: Date(),
            modifiedDate: Date(),
            panels: [],
            characters: [],
            metadata: MangaMetadata(
                tags: [],
                genre: style.genre,
                targetAudience: "",
                status: .draft,
                notes: "",
                collaborators: [],
                style: style
            )
        )
        
        do {
            try await repository.save(newProject)
            await loadProjects()
            selectedProject = newProject
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    func deleteProject(_ project: Manga) async {
        do {
            try await repository.delete(project.id)
            await loadProjects()
            if selectedProject?.id == project.id {
                selectedProject = nil
            }
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }

    func duplicateProject(_ project: Manga) async {
        do {
            let original = try await repository.load(project.id)
            let now = Date()

            /// Duplicate characters with new IDs
            var characterIDMap: [UUID: UUID] = [:]
            let duplicatedCharacters: [Character] = original.characters.map { character in
                let newID = UUID()
                characterIDMap[character.id] = newID
                return Character(
                    id: newID,
                    name: character.name,
                    description: character.description,
                    referenceImageURL: character.referenceImageURL,
                    traits: character.traits,
                    relationships: character.relationships
                )
            }

            /// Duplicate panels and remap character references
            let duplicatedPanels: [Panel] = original.panels.enumerated().map { index, panel in
                let remappedGuides = panel.characterGuide.map { guide in
                    CharacterReference(
                        characterID: characterIDMap[guide.characterID] ?? guide.characterID,
                        action: guide.action,
                        expression: guide.expression,
                        position: guide.position
                    )
                }

                return Panel(
                    id: UUID(),
                    order: index,
                    panelType: panel.panelType,
                    prompt: panel.prompt,
                    generatedImageURL: panel.generatedImageURL,
                    characterGuide: remappedGuides,
                    dialogueBox: panel.dialogueBox,
                    soundEffect: panel.soundEffect,
                    generationStatus: panel.generatedImageURL == nil ? .pending : .cached,
                    generationProgress: panel.generationProgress,
                    estimatedTimeRemaining: panel.estimatedTimeRemaining
                )
            }

            let duplicatedProject = Manga(
                id: UUID(),
                title: "\(original.title) Copy",
                description: original.description,
                creator: original.creator,
                createdDate: now,
                modifiedDate: now,
                panels: duplicatedPanels,
                characters: duplicatedCharacters,
                metadata: original.metadata
            )

            try await repository.save(duplicatedProject)
            await loadProjects()
            selectedProject = duplicatedProject
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    func openProject(_ project: Manga) {
        selectedProject = project
    }
}
