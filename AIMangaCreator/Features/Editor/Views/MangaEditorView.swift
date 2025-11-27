import SwiftUI

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

struct PanelListView: View {
    let panels: [Panel]
    @Binding var selectedID: UUID?
    
    var body: some View {
        List(panels, selection: $selectedID) { panel in
            Text("Panel \(panel.order + 1)")
                .tag(panel.id)
        }
    }
}
