import Foundation
import AppKit

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
    /// Cached locally
    let imageURL: URL
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
    /// 0.0-1.0
    let overallScore: Double
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

enum AIProviderType: String, CaseIterable, Identifiable {
    case openAI = "OpenAI"
    case gemini = "Gemini"
    case openRouter = "OpenRouter"
    
    var id: String { rawValue }
}

/// Implementation for OpenAI GPT-4 Vision
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
            headers: ["Authorization": "Bearer \(apiKey)"],
            baseURL: "https://api.openai.com"
        ) as ImageGenerationResponse
        
        guard let imageURLString = response.data.first?.url else {
            throw AppError.imageProcessingFailed("No image in response")
        }
        
        /// Download and cache image
        let imageData = try await downloadImage(from: imageURLString)
        let cachedURL = try cacheImage(imageData)
        
        return GeneratedImage(
            imageData: imageData,
            imageURL: cachedURL,
            metadata: ImageMetadata(
                model: "dall-e-3",
                /// DALL-E 3 does not provide reproducible seeds
                seed: nil,
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
            headers: ["Authorization": "Bearer \(apiKey)"],
            baseURL: "https://api.openai.com"
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
        throw AppError.notImplemented("Character consistency analysis")
    }
    
    /// Helper methods
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

class OpenRouterProvider: AIProvider {
    private let apiKey: String
    private let apiClient: APIClient
    
    init(apiKey: String, apiClient: APIClient = APIClient.shared) {
        self.apiKey = apiKey
        self.apiClient = apiClient
    }
    
    func generateImage(prompt: String, style: MangaStyle, characterGuides: [CharacterReference]) async throws -> GeneratedImage {
        // OpenRouter primarily handles LLMs. For image generation, we might need to fallback or use a specific model if supported.
        // Assuming OpenRouter might proxy some image models or we throw not supported.
        throw AppError.apiError(.invalidRequest, "Image generation not supported by OpenRouter provider yet.")
    }
    
    func refinePrompt(original: String, style: MangaStyle, context: String) async throws -> String {
        let systemPrompt = """
        You are a manga scene description expert. Enhance prompts for manga-style image generation.
        - Include manga-specific details: panel composition, visual flow, art style
        - Maintain character consistency references
        - Style: \(style.genre.rawValue) genre, \(style.artStyle.detailLevel.rawValue) details
        - Keep descriptions under 200 tokens
        - Return ONLY the refined prompt, no explanations
        """
        
        let request = ChatCompletionRequest(
            model: "anthropic/claude-3-opus", // Example OpenRouter model
            messages: [
                ChatMessage(role: "system", content: systemPrompt),
                ChatMessage(role: "user", content: "Original: \(original)\nContext: \(context)")
            ],
            temperature: 0.7,
            maxTokens: 200
        )
        
        let response = try await apiClient.post(
            endpoint: "/api/v1/chat/completions",
            body: request,
            headers: [
                "Authorization": "Bearer \(apiKey)",
                "HTTP-Referer": "https://aimangacreator.app", // Required by OpenRouter
                "X-Title": "AI Manga Creator"
            ],
            baseURL: "https://openrouter.ai"
        ) as ChatCompletionResponse
        
        guard let content = response.choices.first?.message.content else {
            throw AppError.apiError(.unknown, "No response from prompt refinement")
        }
        
        return content
    }
    
    func analyzeCharacterConsistency(referenceImage: NSImage, panelImage: NSImage) async throws -> ConsistencyReport {
        throw AppError.notImplemented("Character consistency analysis")
    }
}

class GeminiProvider: AIProvider {
    private let apiKey: String
    private let apiClient: APIClient
    
    init(apiKey: String, apiClient: APIClient = APIClient.shared) {
        self.apiKey = apiKey
        self.apiClient = apiClient
    }
    
    func generateImage(prompt: String, style: MangaStyle, characterGuides: [CharacterReference]) async throws -> GeneratedImage {
         throw AppError.apiError(.invalidRequest, "Image generation not supported by Gemini provider yet.")
    }
    
    func refinePrompt(original: String, style: MangaStyle, context: String) async throws -> String {
        let systemPrompt = """
        You are a manga scene description expert. Enhance prompts for manga-style image generation.
        - Include manga-specific details: panel composition, visual flow, art style
        - Maintain character consistency references
        - Style: \(style.genre.rawValue) genre, \(style.artStyle.detailLevel.rawValue) details
        - Keep descriptions under 200 tokens
        - Return ONLY the refined prompt, no explanations
        """
        
        let fullPrompt = "\(systemPrompt)\n\nOriginal: \(original)\nContext: \(context)"
        
        let request = GeminiGenerateContentRequest(
            contents: [GeminiContent(parts: [GeminiPart(text: fullPrompt)])]
        )
        
        let endpoint = "/v1beta/models/gemini-pro:generateContent?key=\(apiKey)"
        
        let response = try await apiClient.post(
            endpoint: endpoint,
            body: request,
            baseURL: "https://generativelanguage.googleapis.com"
        ) as GeminiGenerateContentResponse
        
        guard let content = response.candidates?.first?.content.parts.first?.text else {
            throw AppError.apiError(.unknown, "No response from Gemini")
        }
        
        return content
    }
    
    func analyzeCharacterConsistency(referenceImage: NSImage, panelImage: NSImage) async throws -> ConsistencyReport {
        throw AppError.notImplemented("Character consistency analysis")
    }
}

/// Gemini Data Structures
struct GeminiGenerateContentRequest: Encodable {
    let contents: [GeminiContent]
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String
}

struct GeminiGenerateContentResponse: Decodable {
    struct Candidate: Decodable {
        let content: GeminiContent
    }
    let candidates: [Candidate]?
}

/// Data structures for API communication
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

struct ChatMessage: Encodable, Decodable {
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
