import Foundation

@MainActor
class ProjectManagerViewModel: ObservableObject {
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
                title: title,
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
    
    func openProject(_ project: Manga) {
        selectedProject = project
    }
}
