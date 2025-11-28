import SwiftUI

struct MangaEditorView: View {
    @ObservedObject var viewModel: MangaEditorViewModel
    @State private var selectedPanelID: UUID?
    @State private var showInspector = true
    @State private var inspectorWidth: CGFloat = 300
    
    var body: some View {
        HSplitView {
            // MARK: Left - Panel list
            PanelListSidebar(
                panels: viewModel.manga.panels,
                selectedID: $selectedPanelID,
                onAdd: { viewModel.addPanel() },
                onDelete: { id in viewModel.removePanel(id) },
                onReorder: { from, to in viewModel.reorderPanels(from: from, to: to) }
            )
            .frame(minWidth: 200, idealWidth: 250, maxWidth: 300)
            
            // MARK: Center - Panel canvas
            VStack(spacing: 0) {
                /// Toolbar
                EditorToolbar(
                    viewModel: viewModel,
                    selectedPanelCount: selectedPanelID != nil ? 1 : 0
                )
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.controlBackgroundColor))
                
                Divider()
                
                /// Canvas
                if viewModel.manga.panels.isEmpty {
                    EmptyCanvasView(onAddPanel: { viewModel.addPanel() })
                } else {
                    PanelGridView(
                        panels: viewModel.manga.panels,
                        selectedID: $selectedPanelID
                    )
                }
            }
            
            // MARK: Right - Inspector
            if showInspector {
                InspectorView(
                    viewModel: viewModel,
                    selectedPanelID: $selectedPanelID
                )
                .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
            }
        }
        .navigationTitle(viewModel.manga.title)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showInspector.toggle() }) {
                    Label("Inspector", systemImage: "sidebar.right")
                }
                .help("Toggle Inspector")
            }
        }
    }
}

struct PanelListSidebar: View {
    let panels: [Panel]
    @Binding var selectedID: UUID?
    let onAdd: () -> Void
    let onDelete: (UUID) -> Void
    let onReorder: (IndexSet, Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            /// Header
            HStack {
                Text("Panels")
                    .font(.headline)
                Spacer()
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("Add Panel")
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            /// Panel list
            if panels.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "rectangle.on.rectangle.angled")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No Panels")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Button("Add First Panel", action: onAdd)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedID) {
                    ForEach(panels) { panel in
                        PanelListItem(panel: panel, isSelected: selectedID == panel.id)
                            .tag(panel.id)
                            .contextMenu {
                                Button("Delete") { onDelete(panel.id) }
                            }
                    }
                    .onMove(perform: onReorder)
                }
            }
        }
    }
}

struct PanelListItem: View {
    let panel: Panel
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            /// Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 40, height: 50)
                
                if let imageURL = panel.generatedImageURL,
                   let nsImage = NSImage(contentsOf: imageURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Panel \(panel.order + 1)")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text(panel.prompt.isEmpty ? "No description" : panel.prompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                if case .generating = panel.generationStatus {
                    ProgressView(value: panel.generationProgress)
                        .progressViewStyle(.linear)
                        .scaleEffect(x: 1, y: 0.5)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    var statusIcon: String {
        switch panel.generationStatus {
        case .pending: return "clock"
        case .generating: return "sparkles"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .cached: return "checkmark.circle"
        }
    }
    
    var statusColor: Color {
        switch panel.generationStatus {
        case .pending: return .secondary
        case .generating: return .blue
        case .completed: return .green
        case .failed: return .red
        case .cached: return .green
        }
    }
}

struct EditorToolbar: View {
    @ObservedObject var viewModel: MangaEditorViewModel
    let selectedPanelCount: Int
    
    var body: some View {
        HStack {
            /// Project info
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.manga.title)
                    .font(.headline)
                HStack(spacing: 12) {
                    Label("\(viewModel.manga.panelCount) panels", systemImage: "rectangle.grid.2x2")
                    Label("\(viewModel.manga.totalPages) pages", systemImage: "doc")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            /// Actions
            HStack(spacing: 12) {
                if viewModel.isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                }
                
                Button(action: { Task { await viewModel.save() } }) {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .disabled(viewModel.isSaving)
                
                Button(action: { viewModel.addPanel() }) {
                    Label("Add Panel", systemImage: "plus.rectangle")
                }
                
                if viewModel.canUndo || viewModel.canRedo {
                    Divider()
                        .frame(height: 20)
                    
                    Button(action: { viewModel.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!viewModel.canUndo)
                    .help("Undo")
                    
                    Button(action: { viewModel.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(!viewModel.canRedo)
                    .help("Redo")
                }
            }
            .buttonStyle(.bordered)
        }
    }
}

struct EmptyCanvasView: View {
    let onAddPanel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "rectangle.dashed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Panels Yet")
                .font(.title2)
            
            Text("Add your first panel to start creating your manga")
                .foregroundColor(.secondary)
            
            Button(action: onAddPanel) {
                Label("Add Panel", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InspectorView: View {
    @ObservedObject var viewModel: MangaEditorViewModel
    @Binding var selectedPanelID: UUID?
    
    var body: some View {
        VStack(spacing: 0) {
            /// Header
            HStack {
                Text("Inspector")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            /// Content
            if let panelID = selectedPanelID,
               let panel = viewModel.manga.panels.first(where: { $0.id == panelID }) {
                PanelInspector(panel: panel, viewModel: viewModel)
            } else {
                ProjectInspector(manga: viewModel.manga)
            }
        }
    }
}

struct ProjectInspector: View {
    let manga: Manga
    
    var body: some View {
        Form {
            Section("Project") {
                LabeledContent("Title", value: manga.title)
                LabeledContent("Creator", value: manga.creator)
                LabeledContent("Style", value: manga.metadata.style.name)
            }
            
            Section("Statistics") {
                LabeledContent("Panels", value: "\(manga.panelCount)")
                LabeledContent("Pages", value: "\(manga.totalPages)")
                LabeledContent("Characters", value: "\(manga.characters.count)")
            }
            
            Section("Dates") {
                LabeledContent("Created", value: manga.createdDate.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Modified", value: manga.modifiedDate.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

struct PanelInspector: View {
    let panel: Panel
    @ObservedObject var viewModel: MangaEditorViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                PanelDetailView(panel: panel, viewModel: viewModel)
            }
            .padding()
        }
    }
}
