import Foundation

protocol MangaRepository {
    func save(_ manga: Manga) async throws
    func load(_ id: UUID) async throws -> Manga
    func listAll() throws -> [Manga]
    func delete(_ id: UUID) async throws
}

/// Concrete implementation using ProjectService
class LocalMangaRepository: MangaRepository {
    static let shared = LocalMangaRepository()
    private let service = ProjectService.shared
    
    func save(_ manga: Manga) async throws {
        try service.save(manga)
    }
    
    func load(_ id: UUID) async throws -> Manga {
        try service.load(projectID: id)
    }
    
    func listAll() throws -> [Manga] {
        try service.listProjects()
    }
    
    func delete(_ id: UUID) async throws {
        try service.delete(projectID: id)
    }
}
