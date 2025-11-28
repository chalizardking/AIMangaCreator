import Foundation

class ProjectService {
    nonisolated(unsafe) static let shared = ProjectService()
    
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
        
        /// Save manga
        let metadataPath = projectDir.appendingPathComponent("metadata.json")
        let jsonData = try JSONEncoder().encode(manga)
        try jsonData.write(to: metadataPath)
        
        /// Save panels with images
        let panelsDir = projectDir.appendingPathComponent("panels")
        try fileManager.createDirectory(at: panelsDir, withIntermediateDirectories: true)
        
        for (index, panel) in manga.panels.enumerated() {
            let panelDir = panelsDir.appendingPathComponent("\(index)")
            try fileManager.createDirectory(at: panelDir, withIntermediateDirectories: true)
            
            /// Save panel data
            let panelPath = panelDir.appendingPathComponent("panel.json")
            let panelJSON = try JSONEncoder().encode(panel)
            try panelJSON.write(to: panelPath)
            
            /// Copy image if exists
            if let imageURL = panel.generatedImageURL {
                let destPath = panelDir.appendingPathComponent("image.png")
                /// Only copy if it's not already there
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
        var manga = try JSONDecoder().decode(Manga.self, from: metadataData)

        /// Load panels with images
        let panelsDir = projectDir.appendingPathComponent("panels")
        if fileManager.fileExists(atPath: panelsDir.path) {
            let panelDirs = try fileManager.contentsOfDirectory(
                at: panelsDir,
                includingPropertiesForKeys: nil
            ).compactMap { url -> (URL, Int)? in
                guard let panelNumber = Int(url.lastPathComponent) else {
                    print("Warning: Skipping non-numeric panel directory: \(url.lastPathComponent)")
                    return nil
                }
                return (url, panelNumber)
            }.sorted { $0.1 < $1.1 }
             .map { $0.0 }

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
            manga.panels = panels
        }

        return manga
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
