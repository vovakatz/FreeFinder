import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel
    var showLeftSidebar: Bool = true
    var onToggleLeftSidebar: () -> Void = {}
    var showRightPanel: Bool = true
    var onToggleRightPanel: () -> Void = {}
    var showBottomPanel: Bool = true
    var onToggleBottomPanel: () -> Void = {}
    @Binding var bottomPanelWidget: WidgetType
    @Binding var selectedItems: Set<URL>

    @State private var bottomPanelHeight: CGFloat?
    @State private var totalHeight: CGFloat = 0

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
                showLeftSidebar: showLeftSidebar,
                onToggleLeftSidebar: onToggleLeftSidebar,
                showRightPanel: showRightPanel,
                onToggleRightPanel: onToggleRightPanel,
                showBottomPanel: showBottomPanel,
                onToggleBottomPanel: onToggleBottomPanel,
                viewMode: viewModel.viewMode,
                onSetViewMode: { viewModel.viewMode = $0 },
                showHiddenFiles: viewModel.showHiddenFiles,
                onToggleHidden: {
                    viewModel.showHiddenFiles.toggle()
                    Task { await viewModel.reload() }
                }
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
                        selection: $viewModel.selectedItems
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
    }

    private func updateTotalHeight(_ h: CGFloat) {
        if totalHeight != h {
            DispatchQueue.main.async { totalHeight = h }
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
