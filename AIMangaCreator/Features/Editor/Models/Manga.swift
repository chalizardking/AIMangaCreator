import Foundation

/// Core project structure
struct Manga: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var creator: String
    var createdDate: Date
    var modifiedDate: Date
    
    var panels: [Panel]
    var characters: [Character]
    var metadata: MangaMetadata
    
    /// Computed properties
    var panelCount: Int { panels.count }
    /// 4 panels per page standard
    var totalPages: Int { (panelCount + 3) / 4 }
    
    static let preview = Manga(
        id: UUID(),
        title: "Preview Manga",
        description: "A preview project",
        creator: "User",
        createdDate: Date(),
        modifiedDate: Date(),
        panels: [],
        characters: [],
        metadata: MangaMetadata(
            tags: [],
            genre: .shounen,
            targetAudience: "Teens",
            status: .draft,
            notes: "",
            collaborators: [],
            style: MangaStyle.allCases.first!
        )
    )
}

struct Panel: Codable, Identifiable {
    let id: UUID
    var order: Int
    var panelType: PanelLayout
    
    var prompt: String
    var generatedImageURL: URL?
    var characterGuide: [CharacterReference]
    var dialogueBox: DialogueBox?
    var soundEffect: String?
    
    var generationStatus: GenerationStatus
    var generationProgress: Double = 0.0
    var estimatedTimeRemaining: TimeInterval?
    
    mutating func updateProgress(_ progress: Double) {
        self.generationProgress = min(max(progress, 0.0), 1.0)
    }
}

enum PanelLayout: String, Codable {
    case fullPage
    case halfPage
    case thirdPage
    case quarterPage
    case wideStrip
}

enum GenerationStatus: Codable, Equatable {
    case pending
    case generating
    case completed
    case failed(String)
    case cached
    
    enum CodingKeys: String, CodingKey {
        case type, payload
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "pending": self = .pending
        case "generating": self = .generating
        case "completed": self = .completed
        case "failed":
            let payload = try container.decode(String.self, forKey: .payload)
            self = .failed(payload)
        case "cached": self = .cached
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .pending: try container.encode("pending", forKey: .type)
        case .generating: try container.encode("generating", forKey: .type)
        case .completed: try container.encode("completed", forKey: .type)
        case .failed(let reason):
            try container.encode("failed", forKey: .type)
            try container.encode(reason, forKey: .payload)
        case .cached: try container.encode("cached", forKey: .type)
        }
    }
}

struct DialogueBox: Codable {
    var character: String
    var text: String
    var position: DialoguePosition
    var style: DialogueStyle
}

enum DialoguePosition: String, Codable {
    case topLeft, topCenter, topRight
    case middleLeft, middleCenter, middleRight
    case bottomLeft, bottomCenter, bottomRight
}

enum DialogueStyle: String, Codable {
    case speechBubble
    case thinkBubble
    case narratorBox
}

struct MangaMetadata: Codable {
    var tags: [String]
    var genre: MangaGenre
    var targetAudience: String
    var status: ProjectStatus
    var notes: String
    var collaborators: [Collaborator]
    var style: MangaStyle
}

struct Collaborator: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
    var role: CollaboratorRole
    var addedDate: Date
}

enum CollaboratorRole: String, Codable {
    case creator
    case editor
    case contributor
    case viewer
}

enum ProjectStatus: String, Codable {
    case draft
    case inProgress
    case inReview
    case published
    case archived
}
