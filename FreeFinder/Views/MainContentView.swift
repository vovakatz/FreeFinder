import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel
    var showBottomPanel: Bool = true
    @Binding var bottomPanelWidget: WidgetType
    @Binding var selectedItems: Set<URL>
    var isActive: Bool = true
    var onActivate: (() -> Void)?

    @State private var bottomPanelHeight: CGFloat?
    @State private var totalHeight: CGFloat = 0
    @State private var showNewFolderSheet = false
    @State private var showNewFileSheet = false

    private var effectiveBottomHeight: CGFloat {
        bottomPanelHeight ?? (totalHeight * 0.3)
    }

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                pathComponents: viewModel.pathComponents,
                onNavigate: { viewModel.navigate(to: $0) },
                canGoBack: viewModel.canGoBack,
                canGoForward: viewModel.canGoForward,
                onGoBack: { viewModel.goBack() },
                onGoForward: { viewModel.goForward() },
                onNewFolder: { showNewFolderSheet = true },
                onNewFile: { showNewFileSheet = true }
            )
            Divider()

            GeometryReader { geo in
                let _ = updateTotalHeight(geo.size.height)
                VStack(spacing: 0) {
                    FileListView(
                        displayItems: viewModel.displayItems,
                        sortCriteria: viewModel.sortCriteria,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage,
                        expandedFolders: viewModel.expandedFolders,
                        onSort: { viewModel.toggleSort(by: $0) },
                        onOpen: { viewModel.openItem($0) },
                        onToggleExpand: { viewModel.toggleExpanded($0) },
                        viewMode: viewModel.viewMode,
                        onCopy: { viewModel.copyItems($0) },
                        onCut: { viewModel.cutItems($0) },
                        onPaste: { viewModel.pasteItems() },
                        onMoveToTrash: { viewModel.moveToTrash($0) },
                        onRequestDelete: { viewModel.requestDelete($0) },
                        onConfirmDelete: { viewModel.confirmDelete() },
                        onConfirmOverwritePaste: { viewModel.confirmOverwritePaste() },
                        canPaste: viewModel.clipboard != nil,
                        conflictingNames: viewModel.conflictingNames,
                        showOverwriteConfirmation: $viewModel.showOverwriteConfirmation,
                        needsFullDiskAccess: viewModel.needsFullDiskAccess,
                        onOpenFullDiskAccessSettings: { viewModel.openFullDiskAccessSettings() },
                        onCreateFolder: { viewModel.createFolder(name: $0) },
                        onCreateFile: { viewModel.createFile(name: $0) },
                        onRename: { viewModel.renameItem(at: $0, to: $1) },
                        showDeleteConfirmation: $viewModel.showDeleteConfirmation,
                        onDrop: { viewModel.requestMoveItems($0) },
                        onDropIntoFolder: { urls, folder in viewModel.requestMoveItems(urls, destination: folder) },
                        onConfirmMove: { viewModel.confirmMoveItems() },
                        pendingMoveNames: viewModel.pendingMoveNames,
                        pendingMoveDestinationName: viewModel.pendingMoveDestinationName,
                        showMoveConfirmation: $viewModel.showMoveConfirmation,
                        selection: $viewModel.selectedItems,
                        showNewFolderSheet: $showNewFolderSheet,
                        showNewFileSheet: $showNewFileSheet
                    )

                    if showBottomPanel {
                        SplitDragHandle(height: Binding(
                            get: { effectiveBottomHeight },
                            set: { bottomPanelHeight = $0 }
                        ), totalHeight: geo.size.height)

                        BottomPanelView(currentDirectory: viewModel.currentURL, selectedItems: $selectedItems, widgetType: $bottomPanelWidget)
                            .frame(height: effectiveBottomHeight)
                    }
                }
            }

            Divider()

            StatusBarView(
                selectionCount: viewModel.selectedItems.count,
                volumeStatusText: viewModel.volumeStatusText
            )
        }
        .overlay(alignment: .top) {
            if isActive {
                Color.accentColor
                    .frame(height: 2)
            }
        }
        .background {
            MouseDownDetector { onActivate?() }
        }
    }

    private func updateTotalHeight(_ h: CGFloat) {
        if totalHeight != h {
            DispatchQueue.main.async { totalHeight = h }
        }
    }
}

private struct MouseDownDetector: NSViewRepresentable {
    var onMouseDown: () -> Void

    func makeNSView(context: Context) -> MouseDownNSView {
        let view = MouseDownNSView()
        view.onMouseDown = onMouseDown
        return view
    }

    func updateNSView(_ nsView: MouseDownNSView, context: Context) {
        nsView.onMouseDown = onMouseDown
    }

    class MouseDownNSView: NSView {
        var onMouseDown: (() -> Void)?
        private var monitor: Any?

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard window != nil, monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
                guard let self, let window = self.window, event.window === window else { return event }
                let locationInView = self.convert(event.locationInWindow, from: nil)
                if self.bounds.contains(locationInView) {
                    self.onMouseDown?()
                }
                return event
            }
        }

        override func removeFromSuperview() {
            removeMonitor()
            super.removeFromSuperview()
        }

        private func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            removeMonitor()
        }
    }
}

private struct SplitDragHandle: View {
    @Binding var height: CGFloat
    let totalHeight: CGFloat

    @State private var dragStartHeight: CGFloat?

    var body: some View {
        Rectangle()
            .fill(Color(nsColor: .separatorColor))
            .frame(height: 5)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        if dragStartHeight == nil {
                            dragStartHeight = height
                        }
                        let newHeight = (dragStartHeight ?? height) - value.translation.height
                        height = max(50, min(newHeight, totalHeight - 100))
                    }
                    .onEnded { _ in
                        dragStartHeight = nil
                    }
            )
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeUpDown.push()
                } else {
                    NSCursor.pop()
                }
            }
    }
}
