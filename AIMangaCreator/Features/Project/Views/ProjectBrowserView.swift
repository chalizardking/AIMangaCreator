import SwiftUI

struct ProjectBrowserView: View {
    @ObservedObject var viewModel: ProjectManagerViewModel
    @State private var showingNewProjectSheet = false
    @State private var searchText = ""
    @State private var sortOrder: SortOrder = .dateModified
    
    enum SortOrder: String, CaseIterable {
        case dateModified = "Last Modified"
        case dateCreated = "Date Created"
        case titleAscending = "Title (A-Z)"
        case titleDescending = "Title (Z-A)"
    }
    
    var filteredAndSortedProjects: [Manga] {
        let filtered = searchText.isEmpty
            ? viewModel.projects
            : viewModel.projects.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        
        switch sortOrder {
        case .dateModified:
            return filtered.sorted { $0.modifiedDate > $1.modifiedDate }
        case .dateCreated:
            return filtered.sorted { $0.createdDate > $1.createdDate }
        case .titleAscending:
            return filtered.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .titleDescending:
            return filtered.sorted { $0.title.localizedCompare($1.title) == .orderedDescending }
        }
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack {
                    ProgressView("Loading Projects...")
                        .controlSize(.large)
                }
            } else if viewModel.projects.isEmpty {
                EmptyStateView(onCreateProject: { showingNewProjectSheet = true })
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredAndSortedProjects) { project in
                            ProjectCard(
                                project: project,
                                onOpen: { viewModel.openProject(project) },
                                onDuplicate: {
                                    Task { await viewModel.duplicateProject(project) }
                                },
                                onDelete: {
                                    Task { await viewModel.deleteProject(project) }
                                }
                            )
                        }
                    }
                    .padding()
                }
                .searchable(text: $searchText, prompt: "Search projects...")
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Text(order.rawValue).tag(order)
                    }
                }
                .pickerStyle(.menu)
                
                Button(action: { showingNewProjectSheet = true }) {
                    Label("New Project", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingNewProjectSheet) {
            NewProjectSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { _ in
            Button("OK") { viewModel.error = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}

struct EmptyStateView: View {
    let onCreateProject: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Projects Found")
                .font(.title)
                .foregroundColor(.primary)
            
            Text("Create your first manga project to get started")
                .font(.body)
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

struct ProjectCard: View {
    let project: Manga
    let onOpen: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            /// Thumbnail or placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 120, height: 160)
                
                if let firstPanel = project.panels.first,
                   let imageURL = firstPanel.generatedImageURL,
                   let nsImage = NSImage(contentsOf: imageURL) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                }
            }
            
            /// Project info
            VStack(alignment: .leading, spacing: 8) {
                Text(project.title)
                    .font(.headline)
                
                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    Label("\(project.panelCount) panels", systemImage: "rectangle.grid.2x2")
                    Label("\(project.totalPages) pages", systemImage: "doc")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack {
                    Text("Modified: \(project.modifiedDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if !project.metadata.tags.isEmpty {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(project.metadata.tags.prefix(3).joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            /// Actions
            VStack(spacing: 8) {
                Button(action: onOpen) {
                    Label("Open", systemImage: "arrow.right.circle.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderedProminent)
                
                Menu {
                    Button("Open") { onOpen() }
                    Button("Duplicate", action: onDuplicate)
                    Divider()
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .confirmationDialog(
            "Delete Project",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete '\(project.title)'? This action cannot be undone.")
        }
    }
}

struct NewProjectSheet: View {
    @ObservedObject var viewModel: ProjectManagerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var selectedStyle: MangaStyle = MangaStyle.allCases.first!
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Project Title", text: $title)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                Section("Style") {
                    Picker("Manga Style", selection: $selectedStyle) {
                        ForEach(MangaStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading) {
                                Text(style.name)
                                    .font(.headline)
                                Text(style.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
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
        }
        .frame(width: 500, height: 400)
    }
}
