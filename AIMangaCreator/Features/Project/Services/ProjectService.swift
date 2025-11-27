import Foundation

class ProjectService {
    static let shared = ProjectService()
    
    private let fileManager = FileManager.default
    private lazy var projectsDirectory: URL = {
        guard let appSupportDir = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            fatalError("Failed to access Application Support directory")
        }
        
        let projectsDir = appSupportDir.appendingPathComponent("AIMangaCreator/Projects")
        try! fileManager.createDirectory(
            at: projectsDir,
            withIntermediateDirectories: true
        )
        return projectsDir
    }()
    
    func save(_ manga: Manga) throws {
        let projectDir = projectsDirectory.appendingPathComponent(manga.id.uuidString)
        try fileManager.createDirectory(at: projectDir, withIntermediateDirectories: true)
        
        // Save metadata
        let metadataPath = projectDir.appendingPathComponent("metadata.json")
        // Update metadata with current manga properties
        var metadata = manga.metadata
        metadata.title = manga.title
        metadata.description = manga.description
        metadata.creator = manga.creator
        metadata.createdDate = manga.createdDate
        metadata.modifiedDate = manga.modifiedDate
        metadata.characters = manga.characters
        
        let jsonData = try JSONEncoder().encode(metadata)
        try jsonData.write(to: metadataPath)
        
        // Save panels with images
        let panelsDir = projectDir.appendingPathComponent("panels")
        try fileManager.createDirectory(at: panelsDir, withIntermediateDirectories: true)
        
        for (index, panel) in manga.panels.enumerated() {
            let panelDir = panelsDir.appendingPathComponent("\(index)")
            try fileManager.createDirectory(at: panelDir, withIntermediateDirectories: true)
            
            // Save panel data
            let panelPath = panelDir.appendingPathComponent("panel.json")
            let panelJSON = try JSONEncoder().encode(panel)
            try panelJSON.write(to: panelPath)
            
            // Copy image if exists
            if let imageURL = panel.generatedImageURL {
                let destPath = panelDir.appendingPathComponent("image.png")
                // Only copy if it's not already there
                if imageURL.path != destPath.path {
                    if fileManager.fileExists(atPath: destPath.path) {
                        try fileManager.removeItem(at: destPath)
                    }
                    try fileManager.copyItem(at: imageURL, to: destPath)
                }
            }
        }
    }
    
    func load(projectID: UUID) throws -> Manga {
        let projectDir = projectsDirectory.appendingPathComponent(projectID.uuidString)
        
        let metadataPath = projectDir.appendingPathComponent("metadata.json")
        let metadataData = try Data(contentsOf: metadataPath)
        let metadata = try JSONDecoder().decode(MangaMetadata.self, from: metadataData)
        
        // Load panels
        let panelsDir = projectDir.appendingPathComponent("panels")
        let panelDirs = try fileManager.contentsOfDirectory(
            at: panelsDir,
            includingPropertiesForKeys: nil
        ).sorted { 
            ($0.lastPathComponent as NSString).integerValue <
            ($1.lastPathComponent as NSString).integerValue
        }
        
        var panels: [Panel] = []
        for panelDir in panelDirs {
            let panelPath = panelDir.appendingPathComponent("panel.json")
            let panelData = try Data(contentsOf: panelPath)
            var panel = try JSONDecoder().decode(Panel.self, from: panelData)
            
            let imagePath = panelDir.appendingPathComponent("image.png")
            if fileManager.fileExists(atPath: imagePath.path) {
                panel.generatedImageURL = imagePath
            }
            
            panels.append(panel)
        }
        
        return Manga(
            id: projectID,
            title: metadata.title ?? "Untitled",
            description: metadata.description ?? "",
            creator: metadata.creator ?? "Unknown",
            createdDate: metadata.createdDate ?? Date(),
            modifiedDate: metadata.modifiedDate ?? Date(),
            panels: panels,
            characters: metadata.characters ?? [],
            metadata: metadata
        )
    }
    
    func listProjects() throws -> [Manga] {
        let projectDirs = try fileManager.contentsOfDirectory(
            at: projectsDirectory,
            includingPropertiesForKeys: nil
        )
        
        var projects: [Manga] = []
        for projectDir in projectDirs {
            if let uuid = UUID(uuidString: projectDir.lastPathComponent),
               let manga = try? load(projectID: uuid) {
                projects.append(manga)
            }
        }
        
        return projects.sorted { $0.modifiedDate > $1.modifiedDate }
    }
    
    func delete(projectID: UUID) throws {
        let projectDir = projectsDirectory.appendingPathComponent(projectID.uuidString)
        try fileManager.removeItem(at: projectDir)
    }
}
