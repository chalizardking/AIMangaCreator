import Foundation

struct Character: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var referenceImageURL: URL?
    var traits: CharacterTraits
    var relationships: [String: String] // Character name -> relationship description
}

struct CharacterTraits: Codable {
    var appearance: String // Physical description
    var personality: [String] // Keywords: brave, cheerful, mysterious
    var clothingStyle: String
    var distinguishingFeatures: [String] // Scars, tattoos, unique accessories
}

struct CharacterReference: Codable {
    var characterID: UUID
    var action: String // What they're doing in this panel
    var expression: String // happy, angry, shocked, etc.
    var position: String // left, center, right
}
