import SwiftUI

struct ContentView: View {
    @State private var fileListVM = FileListViewModel()
    @State private var sidebarVM = SidebarViewModel()
    @State private var sidebarSelection: URL?
    @State private var showLeftSidebar: Bool = true
    @State private var showRightPanel: Bool = true

    var body: some View {
        HSplitView {
            if showLeftSidebar {
                SidebarView(viewModel: sidebarVM, selection: $sidebarSelection)
                    .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
            }
            MainContentView(
                viewModel: fileListVM,
                showLeftSidebar: showLeftSidebar,
                onToggleLeftSidebar: { showLeftSidebar.toggle() },
                showRightPanel: showRightPanel,
                onToggleRightPanel: { showRightPanel.toggle() }
            )
                .frame(minWidth: 400)
            if showRightPanel {
                RightPanelView(selectedItems: fileListVM.selectedItems)
            }
        }
        .onChange(of: sidebarSelection) { _, newURL in
            if let url = newURL {
                fileListVM.navigate(to: url)
            }
        }
        .task {
            await fileListVM.reload()
        }
    }
}
