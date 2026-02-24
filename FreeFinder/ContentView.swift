import SwiftUI

struct ContentView: View {
    @State private var fileListVM = FileListViewModel()
    @State private var sidebarVM = SidebarViewModel()
    @State private var sidebarSelection: URL?

    var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: sidebarVM, selection: $sidebarSelection)
        } detail: {
            MainContentView(viewModel: fileListVM)
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
