import SwiftUI

struct ContentView: View {
    @State private var fileListVM = FileListViewModel()
    @State private var sidebarVM = SidebarViewModel()
    @State private var sidebarSelection: URL?

    var body: some View {
        HSplitView {
            SidebarView(viewModel: sidebarVM, selection: $sidebarSelection)
                .frame(minWidth: 150, idealWidth: 200, maxWidth: 300)
            MainContentView(viewModel: fileListVM)
                .frame(minWidth: 400)
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
