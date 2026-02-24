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

    @Binding var selection: Set<FileItem.ID>
    @State private var dateWidth: CGFloat = 150
    @State private var sizeWidth: CGFloat = 80
    @State private var kindWidth: CGFloat = 120
    @State private var doubleClickProxy = DoubleClickProxy()

    var body: some View {
        let _ = doubleClickProxy.updateAction { [selection, displayItems, onOpen] in
            guard let selectedURL = selection.first,
                  let displayItem = displayItems.first(where: { $0.id == selectedURL }) else { return }
            onOpen(displayItem.fileItem)
        }

        VStack(spacing: 0) {
            ColumnHeaderView(
                sortCriteria: sortCriteria,
                onSort: onSort,
                dateWidth: $dateWidth,
                sizeWidth: $sizeWidth,
                kindWidth: $kindWidth
            )
            Divider()

            if isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = errorMessage {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .foregroundStyle(.secondary)
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
                    .draggable(displayItem.fileItem.url)
                    .tag(displayItem.id)
                }
                .listStyle(.plain)
                .alternatingRowBackgrounds()
                .environment(\.defaultMinListRowHeight, 22)
                .onHover { doubleClickProxy.isHovered = $0 }
                .onAppear { doubleClickProxy.startMonitoring() }
                .onDisappear { doubleClickProxy.stopMonitoring() }
                .onKeyPress(.return) {
                    openSelected()
                    return .handled
                }
                .contextMenu {
                    if let selectedDisplay = displayItems.first(where: { selection.contains($0.id) }) {
                        Button("Open") { onOpen(selectedDisplay.fileItem) }
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([selectedDisplay.fileItem.url])
                        }
                    }
                }
            }
        }
    }

    private func openSelected() {
        guard let selectedURL = selection.first,
              let displayItem = displayItems.first(where: { $0.id == selectedURL }) else { return }
        onOpen(displayItem.fileItem)
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
