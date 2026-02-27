import SwiftUI

struct ContentView: View {
    @State private var fileListVM = FileListViewModel()
    @State private var sidebarVM = SidebarViewModel()
    @State private var sidebarSelection: URL?
    @State private var showLeftSidebar: Bool = true
    @State private var showRightPanel: Bool = true
    @State private var showBottomPanel: Bool = false
    @State private var searchText: String = ""
    @State private var searchDebounceTask: Task<Void, Never>?
    @State private var rightTopWidget: WidgetType = .info
    @State private var rightBottomWidget: WidgetType = .preview
    @State private var bottomPanelWidget: WidgetType = .terminal

    var body: some View {
        HSplitView {
            if showLeftSidebar {
                SidebarView(viewModel: sidebarVM, selection: $sidebarSelection)
                    .frame(minWidth: 100, idealWidth: 100, maxWidth: 300)
            }
            MainContentView(
                viewModel: fileListVM,
                showBottomPanel: showBottomPanel,
                bottomPanelWidget: $bottomPanelWidget,
                selectedItems: $fileListVM.selectedItems
            )
                .frame(minWidth: 400)
            if showRightPanel {
                RightPanelView(selectedItems: $fileListVM.selectedItems, currentDirectory: fileListVM.currentURL, topWidget: $rightTopWidget, bottomWidget: $rightBottomWidget)
            }
        }
        .toolbarBackground(Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0), for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button { fileListVM.viewMode = .list } label: {
                    Image(systemName: "list.dash")
                        .foregroundStyle(fileListVM.viewMode == .list ? Color.accentColor : Color.secondary)
                }
                .help("List view")

                Button { fileListVM.viewMode = .icons } label: {
                    Image(systemName: "square.grid.3x3")
                        .foregroundStyle(fileListVM.viewMode == .icons ? Color.accentColor : Color.secondary)
                }
                .help("Icon view")

                Button { fileListVM.viewMode = .thumbnails } label: {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(fileListVM.viewMode == .thumbnails ? Color.accentColor : Color.secondary)
                }
                .help("Thumbnail view")

                Button {
                    fileListVM.showHiddenFiles.toggle()
                    Task { await fileListVM.reload() }
                } label: {
                    Image(systemName: fileListVM.showHiddenFiles ? "eye" : "eye.slash")
                }
                .help(fileListVM.showHiddenFiles ? "Hide hidden files" : "Show hidden files")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                Button { showLeftSidebar.toggle() } label: {
                    Image(systemName: "sidebar.left")
                }
                .help(showLeftSidebar ? "Hide left sidebar" : "Show left sidebar")

                Button { showBottomPanel.toggle() } label: {
                    Image(systemName: "rectangle.bottomthird.inset.filled")
                }
                .help(showBottomPanel ? "Hide bottom panel" : "Show bottom panel")

                Button { showRightPanel.toggle() } label: {
                    Image(systemName: "sidebar.right")
                }
                .help(showRightPanel ? "Hide right panel" : "Show right panel")

                SearchBarView(text: $searchText)
                    .frame(width: 280)
                    .padding(.horizontal, 8)
            }
        }
        .onChange(of: searchText) { _, newValue in
            searchDebounceTask?.cancel()
            searchDebounceTask = Task {
                try? await Task.sleep(for: .milliseconds(250))
                guard !Task.isCancelled else { return }
                fileListVM.searchFilter = newValue
            }
        }
        .onChange(of: fileListVM.currentURL) { _, _ in
            searchText = ""
            fileListVM.searchFilter = ""
        }
        .onChange(of: sidebarSelection) { _, newURL in
            if let url = newURL {
                fileListVM.navigate(to: url)
            }
        }
        .task {
            await fileListVM.reload()
        }
        .sheet(isPresented: $fileListVM.showConnectToServer) {
            ConnectToServerSheet { urlString in
                fileListVM.connectToServer(urlString: urlString)
            }
        }
        .sheet(isPresented: $fileListVM.showAuthSheet) {
            let serverName = fileListVM.pendingAuthHostname
                ?? fileListVM.pendingMountURL?.host()
                ?? "Server"
            AuthenticationSheet(serverName: serverName) { credentials in
                fileListVM.authenticateAndMount(credentials: credentials)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .connectToServer)) { _ in
            fileListVM.showConnectToServer = true
        }
    }
}

