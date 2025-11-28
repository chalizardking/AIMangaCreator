//
//  AIProviderFactory.swift
//  AIMangaCreator
//
//  Created on 2025-11-28.
//

import Foundation

class AIProviderFactory {
    private let keychain = KeychainService.shared
    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func provider(for type: AIProviderType) -> AIProvider {
        switch type {
        case .openAI:
            let apiKey = keychain.get(key: "openai_api_key") ?? ""
            return OpenAIProvider(apiKey: apiKey, apiClient: apiClient)
        case .gemini:
            let apiKey = keychain.get(key: "gemini_api_key") ?? ""
            return GeminiProvider(apiKey: apiKey, apiClient: apiClient)
        case .openRouter:
            let apiKey = keychain.get(key: "openrouter_api_key") ?? ""
            return OpenRouterProvider(apiKey: apiKey, apiClient: apiClient)
        }
    }
}
