import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel
    var showLeftSidebar: Bool = true
    var onToggleLeftSidebar: () -> Void = {}
    var showRightPanel: Bool = true
    var onToggleRightPanel: () -> Void = {}
    var showBottomPanel: Bool = true
    var onToggleBottomPanel: () -> Void = {}

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

            VSplitView {
                GeometryReader { _ in
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
                        showDeleteConfirmation: $viewModel.showDeleteConfirmation,
                        selection: $viewModel.selectedItems
                    )
                }
                .frame(minHeight: 100)

                if showBottomPanel {
                    BottomPanelView(currentDirectory: viewModel.currentURL)
                }
            }

            Divider()

            StatusBarView(
                selectionCount: viewModel.selectedItems.count,
                volumeStatusText: viewModel.volumeStatusText
            )
        }
    }
}
