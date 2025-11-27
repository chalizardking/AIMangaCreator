import Foundation

struct MangaStyle: Codable, Hashable {
    let id: UUID
    var name: String
    var genre: MangaGenre
    var description: String
    
    var artStyle: ArtStyleSettings
    var panelSettings: PanelSettings
    var colorPalette: ColorPalette
    var typography: TypographySettings
    
    // Hashable conformance for Picker
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MangaStyle, rhs: MangaStyle) -> Bool {
        lhs.id == rhs.id
    }
    
    static let allCases: [MangaStyle] = [
        MangaStyle(
            id: UUID(),
            name: "Shounen",
            genre: .shounen,
            description: "Action packed",
            artStyle: .init(lineWeight: 1.0, detailLevel: .standard, inkStyle: .digital, screenToneIntensity: 0.5),
            panelSettings: .init(borderWidth: 2, gutterWidth: 10, backgroundColor: "#FFFFFF", screentonePattern: nil),
            colorPalette: .init(colors: [], useMonochrome: true, tonalRange: .highContrast),
            typography: .init(fontName: "Anime Ace", fontSize: 12, characterSpacing: 0, lineSpacing: 0)
        ),
        MangaStyle(
            id: UUID(),
            name: "Shoujo",
            genre: .shoujo,
            description: "Romance and drama",
            artStyle: .init(lineWeight: 0.5, detailLevel: .detailed, inkStyle: .traditional, screenToneIntensity: 0.3),
            panelSettings: .init(borderWidth: 1, gutterWidth: 12, backgroundColor: "#FFF0F5", screentonePattern: "dots"),
            colorPalette: .init(colors: [], useMonochrome: false, tonalRange: .balanced),
            typography: .init(fontName: "Cookie", fontSize: 14, characterSpacing: 1, lineSpacing: 2)
        )
    ]
}

enum MangaGenre: String, Codable, CaseIterable {
    case shounen // Action/adventure for young boys
    case shoujo  // Romance for young girls
    case seinen  // Mature for adult men
    case kodomo  // Children
    case josei   // Romantic comedy for adult women
}

struct ArtStyleSettings: Codable {
    var lineWeight: Double // 0.5 to 3.0
    var detailLevel: DetailLevel // minimal, standard, detailed
    var inkStyle: InkStyle
    var screenToneIntensity: Double // 0.0 to 1.0
}

enum DetailLevel: String, Codable {
    case minimal
    case standard
    case detailed
}

enum InkStyle: String, Codable {
    case traditional // Pen and ink
    case digital     // Clean digital
    case sketchy     // Loose, expressive
}

struct PanelSettings: Codable {
    var borderWidth: Double
    var gutterWidth: Double // Space between panels
    var backgroundColor: String // Hex or named color
    var screentonePattern: String? // Crosshatch, dots, etc.
}

struct ColorPalette: Codable {
    var colors: [String] // Array of hex codes
    var useMonochrome: Bool
    var tonalRange: TonalRange
}

enum TonalRange: String, Codable {
    case highContrast
    case balanced
    case lowKey
}

struct TypographySettings: Codable {
    var fontName: String // System or custom
    var fontSize: Double
    var characterSpacing: Double
    var lineSpacing: Double
}
