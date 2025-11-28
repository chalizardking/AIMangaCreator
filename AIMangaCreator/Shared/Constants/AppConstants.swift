import Foundation

/// Prefer Keychain, fallback to environment variables, Info.plist, otherwise empty string
struct Config {
    static var openAIKey: String {
        if let keychainValue = KeychainService.shared.get(key: "openai_api_key"), !keychainValue.isEmpty {
            return keychainValue
        }
        return legacyValue(for: "OPENAI_API_KEY")
    }

    static var geminiKey: String {
        if let keychainValue = KeychainService.shared.get(key: "gemini_api_key"), !keychainValue.isEmpty {
            return keychainValue
        }
        return legacyValue(for: "GEMINI_API_KEY")
    }

    static var openRouterKey: String {
        if let keychainValue = KeychainService.shared.get(key: "openrouter_api_key"), !keychainValue.isEmpty {
            return keychainValue
        }
        return legacyValue(for: "OPENROUTER_API_KEY")
    }

    private static func legacyValue(for key: String) -> String {
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        if let info = Bundle.main.infoDictionary?[key] as? String, !info.isEmpty {
            return info
        }
        return ""
    }
}

struct AppConstants {
    static let appName = "AI Manga Creator"
}
