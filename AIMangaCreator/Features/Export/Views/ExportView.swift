import SwiftUI

struct ExportView: View {
    @StateObject private var viewModel = ExportViewModel()

    /// This should be passed in from the parent view when the user selects a manga to export
    let manga: Manga?

    init(manga: Manga? = nil) {
        self.manga = manga
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                /// Header
                VStack(spacing: 8) {
                    Text("Export Manga")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    if let manga = viewModel.currentManga {
                        VStack(spacing: 4) {
                            Text(manga.title)
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("\(manga.panelCount) panels • \(manga.totalPages) pages")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("No manga selected")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top)

                /// Export Options
                if viewModel.currentManga != nil {
                    exportOptionsSection
                }

                /// Export Progress
                if viewModel.isExporting {
                    exportProgressSection
                }

                /// Export Status
                if !viewModel.exportStatus.isEmpty && !viewModel.isExporting {
                    statusSection
                }

                /// Action Buttons
                if viewModel.currentManga != nil {
                    actionButtonsSection
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
            .frame(minWidth: 600, minHeight: 500)
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            if let manga = manga {
                viewModel.setCurrentManga(manga)
            }
        }
    }

    private var exportOptionsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Export Options", icon: "slider.horizontal.3")

            VStack(spacing: 16) {
                /// Format Selection
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Format")
                            .font(.headline)
                        Text("Choose the export file format")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Format", selection: $viewModel.selectedFormat) {
                            ForEach(ExportFormat.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality")
                            .font(.headline)
                        Text("Resolution and detail level")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Quality", selection: $viewModel.selectedQuality) {
                            ForEach(ExportQuality.allCases) { quality in
                                Text(quality.rawValue).tag(quality)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Layout")
                            .font(.headline)
                        Text("Panels per page arrangement")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Layout", selection: $viewModel.selectedLayout) {
                            ForEach(ExportLayout.allCases) { layout in
                                Text(layout.rawValue).tag(layout)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 160)
                    }
                }
            }
            .padding()
            .background(Color(.textBackgroundColor).opacity(0.5))
            .cornerRadius(8)

            /// Preview information
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text("Export Preview")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let config = exportConfigPreview {
                        Text("Format: \(config.format.rawValue) • Resolution: ~\(config.quality.resolution)px • \(config.layout.panelsPerPage) panels/page")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }

    private var exportProgressSection: some View {
        VStack(spacing: 12) {
            ProgressView(value: viewModel.exportProgress)
                .progressViewStyle(.linear)
                .frame(height: 20)

            HStack {
                Text(viewModel.exportStatus)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Button(action: viewModel.cancelExport) {
                    Text("Cancel")
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.textBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: viewModel.exportStatus.contains("failed") ? "exclamationmark.triangle" : "checkmark.circle")
                    .foregroundColor(viewModel.exportStatus.contains("failed") ? .red : .green)
                Text(viewModel.exportStatus)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
        }
        .padding()
        .background(viewModel.exportStatus.contains("failed") ? Color.red.opacity(0.1) : Color.green.opacity(0.1))
        .cornerRadius(8)
    }

    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Spacer()

            Button(action: {
                /// Clear status when re-selecting options
                viewModel.exportStatus = ""
            }) {
                Text("Reset Options")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .foregroundColor(.secondary)
            }

            Button(action: {
                Task {
                    await viewModel.export()
                }
            }) {
                HStack {
                    Image(systemName: viewModel.isExporting ? "arrow.down.circle.fill" : "arrow.down.circle")
                    Text(viewModel.isExporting ? "Exporting..." : "Export Manga")
                }
                .frame(minWidth: 120)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(viewModel.isExporting ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(viewModel.isExporting)
        }
        .padding(.top)
    }

    private var exportConfigPreview: (format: ExportFormat, quality: ExportQuality, layout: ExportLayout)? {
        guard viewModel.currentManga != nil else { return nil }
        return (viewModel.selectedFormat, viewModel.selectedQuality, viewModel.selectedLayout)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
        }
    }
}
