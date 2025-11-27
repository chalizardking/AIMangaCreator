import SwiftUI

struct ProjectBrowserView: View {
    @ObservedObject var viewModel: ProjectManagerViewModel
    @State private var showingNewProjectSheet = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading Projects...")
            } else if viewModel.projects.isEmpty {
                VStack {
                    Text("No Projects Found")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Button("Create New Project") {
                        showingNewProjectSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                List(viewModel.projects) { project in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(project.title)
                                .font(.headline)
                            Text("Last modified: \(project.modifiedDate.formatted())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Open") {
                            viewModel.openProject(project)
                        }
                    }
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            Task {
                                await viewModel.deleteProject(project)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewProjectSheet = true }) {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(viewModel: viewModel)
        }
    }
}

struct NewProjectSheet: View {
    @ObservedObject var viewModel: ProjectManagerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var selectedStyle: MangaStyle = MangaStyle.allCases.first!
    
    var body: some View {
        Form {
            TextField("Project Title", text: $title)
            Picker("Style", selection: $selectedStyle) {
                ForEach(MangaStyle.allCases, id: \.self) { style in
                    Text(style.name).tag(style)
                }
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Create") {
                    Task {
                        await viewModel.createProject(title: title, style: selectedStyle)
                        dismiss()
                    }
                }
                .disabled(title.isEmpty)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
    }
}
