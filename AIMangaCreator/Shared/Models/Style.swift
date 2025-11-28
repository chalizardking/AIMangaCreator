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
    
    /// Hashable conformance for Picker
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MangaStyle, rhs: MangaStyle) -> Bool {
        lhs.id == rhs.id
    }
    
    static let allCases: [MangaStyle] = [
        MangaStyle(
            id: UUID(uuidString: "2862D803-8455-4F0A-8C86-AC7E4AEB8FBE")!,
            name: "Shounen",
            genre: .shounen,
            description: "Action-packed manga for young boys with dynamic storytelling",
            artStyle: .init(lineWeight: 1.0, detailLevel: .standard, inkStyle: .digital, screenToneIntensity: 0.5),
            panelSettings: .init(borderWidth: 2, gutterWidth: 10, backgroundColor: "#FFFFFF", screentonePattern: nil),
            colorPalette: .init(colors: [], useMonochrome: true, tonalRange: .highContrast),
            typography: .init(fontName: "Anime Ace", fontSize: 12, characterSpacing: 0, lineSpacing: 0)
        ),
        MangaStyle(
            id: UUID(uuidString: "3862D803-8455-4F0A-8C86-AC7E4AEB8FBF")!,
            name: "Shoujo",
            genre: .shoujo,
            description: "Romance and drama focused manga for young girls",
            artStyle: .init(lineWeight: 0.5, detailLevel: .detailed, inkStyle: .traditional, screenToneIntensity: 0.3),
            panelSettings: .init(borderWidth: 1, gutterWidth: 12, backgroundColor: "#FFF0F5", screentonePattern: "dots"),
            colorPalette: .init(colors: [], useMonochrome: false, tonalRange: .balanced),
            typography: .init(fontName: "Cookie", fontSize: 14, characterSpacing: 1, lineSpacing: 2)
        ),
        MangaStyle(
            id: UUID(uuidString: "4862D803-8455-4F0A-8C86-AC7E4AEB8FC0")!,
            name: "Seinen",
            genre: .seinen,
            description: "Complex storytelling for adult male readers",
            artStyle: .init(lineWeight: 1.5, detailLevel: .detailed, inkStyle: .traditional, screenToneIntensity: 0.4),
            panelSettings: .init(borderWidth: 2, gutterWidth: 8, backgroundColor: "#FAFAFA", screentonePattern: "crosshatch"),
            colorPalette: .init(colors: [], useMonochrome: true, tonalRange: .balanced),
            typography: .init(fontName: "Helvetica Neue", fontSize: 11, characterSpacing: 0.5, lineSpacing: 1)
        ),
        MangaStyle(
            id: UUID(uuidString: "5862D803-8455-4F0A-8C86-AC7E4AEB8FC1")!,
            name: "Kodomo",
            genre: .kodomo,
            description: "Fun and educational manga for children",
            artStyle: .init(lineWeight: 0.8, detailLevel: .minimal, inkStyle: .digital, screenToneIntensity: 0.2),
            panelSettings: .init(borderWidth: 3, gutterWidth: 15, backgroundColor: "#FFFFFF", screentonePattern: nil),
            colorPalette: .init(colors: ["#FF6B6B", "#4ECDC4", "#45B7D1", "#FFA07A", "#98D8C8"], useMonochrome: false, tonalRange: .highContrast),
            typography: .init(fontName: "Comic Sans MS", fontSize: 16, characterSpacing: 2, lineSpacing: 3)
        ),
        MangaStyle(
            id: UUID(uuidString: "6862D803-8455-4F0A-8C86-AC7E4AEB8FC2")!,
            name: "Josei",
            genre: .josei,
            description: "Sophisticated romance and drama for adult women",
            artStyle: .init(lineWeight: 1.2, detailLevel: .detailed, inkStyle: .digital, screenToneIntensity: 0.6),
            panelSettings: .init(borderWidth: 1, gutterWidth: 14, backgroundColor: "#FEF7ED", screentonePattern: "stipple"),
            colorPalette: .init(colors: [], useMonochrome: false, tonalRange: .lowKey),
            typography: .init(fontName: "Georgia", fontSize: 13, characterSpacing: 0.8, lineSpacing: 1.5)
        ),
        MangaStyle(
            id: UUID(uuidString: "7862D803-8455-4F0A-8C86-AC7E4AEB8FC3")!,
            name: "Fantasy",
            genre: .fantasy,
            description: "Magical worlds, mythical creatures, and epic adventures",
            artStyle: .init(lineWeight: 0.7, detailLevel: .detailed, inkStyle: .traditional, screenToneIntensity: 0.4),
            panelSettings: .init(borderWidth: 2, gutterWidth: 12, backgroundColor: "#E8F4FD", screentonePattern: "stipple"),
            colorPalette: .init(colors: [], useMonochrome: false, tonalRange: .balanced),
            typography: .init(fontName: "Papyrus", fontSize: 12, characterSpacing: 0.5, lineSpacing: 1.5)
        )
    ]
}

enum MangaGenre: String, Codable, CaseIterable {
    /// Action/adventure for young boys
    case shounen
    /// Romance for young girls
    case shoujo
    /// Mature for adult men
    case seinen
    /// Children
    case kodomo
    /// Romantic comedy for adult women
    case josei
    /// Magical worlds and epic adventures
    case fantasy
}

struct ArtStyleSettings: Codable {
    /// 0.5 to 3.0
    var lineWeight: Double
    /// minimal, standard, detailed
    var detailLevel: DetailLevel
    var inkStyle: InkStyle
    /// 0.0 to 1.0
    var screenToneIntensity: Double
}

enum DetailLevel: String, Codable {
    case minimal
    case standard
    case detailed
}

enum InkStyle: String, Codable {
    /// Pen and ink
    case traditional
    /// Clean digital
    case digital
    /// Loose, expressive
    case sketchy
}

struct PanelSettings: Codable {
    var borderWidth: Double
    /// Space between panels
    var gutterWidth: Double
    /// Hex or named color
    var backgroundColor: String
    /// Crosshatch, dots, etc.
    var screentonePattern: String?
}

struct ColorPalette: Codable {
    /// Array of hex codes
    var colors: [String]
    var useMonochrome: Bool
    var tonalRange: TonalRange
}

enum TonalRange: String, Codable {
    case highContrast
    case balanced
    case lowKey
}

struct TypographySettings: Codable {
    /// System or custom
    var fontName: String
    var fontSize: Double
    var characterSpacing: Double
    var lineSpacing: Double
}
