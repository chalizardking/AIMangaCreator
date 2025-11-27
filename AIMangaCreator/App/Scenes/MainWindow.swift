import SwiftUI

struct MainWindow: Scene {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Project") {
                    // Trigger new project action
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") { /* Save logic */ }
                    .keyboardShortcut("s", modifiers: .command)
                
                Button("Export") { /* Export logic */ }
                    .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

// Main content area
struct ContentView: View {
    @StateObject private var projectVM = ProjectManagerViewModel()
    @State private var selectedView: AppView = .browser
    
    enum AppView {
        case browser
        case editor
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            SidebarView(selectedView: $selectedView)
        } detail: {
            // Main content area
            switch selectedView {
            case .browser:
                ProjectBrowserView(viewModel: projectVM)
            case .editor:
                if let project = projectVM.selectedProject {
                    // We create a new VM for the editor. 
                    // In a real app, we might want to manage the lifecycle of this VM better.
                    let editorVM = MangaEditorViewModel(manga: project)
                    MangaEditorView(viewModel: editorVM)
                } else {
                    EmptyProjectView()
                }
            case .settings:
                Text("Settings View Placeholder")
            }
        }
        .onChange(of: projectVM.selectedProject?.id) { _ in
            if projectVM.selectedProject != nil {
                selectedView = .editor
            }
        }
    }
}

struct EmptyProjectView: View {
    var body: some View {
        VStack {
            Text("No Project Selected")
                .font(.title)
                .foregroundColor(.secondary)
            Text("Select a project from the browser or create a new one.")
                .foregroundColor(.secondary)
        }
    }
}

// Sidebar navigation
struct SidebarView: View {
    @Binding var selectedView: ContentView.AppView
    @State private var expandProjects = true
    
    var body: some View {
        List(selection: $selectedView) {
            Section("Navigation") {
                NavigationLink(value: ContentView.AppView.browser) {
                    Label("Projects", systemImage: "folder.fill")
                }
                
                NavigationLink(value: ContentView.AppView.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            NavigationLink(value: ContentView.AppView.editor) {
                Label("Editor", systemImage: "pencil.and.outline")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AI Manga Creator")
    }
}
