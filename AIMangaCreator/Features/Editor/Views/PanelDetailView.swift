import SwiftUI

struct PanelDetailView: View {
    let panel: Panel
    @ObservedObject var viewModel: MangaEditorViewModel
    
    var body: some View {
        Form {
            Section("Prompt") {
                TextEditor(text: Binding(
                    get: { panel.prompt },
                    set: { 
                        var updated = panel
                        updated.prompt = $0
                        viewModel.updatePanel(updated)
                    }
                ))
                .frame(minHeight: 100)
                
                HStack {
                    Button("Refine") {
                        Task {
                            await viewModel.refinePanelPrompt(panel.id)
                        }
                    }
                    .disabled(panel.prompt.isEmpty)
                    
                    Spacer()
                    
                    Button("Generate") {
                        Task {
                            await viewModel.generatePanel(panel.id)
                        }
                    }
                }
            }
            
            Section("Settings") {
                Picker("AI Provider", selection: $viewModel.selectedProviderType) {
                    ForEach(AIProviderType.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
            }
            
            Section("Status") {
                Text(panel.generationStatus.description)
            }
        }
        .padding()
    }
}

extension GenerationStatus {
    var description: String {
        switch self {
        case .pending: return "Pending"
        case .generating: return "Generating..."
        case .completed: return "Completed"
        case .failed(let msg): return "Failed: \(msg)"
        case .cached: return "Cached"
        }
    }
}
