# AI Manga Creator — Developer Documentation

**Version:** 1.0  
**Platform:** macOS 12.0+  
**Xcode:** 15.0+  
**Swift:** 5.9+  
**Last Updated:** November 2025

---

## TABLE OF CONTENTS
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Project Structure](#project-structure)
4. [Setup & Build](#setup--build)
5. [Core Components](#core-components)
6. [AI Integration](#ai-integration)
7. [Data Models](#data-models)
8. [UI Framework](#ui-framework)
9. [State Management](#state-management)
10. [File I/O & Persistence](#file-io--persistence)
11. [Testing Strategy](#testing-strategy)
12. [Performance Optimization](#performance-optimization)
13. [Deployment](#deployment)

---

## PROJECT OVERVIEW

### Purpose
AI Manga Creator is a native macOS application that generates manga-style comic sequences from natural language prompts. Users provide story descriptions, character details, and panel layouts; the app leverages vision-language models to generate consistent artwork, apply manga-specific styling, and manage serialization.

### Key Features
- **Prompt-to-Panel Generation:** Convert text descriptions into manga panels
- **Character Consistency:** Maintain character appearance across panels
- **Batch Processing:** Generate multiple panels/pages in sequence
- **Style Library:** Apply predefined manga art styles (shounen, shoujo, seinen, kodomo)
- **Panel Management:** Reorder, delete, edit, and organize panels
- **Export:** Save as PDF, PNG sequences, or project bundles
- **Project Management:** Create, open, save, and organize manga projects

### Target Users
- Manga enthusiasts without drawing skills
- Content creators developing story outlines
- Small publishers prototyping serialized content
- Writers/artists collaborating on visual narratives

### Success Metrics
- Panel generation latency <30 seconds (GPU-accelerated)
- Support for 50+ panel projects without UI lag
- Export quality at 300 DPI minimum for print
- Zero data loss on unexpected shutdown

---

## ARCHITECTURE

### Design Pattern: MVVM + Repository Pattern
```
┌─────────────┐
│   SwiftUI   │ (View Layer)
└──────┬──────┘
       │
┌──────▼──────────────┐
│  ViewModel Layer    │ (Business Logic, State)
│  - MangaEditorVM    │
│  - PanelGeneratorVM │
│  - ProjectManagerVM │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│ Repository Layer    │ (Data Access Abstraction)
│  - MangaRepository  │
│  - AIServiceRepo    │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│  Services Layer     │ (External APIs)
│  - AIProvider       │ (OpenAI/Claude/Stable Diffusion)
│  - FileManager      │ (Local I/O)
│  - CacheManager     │ (Performance)
└─────────────────────┘
```

### Key Design Principles
1. **Separation of Concerns:** UI, business logic, and data persistence are isolated
2. **Reactive Programming:** SwiftUI state drives UI updates; ViewModels emit state changes
3. **Dependency Injection:** Services injected into ViewModels for testability
4. **Error Handling:** Structured error types with user-facing messages
5. **Async/Await:** Modern Swift concurrency for API calls and file I/O

---

## PROJECT STRUCTURE

```
AIMangaCreator/
├── AIMangaCreator.xcodeproj/
│   └── (Xcode configuration)
├── AIMangaCreator/
│   ├── App/
│   │   ├── AIMangaCreatorApp.swift (Entry point)
│   │   ├── AppDelegate.swift (macOS lifecycle)
│   │   └── Scenes/
│   │       ├── MainWindow.swift
│   │       ├── LaunchScreen.swift
│   │       └── SettingsView.swift
│   ├── Features/
│   │   ├── Editor/
│   │   │   ├── Views/
│   │   │   │   ├── MangaEditorView.swift
│   │   │   │   ├── PanelGridView.swift
│   │   │   │   ├── PanelDetailView.swift
│   │   │   │   └── PropertyInspector.swift
│   │   │   ├── ViewModels/
│   │   │   │   ├── MangaEditorViewModel.swift
│   │   │   │   └── PanelViewModel.swift
│   │   │   └── Models/
│   │   │       ├── Panel.swift
│   │   │       └── Manga.swift
│   │   ├── Generator/
│   │   │   ├── Views/
│   │   │   │   ├── GeneratorView.swift
│   │   │   │   ├── PromptInputView.swift
│   │   │   │   └── GenerationProgressView.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── PanelGeneratorViewModel.swift
│   │   │   └── Services/
│   │   │       ├── AIProvider.swift
│   │   │       └── ImageStyler.swift
│   │   ├── Project/
│   │   │   ├── Views/
│   │   │   │   ├── ProjectBrowserView.swift
│   │   │   │   ├── ProjectDetailView.swift
│   │   │   │   └── NewProjectSheet.swift
│   │   │   ├── ViewModels/
│   │   │   │   └── ProjectManagerViewModel.swift
│   │   │   └── Services/
│   │   │       ├── ProjectService.swift
│   │   │       └── FileManager+Extensions.swift
│   │   └── Export/
│   │       ├── Views/
│   │       │   └── ExportView.swift
│   │       ├── ViewModels/
│   │       │   └── ExportViewModel.swift
│   │       └── Services/
│   │           ├── PDFExporter.swift
│   │           ├── ImageSequenceExporter.swift
│   │           └── ProjectBundleExporter.swift
│   ├── Shared/
│   │   ├── Models/
│   │   │   ├── Character.swift
│   │   │   ├── Style.swift
│   │   │   ├── ExportFormat.swift
│   │   │   └── AppError.swift
│   │   ├── Utilities/
│   │   │   ├── Logger.swift
│   │   │   ├── ImageProcessor.swift
│   │   │   ├── URLExtensions.swift
│   │   │   └── StringExtensions.swift
│   │   ├── Extensions/
│   │   │   ├── View+Modifiers.swift
│   │   │   ├── Image+Utilities.swift
│   │   │   └── NSImage+Utilities.swift
│   │   └── Constants/
│   │       ├── AppConstants.swift
│   │       ├── APIConstants.swift
│   │       └── UIConstants.swift
│   ├── Resources/
│   │   ├── Assets.xcassets/
│   │   ├── Styles/
│   │   │   ├── style_shounen.json
│   │   │   ├── style_shoujo.json
│   │   │   ├── style_seinen.json
│   │   │   └── style_kodomo.json
│   │   └── Localizable.strings
│   ├── Data/
│   │   ├── Local/
│   │   │   ├── MangaLocalStorage.swift
│   │   │   ├── CacheManager.swift
│   │   │   └── UserDefaults+Extensions.swift
│   │   └── Remote/
│   │       ├── APIClient.swift
│   │       ├── AIServiceProvider.swift
│   │       └── Models/
│   │           ├── APIRequest.swift
│   │           └── APIResponse.swift
│   └── Preview Content/
│       └── PreviewData.swift
├── AIMangaCreatorTests/
│   ├── ViewModelTests/
│   ├── ServiceTests/
│   ├── ModelTests/
│   └── HelperTests/
├── AIMangaCreatorUITests/
│   ├── EditorUITests.swift
│   ├── GeneratorUITests.swift
│   └── ProjectBrowserUITests.swift
├── README.md
├── CONTRIBUTING.md
└── Info.plist
```

---

## SETUP & BUILD

### Prerequisites
- macOS 12.0 or later
- Xcode 15.0+
- Apple silicon or Intel Mac
- 2GB free disk space (project files)

### Environment Setup

#### 1. Clone & Install Dependencies
```bash
git clone https://github.com/yourusername/AIMangaCreator.git
cd AIMangaCreator
```

#### 2. API Keys Configuration
Create `Config/APIKeys.xcconfig` (excluded from version control):
```xcconfig
// API Configuration
AI_PROVIDER = openai  // Options: openai, claude, stablediffusion
OPENAI_API_KEY = sk-...
OPENAI_API_ENDPOINT = https://api.openai.com/v1
OPENAI_MODEL = gpt-4-vision
OPENAI_TIMEOUT = 60

// Optional: Claude API
CLAUDE_API_KEY = sk-ant-...
CLAUDE_ENDPOINT = https://api.anthropic.com

// Optional: Stable Diffusion
STABLE_DIFFUSION_API_KEY = sk-...
STABLE_DIFFUSION_ENDPOINT = https://api.stability.ai/v2beta/stable-image/generate

// App Configuration
APP_NAME = AI Manga Creator
BUNDLE_ID = com.example.ai-manga-creator
```

#### 3. Build Settings
In Xcode, set Build Settings → Configuration:
- Debug: Uses mock AI responses for fast iteration
- Release: Production API calls

#### 4. Build & Run
```bash
# Build for development
xcodebuild -scheme AIMangaCreator -configuration Debug build

# Run in Xcode
xcodebuild -scheme AIMangaCreator -configuration Debug -arch arm64 run

# Build for release
xcodebuild -scheme AIMangaCreator -configuration Release build
```

### Xcode Project Settings
- **Product Name:** AI Manga Creator
- **Bundle Identifier:** com.example.ai-manga-creator
- **Minimum Deployment Target:** macOS 12.0
- **Swift Language Version:** 5.9
- **Supported Architectures:** arm64, x86_64
- **Code Signing:** Automatic (or specify team ID)

---

## CORE COMPONENTS

### 1. Manga Data Model
**File:** `Features/Editor/Models/Manga.swift`

```swift
// Core project structure
struct Manga: Codable {
    let id: UUID
    var title: String
    var description: String
    var creator: String
    var createdDate: Date
    var modifiedDate: Date
    
    var panels: [Panel]
    var characters: [Character]
    var metadata: MangaMetadata
    
    // Computed properties
    var panelCount: Int { panels.count }
    var totalPages: Int { (panelCount + 3) / 4 } // 4 panels per page standard
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
        self.generationProgress = min(progress, 1.0)
    }
}

enum PanelLayout: String, Codable {
    case fullPage
    case halfPage
    case thirdPage
    case quarterPage
    case wideStrip
}

enum GenerationStatus: String, Codable {
    case pending
    case generating
    case completed
    case failed(String)
    case cached
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
```

### 2. Character Management
**File:** `Shared/Models/Character.swift`

```swift
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
```

### 3. Style Configuration
**File:** `Shared/Models/Style.swift`

```swift
struct MangaStyle: Codable {
    let id: UUID
    var name: String
    var genre: MangaGenre
    var description: String
    
    var artStyle: ArtStyleSettings
    var panelSettings: PanelSettings
    var colorPalette: ColorPalette
    var typography: TypographySettings
}

enum MangaGenre: String, Codable {
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
```

### 4. Error Handling
**File:** `Shared/Models/AppError.swift`

```swift
enum AppError: LocalizedError {
    case invalidInput(String)
    case apiError(APIErrorCode, String)
    case fileNotFound(String)
    case fileWriteFailed(String)
    case imageProcessingFailed(String)
    case networkError(URLError)
    case unsupportedFileFormat(String)
    case insufficientDiskSpace
    case unauthorized(String)
    case rateLimited(retryAfter: TimeInterval)
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let msg):
            return "Invalid Input: \(msg)"
        case .apiError(let code, let msg):
            return "API Error (\(code.rawValue)): \(msg)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .fileWriteFailed(let msg):
            return "Could not save file: \(msg)"
        case .imageProcessingFailed(let msg):
            return "Image processing failed: \(msg)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unsupportedFileFormat(let format):
            return "Unsupported format: \(format)"
        case .insufficientDiskSpace:
            return "Not enough disk space to save project"
        case .unauthorized(let msg):
            return "Unauthorized: \(msg)"
        case .rateLimited(let retryAfter):
            return "Rate limited. Retry in \(Int(retryAfter)) seconds."
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidInput:
            return "Check your input and try again."
        case .apiError:
            return "Check your API keys and network connection."
        case .fileNotFound:
            return "The file may have been moved or deleted."
        case .insufficientDiskSpace:
            return "Free up disk space and try again."
        case .rateLimited(let retryAfter):
            return "Wait \(Int(retryAfter)) seconds before retrying."
        default:
            return "Please try again or contact support."
        }
    }
}

enum APIErrorCode: String {
    case invalidRequest = "invalid_request_error"
    case authentication = "authentication_error"
    case rateLimit = "rate_limit_error"
    case server = "server_error"
    case unknown = "unknown_error"
}
```

---

## AI INTEGRATION

### AI Provider Architecture
**File:** `Data/Remote/AIServiceProvider.swift`

```swift
protocol AIProvider {
    func generateImage(
        prompt: String,
        style: MangaStyle,
        characterGuides: [CharacterReference]
    ) async throws -> GeneratedImage
    
    func refinePrompt(
        original: String,
        style: MangaStyle,
        context: String
    ) async throws -> String
    
    func analyzeCharacterConsistency(
        referenceImage: NSImage,
        panelImage: NSImage
    ) async throws -> ConsistencyReport
}

struct GeneratedImage {
    let imageData: Data
    let imageURL: URL // Cached locally
    let metadata: ImageMetadata
    let generationTime: TimeInterval
}

struct ImageMetadata {
    let model: String
    let seed: Int?
    let width: Int
    let height: Int
    let steps: Int?
    let guidanceScale: Double?
}

struct ConsistencyReport {
    let overallScore: Double // 0.0-1.0
    let characterRecognitionConfidence: Double
    let styleConsistency: Double
    let issues: [ConsistencyIssue]
}

struct ConsistencyIssue {
    enum Severity { case low, medium, high }
    var description: String
    var severity: Severity
    var suggestion: String
}

// Implementation for OpenAI GPT-4 Vision
class OpenAIProvider: AIProvider {
    private let apiKey: String
    private let apiClient: APIClient
    
    init(apiKey: String, apiClient: APIClient = APIClient.shared) {
        self.apiKey = apiKey
        self.apiClient = apiClient
    }
    
    func generateImage(
        prompt: String,
        style: MangaStyle,
        characterGuides: [CharacterReference]
    ) async throws -> GeneratedImage {
        let enhancedPrompt = try await refinePrompt(
            original: prompt,
            style: style,
            context: characterGuides.map { $0.action }.joined(separator: ", ")
        )
        
        let request = ImageGenerationRequest(
            prompt: enhancedPrompt,
            model: "dall-e-3",
            size: "1024x1024",
            quality: "hd",
            n: 1,
            style: "vivid"
        )
        
        let response = try await apiClient.post(
            endpoint: "/v1/images/generations",
            body: request,
            headers: ["Authorization": "Bearer \(apiKey)"]
        ) as ImageGenerationResponse
        
        guard let imageURLString = response.data.first?.url else {
            throw AppError.imageProcessingFailed("No image in response")
        }
        
        // Download and cache image
        let imageData = try await downloadImage(from: imageURLString)
        let cachedURL = try cacheImage(imageData)
        
        return GeneratedImage(
            imageData: imageData,
            imageURL: cachedURL,
            metadata: ImageMetadata(
                model: "dall-e-3",
                seed: response.data.first?.revised_prompt.hashValue,
                width: 1024,
                height: 1024,
                steps: nil,
                guidanceScale: nil
            ),
            generationTime: Date().timeIntervalSince(Date())
        )
    }
    
    func refinePrompt(
        original: String,
        style: MangaStyle,
        context: String
    ) async throws -> String {
        let systemPrompt = """
        You are a manga scene description expert. Enhance prompts for manga-style image generation.
        - Include manga-specific details: panel composition, visual flow, art style
        - Maintain character consistency references
        - Style: \(style.genre.rawValue) genre, \(style.artStyle.detailLevel.rawValue) details
        - Keep descriptions under 200 tokens
        - Return ONLY the refined prompt, no explanations
        """
        
        let request = ChatCompletionRequest(
            model: "gpt-4-turbo",
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: "Original: \(original)\nContext: \(context)")
            ],
            temperature: 0.7,
            maxTokens: 200
        )
        
        let response = try await apiClient.post(
            endpoint: "/v1/chat/completions",
            body: request,
            headers: ["Authorization": "Bearer \(apiKey)"]
        ) as ChatCompletionResponse
        
        guard let content = response.choices.first?.message.content else {
            throw AppError.apiError(.unknown, "No response from prompt refinement")
        }
        
        return content
    }
    
    func analyzeCharacterConsistency(
        referenceImage: NSImage,
        panelImage: NSImage
    ) async throws -> ConsistencyReport {
        // Implementation for vision analysis
        // This would use GPT-4 Vision to compare images
        fatalError("Not yet implemented")
    }
    
    // Helper methods
    private func downloadImage(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw AppError.invalidInput("Invalid image URL")
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        
        return data
    }
    
    private func cacheImage(_ data: Data) throws -> URL {
        let cacheDir = FileManager.default.urls(
            for: .cachesDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        
        let mangaCache = cacheDir.appendingPathComponent("AIMangaCreator/Images")
        try FileManager.default.createDirectory(
            at: mangaCache,
            withIntermediateDirectories: true
        )
        
        let filename = "\(UUID().uuidString).png"
        let fileURL = mangaCache.appendingPathComponent(filename)
        try data.write(to: fileURL)
        
        return fileURL
    }
}

// Data structures for API communication
struct ImageGenerationRequest: Encodable {
    let prompt: String
    let model: String
    let size: String
    let quality: String
    let n: Int
    let style: String
}

struct ImageGenerationResponse: Decodable {
    struct ImageData: Decodable {
        let url: String
        let revised_prompt: String
    }
    let data: [ImageData]
}

struct ChatMessage: Encodable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
    
    enum CodingKeys: String, CodingKey {
        case model, messages, temperature
        case maxTokens = "max_tokens"
    }
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        let message: ChatMessage
    }
    let choices: [Choice]
}
```

### API Client Abstraction
**File:** `Data/Remote/APIClient.swift`

```swift
class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300 // 5 minutes for large uploads
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    func post<Request: Encodable, Response: Decodable>(
        endpoint: String,
        body: Request,
        headers: [String: String] = [:]
    ) async throws -> Response {
        let url = try buildURL(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try decoder.decode(Response.self, from: data)
    }
    
    private func buildURL(_ endpoint: String) throws -> URL {
        guard let baseURL = URL(string: "https://api.openai.com") else {
            throw AppError.invalidInput("Invalid base URL")
        }
        return baseURL.appendingPathComponent(endpoint)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw AppError.unauthorized("Invalid API key")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init) ?? 60
            throw AppError.rateLimited(retryAfter: retryAfter)
        case 400:
            throw AppError.invalidInput("Invalid request")
        default:
            throw AppError.apiError(.server, "HTTP \(httpResponse.statusCode)")
        }
    }
}
```

---

## DATA MODELS

### Metadata & Project Structure
**File:** `Features/Editor/Models/Manga.swift` (continued)

```swift
struct MangaMetadata: Codable {
    var tags: [String]
    var genre: MangaGenre
    var targetAudience: String
    var status: ProjectStatus
    var notes: String
    var collaborators: [Collaborator]
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
```

---

## UI FRAMEWORK

### Main Application Window
**File:** `App/Scenes/MainWindow.swift`

```swift
struct MainWindow: Scene {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    // Trigger new project action
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") { /* Save logic */ }
                    .keyboardShortcut("s", modifiers: .command)
                
                Button("Export") { /* Export logic */ }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

// Main content area
struct ContentView: View {
    @StateObject private var projectVM = ProjectManagerViewModel()
    @State private var selectedView: AppView = .browser
    
    enum AppView {
        case browser
        case editor
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedView: $selectedView)
        } detail: {
            // Main content area
            switch selectedView {
            case .browser:
                ProjectBrowserView(viewModel: projectVM)
            case .editor:
                if let project = projectVM.selectedProject {
                    MangaEditorView(manga: project)
                } else {
                    EmptyProjectView()
                }
            case .settings:
                SettingsView()
            }
        }
    }
}

// Sidebar navigation
struct SidebarView: View {
    @Binding var selectedView: ContentView.AppView
    @State private var expandProjects = true
    
    var body: some View {
        List {
            Section("Navigation") {
                NavigationLink(
                    destination: Text("Projects"),
                    tag: ContentView.AppView.browser,
                    selection: $selectedView
                ) {
                    Label("Projects", systemImage: "folder.fill")
                }
                
                NavigationLink(
                    destination: Text("Settings"),
                    tag: ContentView.AppView.settings,
                    selection: $selectedView
                ) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            Section("Recent") {
                // Recent projects list
                ForEach(5..<0, id: \.self) { i in
                    Text("Project \(i)")
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AI Manga Creator")
    }
}
```

### Editor View
**File:** `Features/Editor/Views/MangaEditorView.swift`

```swift
struct MangaEditorView: View {
    @ObservedObject var viewModel: MangaEditorViewModel
    @State private var selectedPanelID: UUID?
    @State private var showInspector = true
    
    var body: some View {
        NavigationSplitView {
            // Panels list
            PanelListView(
                panels: viewModel.manga.panels,
                selectedID: $selectedPanelID
            )
        } content: {
            // Panel grid
            PanelGridView(
                panels: viewModel.manga.panels,
                selectedID: $selectedPanelID
            )
        } detail: {
            // Detail inspector
            if let panelID = selectedPanelID,
               let panel = viewModel.manga.panels.first(where: { $0.id == panelID }) {
                PanelDetailView(
                    panel: panel,
                    viewModel: viewModel
                )
            } else {
                Text("Select a panel to edit")
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Panel grid display (4 panels per page standard layout)
struct PanelGridView: View {
    let panels: [Panel]
    @Binding var selectedID: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<(panels.count + 3) / 4, id: \.self) { pageIndex in
                    PageView(
                        panels: Array(
                            panels[pageIndex * 4..<min((pageIndex + 1) * 4, panels.count)]
                        ),
                        selectedID: $selectedID
                    )
                }
            }
            .padding()
        }
    }
}

struct PageView: View {
    let panels: [Panel]
    @Binding var selectedID: UUID?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(panels.prefix(2), id: \.id) { panel in
                    PanelThumbnail(
                        panel: panel,
                        isSelected: selectedID == panel.id,
                        onSelect: { selectedID = panel.id }
                    )
                }
            }
            if panels.count > 2 {
                HStack(spacing: 8) {
                    ForEach(panels.dropFirst(2), id: \.id) { panel in
                        PanelThumbnail(
                            panel: panel,
                            isSelected: selectedID == panel.id,
                            onSelect: { selectedID = panel.id }
                        )
                    }
                }
            }
        }
        .frame(height: 400)
        .border(Color.gray, width: 1)
        .padding()
    }
}

struct PanelThumbnail: View {
    let panel: Panel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        ZStack {
            // Panel background
            Color.white
            
            // Generated image
            if let imageURL = panel.generatedImageURL,
               let nsImage = NSImage(contentsOf: imageURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
            }
            
            // Generation progress
            if case .generating = panel.generationStatus {
                ProgressView(value: panel.generationProgress)
                    .padding()
            }
            
            // Selection border
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.blue, lineWidth: 3)
            }
        }
        .onTapGesture(perform: onSelect)
    }
}
```

### Generator View
**File:** `Features/Generator/Views/GeneratorView.swift`

```swift
struct GeneratorView: View {
    @ObservedObject var viewModel: PanelGeneratorViewModel
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Prompt input
            PromptInputView(
                prompt: $viewModel.currentPrompt,
                characterGuides: viewModel.selectedCharacters
            )
            
            // Style selector
            Picker("Manga Style", selection: $viewModel.selectedStyle) {
                ForEach(MangaStyle.allCases, id: \.self) { style in
                    Text(style.name).tag(style)
                }
            }
            
            // Generation button
            Button(action: { Task { await generatePanel() } }) {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGenerating ? "Generating..." : "Generate Panel")
                }
            }
            .disabled(isGenerating || viewModel.currentPrompt.isEmpty)
            .buttonStyle(.prominent)
            
            // Results preview
            if let generatedImage = viewModel.lastGeneratedImage {
                VStack {
                    Text("Generated Panel")
                        .font(.headline)
                    Image(nsImage: generatedImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func generatePanel() async {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            try await viewModel.generatePanel()
        } catch {
            viewModel.error = error as? AppError ?? .unknown(error)
        }
    }
}

struct PromptInputView: View {
    @Binding var prompt: String
    let characterGuides: [CharacterReference]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Panel Description", systemImage: "square.and.pencil")
                .font(.headline)
            
            TextEditor(text: $prompt)
                .frame(minHeight: 100)
                .border(Color.gray, width: 1)
                .cornerRadius(4)
            
            if !characterGuides.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Characters in this panel:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(characterGuides, id: \.characterID) { guide in
                        Text("• \(guide.action)")
                            .font(.caption)
                    }
                }
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            }
        }
    }
}
```

---

## STATE MANAGEMENT

### ViewModel Architecture
**File:** `Features/Editor/ViewModels/MangaEditorViewModel.swift`

```swift
@MainActor
class MangaEditorViewModel: NSObject, ObservableObject {
    @Published var manga: Manga
    @Published var error: AppError?
    @Published var isSaving = false
    @Published var undoManager = UndoManager()
    
    private let repository: MangaRepository
    private let aiProvider: AIProvider
    
    // Initialization
    init(
        manga: Manga,
        repository: MangaRepository = MangaRepository.shared,
        aiProvider: AIProvider = OpenAIProvider(apiKey: Config.openAIKey)
    ) {
        self.manga = manga
        self.repository = repository
        self.aiProvider = aiProvider
        super.init()
    }
    
    // MARK: - Panel Management
    func addPanel(after panelID: UUID? = nil) {
        let newPanel = Panel(
            id: UUID(),
            order: manga.panels.count,
            panelType: .quarterPage,
            prompt: "",
            generatedImageURL: nil,
            characterGuide: [],
            dialogueBox: nil,
            soundEffect: nil,
            generationStatus: .pending
        )
        
        if let afterID = panelID,
           let index = manga.panels.firstIndex(where: { $0.id == afterID }) {
            manga.panels.insert(newPanel, at: index + 1)
        } else {
            manga.panels.append(newPanel)
        }
        
        undoManager.registerUndo(withTarget: self) { $0.removePanel(newPanel.id) }
        objectWillChange.send()
    }
    
    func removePanel(_ id: UUID) {
        guard let index = manga.panels.firstIndex(where: { $0.id == id }) else { return }
        let removed = manga.panels.remove(at: index)
        
        undoManager.registerUndo(withTarget: self) { $0.addPanel(after: index > 0 ? manga.panels[index - 1].id : nil) }
        objectWillChange.send()
    }
    
    func reorderPanels(from: IndexSet, to: Int) {
        manga.panels.move(fromOffsets: from, toOffset: to)
        objectWillChange.send()
    }
    
    func updatePanel(_ panel: Panel) {
        if let index = manga.panels.firstIndex(where: { $0.id == panel.id }) {
            manga.panels[index] = panel
            objectWillChange.send()
        }
    }
    
    // MARK: - Generation
    func generatePanel(_ panelID: UUID) async {
        guard var panel = manga.panels.first(where: { $0.id == panelID }) else { return }
        
        panel.generationStatus = .generating
        updatePanel(panel)
        
        do {
            let generatedImage = try await aiProvider.generateImage(
                prompt: panel.prompt,
                style: manga.metadata.style,
                characterGuides: panel.characterGuide
            )
            
            panel.generatedImageURL = generatedImage.imageURL
            panel.generationStatus = .completed
            updatePanel(panel)
        } catch {
            panel.generationStatus = .failed(error.localizedDescription)
            self.error = error as? AppError ?? .unknown(error)
            updatePanel(panel)
        }
    }
    
    func generateBatch(panelIDs: [UUID]) async {
        for panelID in panelIDs {
            await generatePanel(panelID)
        }
    }
    
    // MARK: - Persistence
    func save() async {
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await repository.save(manga)
            manga.modifiedDate = Date()
        } catch {
            self.error = error as? AppError ?? .unknown(error)
        }
    }
    
    func autoSave() async {
        // Debounced auto-save every 30 seconds
        try? await Task.sleep(nanoseconds: 30 * 1_000_000_000)
        await save()
    }
}

// MARK: - Undo/Redo Support
extension MangaEditorViewModel {
    func undo() {
        undoManager.undo()
    }
    
    func redo() {
        undoManager.redo()
    }
    
    var canUndo: Bool {
        undoManager.canUndo
    }
    
    var canRedo: Bool {
        undoManager.canRedo
    }
}
```

### Panel Generator ViewModel
**File:** `Features/Generator/ViewModels/PanelGeneratorViewModel.swift`

```swift
@MainActor
class PanelGeneratorViewModel: ObservableObject {
    @Published var currentPrompt: String = ""
    @Published var selectedStyle: MangaStyle = .shounen
    @Published var selectedCharacters: [CharacterReference] = []
    @Published var lastGeneratedImage: NSImage?
    @Published var generationProgress: Double = 0.0
    @Published var error: AppError?
    
    private let aiProvider: AIProvider
    
    init(aiProvider: AIProvider = OpenAIProvider(apiKey: Config.openAIKey)) {
        self.aiProvider = aiProvider
    }
    
    @MainActor
    func generatePanel() async throws {
        guard !currentPrompt.isEmpty else {
            throw AppError.invalidInput("Prompt cannot be empty")
        }
        
        generationProgress = 0.0
        
        do {
            let startTime = Date()
            let generatedImage = try await aiProvider.generateImage(
                prompt: currentPrompt,
                style: selectedStyle,
                characterGuides: selectedCharacters
            )
            
            self.lastGeneratedImage = NSImage(data: generatedImage.imageData)
            self.generationProgress = 1.0
            
            Logger.info("Panel generated in \(Date().timeIntervalSince(startTime))s")
        } catch {
            self.error = error as? AppError ?? .unknown(error)
            throw error
        }
    }
}
```

---

## FILE I/O & PERSISTENCE

### Project Storage
**File:** `Features/Project/Services/ProjectService.swift`

```swift
class ProjectService {
    static let shared = ProjectService()
    
    private let fileManager = FileManager.default
    private lazy var projectsDirectory: URL = {
        let appSupportDir = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory
        
        let projectsDir = appSupportDir.appendingPathComponent("AIMangaCreator/Projects")
        try? fileManager.createDirectory(
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
        let metadata = MangaMetadata(manga: manga)
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
                try fileManager.copyItem(at: imageURL, to: destPath)
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
            title: metadata.title,
            description: metadata.description,
            creator: metadata.creator,
            createdDate: metadata.createdDate,
            modifiedDate: metadata.modifiedDate,
            panels: panels,
            characters: metadata.characters,
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
```

### Caching Strategy
**File:** `Data/Local/CacheManager.swift`

```swift
class CacheManager {
    static let shared = CacheManager()
    
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let mangaCache = caches.appendingPathComponent("AIMangaCreator")
        try? fileManager.createDirectory(at: mangaCache, withIntermediateDirectories: true)
        return mangaCache
    }()
    
    private let diskSizeLimit: Int = 1_000_000_000 // 1GB
    private var memoryCache = NSCache<NSString, NSImage>()
    
    func setImage(_ image: NSImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        
        if let pngData = image.tiffRepresentation?.pngData() {
            let fileURL = cacheDirectory.appendingPathComponent("\(key).png")
            try? pngData.write(to: fileURL)
            trimCacheIfNeeded()
        }
    }
    
    func image(forKey key: String) -> NSImage? {
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        
        let fileURL = cacheDirectory.appendingPathComponent("\(key).png")
        if let imageData = try? Data(contentsOf: fileURL),
           let image = NSImage(data: imageData) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }
        
        return nil
    }
    
    private func trimCacheIfNeeded() {
        let attrs = try? fileManager.attributesOfFileSystem(forPath: cacheDirectory.path)
        let availableSpace = (attrs?[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        
        if availableSpace < 100_000_000 { // Less than 100MB free
            clearCache()
        }
    }
    
    func clearCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.removeAllObjects()
    }
}
```

---

## TESTING STRATEGY

### Unit Testing Structure
**File:** `AIMangaCreatorTests/ViewModelTests/MangaEditorViewModelTests.swift`

```swift
import XCTest
@testable import AIMangaCreator

class MangaEditorViewModelTests: XCTestCase {
    var viewModel: MangaEditorViewModel!
    var mockRepository: MockMangaRepository!
    var mockAIProvider: MockAIProvider!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMangaRepository()
        mockAIProvider = MockAIProvider()
        
        let testManga = Manga.preview
        viewModel = MangaEditorViewModel(
            manga: testManga,
            repository: mockRepository,
            aiProvider: mockAIProvider
        )
    }
    
    func testAddPanelIncrementsCount() {
        let initialCount = viewModel.manga.panelCount
        viewModel.addPanel()
        
        XCTAssertEqual(viewModel.manga.panelCount, initialCount + 1)
    }
    
    func testRemovePanelDecrementsCount() {
        viewModel.addPanel()
        let panelID = viewModel.manga.panels.last!.id
        viewModel.removePanel(panelID)
        
        XCTAssertEqual(viewModel.manga.panels.count, 0)
    }
    
    func testGeneratePanelUpdatesStatus() async {
        let panelID = viewModel.manga.panels.first!.id
        
        await viewModel.generatePanel(panelID)
        
        let panel = viewModel.manga.panels.first!
        XCTAssertEqual(panel.generationStatus, .completed)
        XCTAssertNotNil(panel.generatedImageURL)
    }
    
    func testUndoRestoresState() {
        let initialCount = viewModel.manga.panelCount
        viewModel.addPanel()
        viewModel.undo()
        
        XCTAssertEqual(viewModel.manga.panelCount, initialCount)
    }
}

// MARK: - Mocks
class MockMangaRepository: MangaRepository {
    func save(_ manga: Manga) async throws {}
    func load(_ id: UUID) async throws -> Manga { Manga.preview }
    func listAll() async throws -> [Manga] { [Manga.preview] }
    func delete(_ id: UUID) async throws {}
}

class MockAIProvider: AIProvider {
    func generateImage(
        prompt: String,
        style: MangaStyle,
        characterGuides: [CharacterReference]
    ) async throws -> GeneratedImage {
        let testImage = NSImage(size: NSSize(width: 1024, height: 1024))
        let pngData = testImage.tiffRepresentation ?? Data()
        
        return GeneratedImage(
            imageData: pngData,
            imageURL: URL(fileURLWithPath: "/tmp/test.png"),
            metadata: ImageMetadata(
                model: "test-model",
                seed: 42,
                width: 1024,
                height: 1024,
                steps: 20,
                guidanceScale: 7.5
            ),
            generationTime: 2.0
        )
    }
    
    func refinePrompt(
        original: String,
        style: MangaStyle,
        context: String
    ) async throws -> String {
        return original
    }
    
    func analyzeCharacterConsistency(
        referenceImage: NSImage,
        panelImage: NSImage
    ) async throws -> ConsistencyReport {
        fatalError("Not implemented in mock")
    }
}
```

### UI Testing
**File:** `AIMangaCreatorUITests/EditorUITests.swift`

```swift
import XCTest

class EditorUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
    }
    
    func testPanelGenerationFlow() {
        // Navigate to generator
        app.tabBars.buttons["Generator"].tap()
        
        // Fill prompt
        let promptField = app.textViews["promptInput"]
        promptField.tap()
        promptField.typeText("A ninja jumping over a building")
        
        // Generate
        app.buttons["Generate Panel"].tap()
        
        // Wait for result
        let generatedImage = app.images["generatedPanel"]
        XCTAssertTrue(
            generatedImage.waitForExistence(timeout: 60),
            "Generated image did not appear"
        )
    }
    
    func testPanelReordering() {
        let firstPanel = app.cells.element(boundBy: 0)
        let secondPanel = app.cells.element(boundBy: 1)
        
        firstPanel.drag(to: secondPanel)
        
        // Verify order changed
        XCTAssertTrue(firstPanel.frame.minY > secondPanel.frame.minY)
    }
}
```

---

## PERFORMANCE OPTIMIZATION

### Image Processing
**File:** `Shared/Utilities/ImageProcessor.swift`

```swift
class ImageProcessor {
    static func optimizeForScreen(_ image: NSImage) -> NSImage {
        let maxSize: CGFloat = 1200
        let currentSize = image.size
        
        if currentSize.width <= maxSize && currentSize.height <= maxSize {
            return image
        }
        
        let ratio = min(maxSize / currentSize.width, maxSize / currentSize.height)
        let newSize = NSSize(
            width: currentSize.width * ratio,
            height: currentSize.height * ratio
        )
        
        return image.resized(to: newSize)
    }
    
    static func optimizeForExport(_ image: NSImage, dpi: Int = 300) -> NSImage {
        // Scale for export DPI
        let scale = CGFloat(dpi) / 72.0 // 72 is screen DPI
        let newSize = NSSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )
        
        return image.resized(to: newSize)
    }
    
    static func applyMangaStyle(_ image: NSImage, style: MangaStyle) -> NSImage {
        // Apply edge detection for ink effect
        // Apply screentone patterns
        // Adjust colors per style palette
        
        let filtered = image // Apply filters
        return filtered
    }
}

extension NSImage {
    func resized(to size: NSSize) -> NSImage {
        let frame = NSRect(origin: .zero, size: size)
        guard let resized = NSImage(size: size) else { return self }
        
        resized.lockFocus()
        self.draw(in: frame)
        resized.unlockFocus()
        
        resized.size = size
        return resized
    }
}
```

### Memory Management
**File:** `Shared/Utilities/MemoryOptimization.swift`

```swift
class MemoryOptimizer {
    static func monitorMemoryUsage() {
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            var info = task_vm_info_data_t()
            var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size)/4
            
            let kern = task_info(
                mach_task_self_,
                task_flavor_t(TASK_VM_INFO),
                &info,
                &count
            )
            
            guard kern == KERN_SUCCESS else { return }
            
            let usedMemory = Double(info.phys_footprint) / 1024 / 1024
            Logger.debug("Memory usage: \(String(format: "%.1f", usedMemory)) MB")
            
            if usedMemory > 500 {
                CacheManager.shared.clearCache()
                URLCache.shared.removeAllCachedResponses()
            }
        }
    }
}
```

### Network Optimization
**File:** `Data/Remote/APIClient.swift` (expanded)

```swift
// Add request deduplication and response caching
class APIClient {
    private var requestCache: [String: (data: Decodable, expiry: Date)] = [:]
    private let cacheLock = NSLock()
    
    func cachedPost<Request: Encodable & Hashable, Response: Decodable>(
        endpoint: String,
        body: Request,
        cacheDuration: TimeInterval = 3600
    ) async throws -> Response {
        let cacheKey = "\(endpoint)_\(body.hashValue)"
        
        cacheLock.lock()
        if let cached = requestCache[cacheKey],
           cached.expiry > Date() {
            cacheLock.unlock()
            return cached.data as! Response
        }
        cacheLock.unlock()
        
        let result = try await post(endpoint: endpoint, body: body) as Response
        
        cacheLock.lock()
        requestCache[cacheKey] = (result, Date().addingTimeInterval(cacheDuration))
        cacheLock.unlock()
        
        return result
    }
}
```

---

## DEPLOYMENT

### Build Configuration
**File:** `AIMangaCreator.xcodeproj/project.pbxproj` (Build Settings)

```
PRODUCT_NAME = AI Manga Creator
BUNDLE_ID = com.example.ai-manga-creator
VERSION_NUMBER = 1.0.0
BUILD_NUMBER = 1

// Code signing
CODE_SIGN_IDENTITY = Apple Development
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = <YOUR_TEAM_ID>

// Deployment target
MACOSX_DEPLOYMENT_TARGET = 12.0

// Optimization
SWIFT_OPTIMIZATION_LEVEL = -O  // Release optimization
ENABLE_BITCODE = NO

// Strip symbols
STRIP_INSTALLED_PRODUCT = YES
COPY_PHASE_STRIP = YES
```

### Release Process

#### 1. Version Bump
```bash
# Update version in Xcode or via xcconfig
VERSION=1.0.0
BUILD=$(git rev-parse --short HEAD)
```

#### 2. Archive Build
```bash
xcodebuild archive \
  -scheme AIMangaCreator \
  -archivePath ./build/AIMangaCreator.xcarchive \
  -configuration Release
```

#### 3. Export for Distribution
```bash
xcodebuild -exportArchive \
  -archivePath ./build/AIMangaCreator.xcarchive \
  -exportOptionsPlist ./ExportOptions.plist \
  -exportPath ./build/Distribution
```

#### 4. Code Signing & Notarization
```bash
# Sign the app
codesign -s - ./build/AIMangaCreator.app

# Notarize for Gatekeeper
xcrun notarytool submit ./build/AIMangaCreator.dmg \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_PASSWORD" \
  --team-id "$TEAM_ID" \
  --wait
```

#### 5. Create DMG Installer
```bash
create-dmg \
  --volname "AI Manga Creator" \
  --volicon "./app-icon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --app-drop-link 750 250 \
  "./dist/AIMangaCreator-${VERSION}.dmg" \
  "./build/AIMangaCreator.app"
```

### Distribution Channels
1. **App Store:** Through Apple's Mac App Store
2. **Direct Download:** Website downloads with auto-update
3. **Homebrew:** `brew install ai-manga-creator`

---

## TROUBLESHOOTING & COMMON ISSUES

### Slow Image Generation
- Verify API rate limits not exceeded
- Check network bandwidth
- Consider batch processing optimization
- Monitor GPU availability if local generation

### Memory Leaks
- Profile with Instruments → Allocations
- Check retain cycles in ViewModels
- Verify image cache size limits
- Monitor background tasks

### File Access Issues
- Verify ~/Library/Application Support permissions
- Check ~/Library/Caches available space
- Validate file paths are absolute
- Use sandboxing exceptions if needed

---

## FUTURE ENHANCEMENTS

1. **Local Model Support:** Integrate Stable Diffusion or SDXL locally
2. **Collaborative Editing:** Real-time multi-user panels
3. **Animation Export:** Generate animated sequences
4. **Voice Integration:** Generate dialogue from text-to-speech
5. **Community Library:** Share styles and characters
6. **Mobile Companion:** iOS app for remote editing
7. **ML Training:** Fine-tune models on user styles

---

## REFERENCES

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Core Data Guide](https://developer.apple.com/documentation/coredata)
- [Swift Concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency)
- [macOS App Development](https://developer.apple.com/macos/app-development/)
- [OpenAI API](https://platform.openai.com/docs)

---

**Last Updated:** November 2025  
**Maintainer:** Development Team  
**License:** MIT
