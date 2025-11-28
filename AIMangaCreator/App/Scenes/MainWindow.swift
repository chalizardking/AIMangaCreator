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
                    NotificationCenter.default.post(name: .newProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    NotificationCenter.default.post(name: .saveProject, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Export") {
                    NotificationCenter.default.post(name: .exportProject, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }
    }
}

// MARK: - Notification Names
/// Notification names for menu commands
extension Notification.Name {
    static let newProject = Notification.Name("newProject")
    static let saveProject = Notification.Name("saveProject")
    static let exportProject = Notification.Name("exportProject")
}

// MARK: - Main Content View
/// Main content area
struct ContentView: View {
    @StateObject private var projectVM = ProjectManagerViewModel()
    @State private var selectedView: AppView = .browser
    @State private var showingNewProjectSheet = false
    
    enum AppView: Hashable {
        case browser
        case editor
        case generator
        case settings
    }
    
    var body: some View {
        NavigationSplitView {
            /// Sidebar
            SidebarView(
                selectedView: $selectedView,
                projectCount: projectVM.projects.count
            )
        } detail: {
            /// Main content area
            Group {
                switch selectedView {
                case .browser:
                    ProjectBrowserView(viewModel: projectVM)
                case .editor:
                    if let project = projectVM.selectedProject {
                        MangaEditorView(viewModel: MangaEditorViewModel(manga: project))
                            /// Force view refresh when project changes
                            .id(project.id)
                    } else {
                        EmptyProjectView(onCreateProject: {
                            showingNewProjectSheet = true
                        })
                    }
                case .generator:
                    GeneratorView(viewModel: PanelGeneratorViewModel())
                case .settings:
                    SettingsView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: projectVM.selectedProject?.id) { _, newValue in
            if newValue != nil {
                selectedView = .editor
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(viewModel: projectVM)
        }
        .onReceive(NotificationCenter.default.publisher(for: .newProject)) { _ in
            showingNewProjectSheet = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveProject)) { _ in
            if let project = projectVM.selectedProject {
                Task {
                    let vm = MangaEditorViewModel(manga: project)
                    await vm.save()
                }
            }
        }
    }
}

struct EmptyProjectView: View {
    let onCreateProject: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Project Selected")
                .font(.title)
                .foregroundColor(.primary)
            
            Text("Create a new project or select an existing one from the sidebar")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: onCreateProject) {
                Label("Create New Project", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
}

// MARK: - Sidebar Navigation
/// Sidebar navigation
struct SidebarView: View {
    @Binding var selectedView: ContentView.AppView
    let projectCount: Int
    
    var body: some View {
        List(selection: $selectedView) {
            Section("Navigation") {
                Button(action: { selectedView = .browser }) {
                    Label("Projects", systemImage: "folder.fill")
                }
                .tag(ContentView.AppView.browser)
                
                Button(action: { selectedView = .editor }) {
                    Label("Editor", systemImage: "pencil.and.outline")
                }
                .tag(ContentView.AppView.editor)
                
                Button(action: { selectedView = .generator }) {
                    Label("Generator", systemImage: "wand.and.stars")
                }
                .tag(ContentView.AppView.generator)
                
                Button(action: { selectedView = .settings }) {
                    Label("Settings", systemImage: "gear")
                }
                .tag(ContentView.AppView.settings)
            }
            
            Section("Info") {
                LabeledContent("Projects", value: "\(projectCount)")
                    .font(.caption)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("AI Manga Creator")
    }
}
