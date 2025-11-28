import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section("API Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenAI API Key")
                        .font(.headline)
                    SecureField("sk-...", text: Binding(
                        get: { viewModel.openAIKey },
                        set: { viewModel.updateOpenAIKey($0) }
                    ))
                    Text("Used for DALL-E 3 image generation and GPT-4 prompt refinement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Gemini API Key")
                        .font(.headline)
                    SecureField("AIza...", text: Binding(
                        get: { viewModel.geminiKey },
                        set: { viewModel.updateGeminiKey($0) }
                    ))
                    Text("Used for Gemini Pro text refinement")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("OpenRouter API Key")
                        .font(.headline)
                    SecureField("sk-or-...", text: Binding(
                        get: { viewModel.openRouterKey },
                        set: { viewModel.updateOpenRouterKey($0) }
                    ))
                    Text("Used for accessing multiple LLM models")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Default Settings") {
                Picker("Default AI Provider", selection: Binding(
                    get: { viewModel.defaultProvider },
                    set: { viewModel.updateDefaultProvider($0) }
                )) {
                    Text("OpenAI").tag("OpenAI")
                    Text("Gemini").tag("Gemini")
                    Text("OpenRouter").tag("OpenRouter")
                }

                Picker("Default Manga Style", selection: Binding(
                    get: { viewModel.defaultStyleIndex },
                    set: { viewModel.updateDefaultStyleIndex($0) }
                )) {
                    ForEach(Array(MangaStyle.allCases.enumerated()), id: \.offset) { index, style in
                        Text(style.name).tag(index)
                    }
                }
            }

            Section("Performance") {
                Toggle("Auto-save Projects", isOn: Binding(
                    get: { viewModel.autoSaveEnabled },
                    set: { viewModel.updateAutoSaveEnabled($0) }
                ))
                .help("Automatically save project changes every 30 seconds")

                Toggle("Cache Generated Images", isOn: Binding(
                    get: { viewModel.cacheImages },
                    set: { viewModel.updateCacheImages($0) }
                ))
                .help("Store generated images locally to reduce API calls")

                Button("Clear Image Cache") {
                    viewModel.clearCache()
                }
                .buttonStyle(.bordered)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Build", value: "1")

                Link("Documentation", destination: URL(string: "https://github.com/yourusername/AIMangaCreator")!)
                    .buttonStyle(.link)

                Link("Report an Issue", destination: URL(string: "https://github.com/yourusername/AIMangaCreator/issues")!)
                    .buttonStyle(.link)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .padding()
    }
}

#Preview {
    SettingsView()
}
