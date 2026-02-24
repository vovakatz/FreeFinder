import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                pathComponents: viewModel.pathComponents,
                onNavigate: { viewModel.navigate(to: $0) },
                canGoBack: viewModel.canGoBack,
                canGoForward: viewModel.canGoForward,
                onGoBack: { viewModel.goBack() },
                onGoForward: { viewModel.goForward() },
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
