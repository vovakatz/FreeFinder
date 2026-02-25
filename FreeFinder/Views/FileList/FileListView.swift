import SwiftUI
import AppKit

struct FileListView: View {
    let displayItems: [DisplayItem]
    let sortCriteria: SortCriteria
    let isLoading: Bool
    let errorMessage: String?
    let expandedFolders: Set<URL>
    let onSort: (SortField) -> Void
    let onOpen: (FileItem) -> Void
    let onToggleExpand: (FileItem) -> Void
    var viewMode: ViewMode = .list

    var onCopy: (Set<URL>) -> Void = { _ in }
    var onCut: (Set<URL>) -> Void = { _ in }
    var onPaste: () -> Void = {}
    var onMoveToTrash: (Set<URL>) -> Void = { _ in }
    var onRequestDelete: (Set<URL>) -> Void = { _ in }
    var onConfirmDelete: () -> Void = {}
    var onConfirmOverwritePaste: () -> Void = {}
    var canPaste: Bool = false
    var conflictingNames: [String] = []
    @Binding var showOverwriteConfirmation: Bool
    var needsFullDiskAccess: Bool = false
    var onOpenFullDiskAccessSettings: () -> Void = {}
    var onCreateFolder: (String) -> Void = { _ in }
    var onCreateFile: (String) -> Void = { _ in }
    @Binding var showDeleteConfirmation: Bool

    @Binding var selection: Set<FileItem.ID>
    @State private var dateWidth: CGFloat = 150
    @State private var sizeWidth: CGFloat = 80
    @State private var kindWidth: CGFloat = 120
    @State private var doubleClickProxy = DoubleClickProxy()
    @State private var showNewFolderSheet = false
    @State private var showNewFileSheet = false
    @State private var newItemName = ""

    var body: some View {
        let _ = doubleClickProxy.updateAction { [selection, displayItems, onOpen] in
            guard let selectedURL = selection.first,
                  let displayItem = displayItems.first(where: { $0.id == selectedURL }) else { return }
            onOpen(displayItem.fileItem)
        }

        VStack(spacing: 0) {
            if viewMode == .list {
                ColumnHeaderView(
                    sortCriteria: sortCriteria,
                    onSort: onSort,
                    dateWidth: $dateWidth,
                    sizeWidth: $sizeWidth,
                    kindWidth: $kindWidth
                )
                Divider()
            }

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: needsFullDiskAccess ? "lock.shield" : "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .foregroundStyle(.secondary)
                    if needsFullDiskAccess {
                        Button("Open System Settings") {
                            onOpenFullDiskAccessSettings()
                        }
                    }
                }
                Spacer()
            } else if displayItems.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "folder")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("This folder is empty")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                contentView
            }
        }
        .alert("Delete Permanently?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onConfirmDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the selected item(s). This action cannot be undone.")
        }
        .alert("Overwrite Existing Items?", isPresented: $showOverwriteConfirmation) {
            Button("Overwrite", role: .destructive) {
                onConfirmOverwritePaste()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            let names = conflictingNames.joined(separator: ", ")
            Text("The destination already contains: \(names). Do you want to overwrite?")
        }
        .sheet(isPresented: $showNewFolderSheet) {
            NewItemSheet(title: "New Folder", placeholder: "Folder name") { name in
                onCreateFolder(name)
            }
        }
        .sheet(isPresented: $showNewFileSheet) {
            NewItemSheet(title: "New File", placeholder: "File name") { name in
                onCreateFile(name)
            }
        }
        .onAppear { doubleClickProxy.startMonitoring() }
        .onDisappear { doubleClickProxy.stopMonitoring() }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewMode == .list {
            listView
        } else {
            gridView
        }
    }

    private var listView: some View {
        List(displayItems, selection: $selection) { displayItem in
            FileRowView(
                item: displayItem.fileItem,
                dateWidth: dateWidth,
                sizeWidth: sizeWidth,
                kindWidth: kindWidth,
                depth: displayItem.depth,
                isExpanded: expandedFolders.contains(displayItem.fileItem.url),
                onToggleExpand: { onToggleExpand(displayItem.fileItem) }
            )
            .listRowInsets(EdgeInsets(top: 2, leading: 4, bottom: 2, trailing: 4))
            .draggable(displayItem.fileItem.url)
            .tag(displayItem.id)
            .contextMenu {
                contextMenuContent(for: displayItem)
            }
        }
        .listStyle(.plain)
        .alternatingRowBackgrounds()
        .environment(\.defaultMinListRowHeight, 20)
        .onHover { doubleClickProxy.isHovered = $0 }
        .onKeyPress(.return) {
            openSelected()
            return .handled
        }
        .contextMenu { backgroundContextMenu }
    }

    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 120))],
                spacing: 8
            ) {
                ForEach(displayItems) { displayItem in
                    FileIconView(
                        item: displayItem.fileItem,
                        isSelected: selection.contains(displayItem.id)
                    )
                    .onTapGesture {
                        selection = [displayItem.id]
                    }
                    .draggable(displayItem.fileItem.url)
                    .tag(displayItem.id)
                    .contextMenu {
                        contextMenuContent(for: displayItem)
                    }
                }
            }
            .padding(8)
        }
        .onHover { doubleClickProxy.isHovered = $0 }
        .onKeyPress(.return) {
            openSelected()
            return .handled
        }
        .contextMenu { backgroundContextMenu }
    }

    @ViewBuilder
    private var backgroundContextMenu: some View {
        Button("New Folder...") {
            newItemName = ""
            showNewFolderSheet = true
        }
        Button("New File...") {
            newItemName = ""
            showNewFileSheet = true
        }
        if canPaste {
            Divider()
            Button("Paste") {
                onPaste()
            }
            .keyboardShortcut("v", modifiers: .command)
        }
    }

    @ViewBuilder
    private func contextMenuContent(for displayItem: DisplayItem) -> some View {
        let targetURLs = selection.contains(displayItem.id) ? selection : [displayItem.id]

        Button("Open") {
            selection = targetURLs
            onOpen(displayItem.fileItem)
        }
        Button("Show in Finder") {
            selection = targetURLs
            NSWorkspace.shared.activateFileViewerSelecting([displayItem.fileItem.url])
        }

        Divider()

        Button("Cut") {
            selection = targetURLs
            onCut(targetURLs)
        }
        .keyboardShortcut("x", modifiers: .command)

        Button("Copy") {
            selection = targetURLs
            onCopy(targetURLs)
        }
        .keyboardShortcut("c", modifiers: .command)

        Button("Paste") {
            onPaste()
        }
        .keyboardShortcut("v", modifiers: .command)
        .disabled(!canPaste)

        Divider()

        Button("Move to Trash") {
            selection = targetURLs
            onMoveToTrash(targetURLs)
        }
        .keyboardShortcut(.delete, modifiers: .command)

        Button("Delete...", role: .destructive) {
            selection = targetURLs
            onRequestDelete(targetURLs)
        }
    }

    private func openSelected() {
        guard let selectedURL = selection.first,
              let displayItem = displayItems.first(where: { $0.id == selectedURL }) else { return }
        onOpen(displayItem.fileItem)
    }
}

private struct NewItemSheet: View {
    let title: String
    let placeholder: String
    let onCreate: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
            TextField(placeholder, text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    if !name.isEmpty {
                        onCreate(name)
                        dismiss()
                    }
                }
            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Create") {
                    onCreate(name)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty)
            }
        }
        .padding(20)
        .frame(width: 300)
        .onAppear { isFocused = true }
    }
}

private class DoubleClickProxy {
    var onFire: (() -> Void)?
    var isHovered = false
    var monitor: Any?

    func updateAction(_ action: @escaping () -> Void) {
        onFire = action
    }

    func startMonitoring() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            if event.clickCount == 2, self?.isHovered == true {
                self?.onFire?()
            }
            return event
        }
    }

    func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }
}
