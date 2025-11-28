import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        Form {
            Section("API Configuration") {
                APIKeyField(
                    title: "OpenAI API Key",
                    text: Binding(
                        get: { viewModel.openAIKey },
                        set: { viewModel.updateOpenAIKey($0) }
                    ),
                    status: viewModel.validationStatus["OpenAI"] ?? .unknown,
                    onValidate: { Task { await viewModel.validateKey(for: "OpenAI") } },
                    description: "Used for DALL-E 3 image generation and GPT-4 prompt refinement"
                )

                APIKeyField(
                    title: "Gemini API Key",
                    text: Binding(
                        get: { viewModel.geminiKey },
                        set: { viewModel.updateGeminiKey($0) }
                    ),
                    status: viewModel.validationStatus["Gemini"] ?? .unknown,
                    onValidate: { Task { await viewModel.validateKey(for: "Gemini") } },
                    description: "Used for Gemini Pro text refinement"
                )

                APIKeyField(
                    title: "OpenRouter API Key",
                    text: Binding(
                        get: { viewModel.openRouterKey },
                        set: { viewModel.updateOpenRouterKey($0) }
                    ),
                    status: viewModel.validationStatus["OpenRouter"] ?? .unknown,
                    onValidate: { Task { await viewModel.validateKey(for: "OpenRouter") } },
                    description: "Used for accessing multiple LLM models"
                )
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

struct APIKeyField: View {
    let title: String
    @Binding var text: String
    let status: ValidationStatus
    let onValidate: () -> Void
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                ValidationBadge(status: status)
            }
            
            HStack {
                SecureField("Enter API Key", text: $text)
                    .textFieldStyle(.roundedBorder)
                
                Button("Validate") {
                    onValidate()
                }
                .disabled(text.isEmpty || status == .validating)
            }
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if case .invalid(let error) = status {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct ValidationBadge: View {
    let status: ValidationStatus
    
    var body: some View {
        switch status {
        case .unknown:
            EmptyView()
        case .validating:
            ProgressView()
                .scaleEffect(0.5)
                .frame(width: 16, height: 16)
        case .valid:
            Label("Valid", systemImage: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        case .invalid:
            Label("Invalid", systemImage: "xmark.circle.fill")
                .foregroundColor(.red)
                .font(.caption)
        }
    }
}
