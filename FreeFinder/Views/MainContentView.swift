import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel
    var showLeftSidebar: Bool = true
    var onToggleLeftSidebar: () -> Void = {}
    var showRightPanel: Bool = true
    var onToggleRightPanel: () -> Void = {}

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
                viewMode: viewModel.viewMode,
                onSetViewMode: { viewModel.viewMode = $0 },
                showHiddenFiles: viewModel.showHiddenFiles,
                onToggleHidden: {
                    viewModel.showHiddenFiles.toggle()
                    Task { await viewModel.reload() }
                }
            )
            Divider()

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
                selection: $viewModel.selectedItems
            )

            Divider()

            StatusBarView(
                selectionCount: viewModel.selectedItems.count,
                volumeStatusText: viewModel.volumeStatusText
            )
        }
    }
}
