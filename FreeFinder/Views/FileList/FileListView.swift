import SwiftUI
import AppKit

struct FileListView: View {
    let items: [FileItem]
    let sortCriteria: SortCriteria
    let isLoading: Bool
    let errorMessage: String?
    let onSort: (SortField) -> Void
    let onOpen: (FileItem) -> Void

    @State private var selection: Set<FileItem.ID> = []
    @State private var dateWidth: CGFloat = 150
    @State private var sizeWidth: CGFloat = 80
    @State private var kindWidth: CGFloat = 120
    @State private var doubleClickProxy = DoubleClickProxy()

    var body: some View {
        let _ = doubleClickProxy.updateAction { [selection, items, onOpen] in
            guard let selectedURL = selection.first,
                  let item = items.first(where: { $0.id == selectedURL }) else { return }
            onOpen(item)
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
            } else if items.isEmpty {
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
                List(items, selection: $selection) { item in
                    FileRowView(
                        item: item,
                        dateWidth: dateWidth,
                        sizeWidth: sizeWidth,
                        kindWidth: kindWidth
                    )
                    .draggable(item.url)
                    .tag(item.id)
                }
                .listStyle(.plain)
                .alternatingRowBackgrounds()
                .environment(\.defaultMinListRowHeight, 24)
                .onHover { doubleClickProxy.isHovered = $0 }
                .onAppear { doubleClickProxy.startMonitoring() }
                .onDisappear { doubleClickProxy.stopMonitoring() }
                .onKeyPress(.return) {
                    openSelected()
                    return .handled
                }
                .contextMenu {
                    if let selectedItem = items.first(where: { selection.contains($0.id) }) {
                        Button("Open") { onOpen(selectedItem) }
                        Button("Show in Finder") {
                            NSWorkspace.shared.activateFileViewerSelecting([selectedItem.url])
                        }
                    }
                }
            }
        }
    }

    private func openSelected() {
        guard let selectedURL = selection.first,
              let item = items.first(where: { $0.id == selectedURL }) else { return }
        onOpen(item)
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
