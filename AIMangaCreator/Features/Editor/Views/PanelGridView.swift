import SwiftUI

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
