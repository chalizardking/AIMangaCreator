import Foundation

struct Character: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var referenceImageURL: URL?
    var traits: CharacterTraits
    /// Character name -> relationship description
    var relationships: [String: String]
}

struct CharacterTraits: Codable {
    /// Physical description
    var appearance: String
    /// Keywords: brave, cheerful, mysterious
    var personality: [String]
    var clothingStyle: String
    /// Scars, tattoos, unique accessories
    var distinguishingFeatures: [String]
}

struct CharacterReference: Codable {
    var characterID: UUID
    /// What they're doing in this panel
    var action: String
    /// happy, angry, shocked, etc.
    var expression: String
    /// left, center, right
    var position: String
}

// MARK: - Protocol Conformances
extension Character: Equatable, Hashable {
    static func == (lhs: Character, rhs: Character) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension CharacterTraits: Equatable, Hashable { }

extension CharacterReference: Equatable, Hashable { }
