//
//  SettingsViewModel.swift
//  AIMangaCreator
//
//  Created on 2025-11-27.
//

import Foundation
import Combine

class SettingsViewModel: ObservableObject {
    @Published var openAIKey: String = ""
    @Published var geminiKey: String = "" 
    @Published var openRouterKey: String = ""
    @Published var defaultProvider: String = "OpenAI"
    @Published var defaultStyleIndex: Int = 0
    @Published var autoSaveEnabled: Bool = true
    @Published var cacheImages: Bool = true

    private let keychain = KeychainService.shared
    private let defaults = UserDefaults.standard

    private let openAIKeyKey = "openai_api_key"
    private let geminiKeyKey = "gemini_api_key"
    private let openRouterKeyKey = "openrouter_api_key"

    init() {
        loadSettings()
    }

    private func loadSettings() {
        /// Load API keys from Keychain
        openAIKey = keychain.get(key: openAIKeyKey) ?? ""
        geminiKey = keychain.get(key: geminiKeyKey) ?? ""
        openRouterKey = keychain.get(key: openRouterKeyKey) ?? ""

        /// Load other settings from UserDefaults
        defaultProvider = defaults.string(forKey: "default_provider") ?? "OpenAI"
        defaultStyleIndex = defaults.integer(forKey: "default_style")
        autoSaveEnabled = defaults.bool(forKey: "auto_save_enabled")
        cacheImages = defaults.bool(forKey: "cache_images")
    }

    private func saveApiKey(key: String, value: String) {
        if value.isEmpty {
            keychain.delete(key: key)
        } else {
            _ = keychain.set(key: key, value: value)
        }
        /// Update the published property
        switch key {
        case openAIKeyKey:
            openAIKey = value
        case geminiKeyKey:
            geminiKey = value
        case openRouterKeyKey:
            openRouterKey = value
        default:
            break
        }
    }

    func updateOpenAIKey(_ value: String) {
        saveApiKey(key: openAIKeyKey, value: value)
    }

    func updateGeminiKey(_ value: String) {
        saveApiKey(key: geminiKeyKey, value: value)
    }

    func updateOpenRouterKey(_ value: String) {
        saveApiKey(key: openRouterKeyKey, value: value)
    }

    func updateDefaultProvider(_ value: String) {
        defaultProvider = value
        defaults.set(value, forKey: "default_provider")
    }

    func updateDefaultStyleIndex(_ value: Int) {
        defaultStyleIndex = value
        defaults.set(value, forKey: "default_style")
    }

    func updateAutoSaveEnabled(_ value: Bool) {
        autoSaveEnabled = value
        defaults.set(value, forKey: "auto_save_enabled")
    }

    func updateCacheImages(_ value: Bool) {
        cacheImages = value
        defaults.set(value, forKey: "cache_images")
    }

    func clearCache() {
        CacheManager.shared.clearCache()
    }

    func clearAllAPIKeys() {
        keychain.clearAll()
        /// Reload to update UI
        loadSettings()
    }
}
