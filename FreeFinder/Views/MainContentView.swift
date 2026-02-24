import SwiftUI

struct MainContentView: View {
    @Bindable var viewModel: FileListViewModel

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                pathComponents: viewModel.pathComponents,
                onNavigate: { viewModel.navigate(to: $0) }
            )
            Divider()

            FileListView(
                items: viewModel.items,
                sortCriteria: viewModel.sortCriteria,
                isLoading: viewModel.isLoading,
                errorMessage: viewModel.errorMessage,
                onSort: { viewModel.toggleSort(by: $0) },
                onOpen: { viewModel.openItem($0) }
            )
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: { viewModel.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.canGoBack)

                Button(action: { viewModel.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.canGoForward)
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showHiddenFiles.toggle()
                    Task { await viewModel.reload() }
                } label: {
                    Image(systemName: viewModel.showHiddenFiles ? "eye" : "eye.slash")
                }
                .help(viewModel.showHiddenFiles ? "Hide hidden files" : "Show hidden files")
            }
        }
    }
}
