import SwiftUI

struct FocusedFileListVMKey: FocusedValueKey {
    typealias Value = FileListViewModel
}

extension FocusedValues {
    var activeFileListVM: FileListViewModel? {
        get { self[FocusedFileListVMKey.self] }
        set { self[FocusedFileListVMKey.self] = newValue }
    }
}

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
    @State private var clipboardService = ClipboardService()
    @State private var showDualPane: Bool = false
    @State private var secondFileListVM = FileListViewModel()
    @State private var activePaneIsSecond: Bool = false
    @State private var bottomPanelHeight: CGFloat?
    @State private var centerPanelHeight: CGFloat = 0

    private var effectiveBottomHeight: CGFloat {
        bottomPanelHeight ?? (centerPanelHeight * 0.3)
    }

    private var activeVM: FileListViewModel {
        showDualPane && activePaneIsSecond ? secondFileListVM : fileListVM
    }

    var body: some View {
        HSplitView {
            if showLeftSidebar {
                SidebarView(viewModel: sidebarVM, selection: $sidebarSelection)
                    .frame(minWidth: 100, idealWidth: 100, maxWidth: 300)
            }
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let _ = updateCenterPanelHeight(geo.size.height)
                    VStack(spacing: 0) {
                        HStack(spacing: 0) {
                            MainContentView(
                                viewModel: fileListVM,
                                isActive: !activePaneIsSecond || !showDualPane,
                                onActivate: { activePaneIsSecond = false }
                            )
                            if showDualPane {
                                Divider()
                                MainContentView(
                                    viewModel: secondFileListVM,
                                    isActive: activePaneIsSecond,
                                    onActivate: { activePaneIsSecond = true }
                                )
                            }
                        }

                        if showBottomPanel {
                            SplitDragHandle(height: Binding(
                                get: { effectiveBottomHeight },
                                set: { bottomPanelHeight = $0 }
                            ), totalHeight: geo.size.height)

                            BottomPanelView(
                                currentDirectory: activeVM.currentURL,
                                selectedItems: Binding(
                                    get: { activeVM.selectedItems },
                                    set: { activeVM.selectedItems = $0 }
                                ),
                                widgetType: $bottomPanelWidget
                            )
                            .frame(height: effectiveBottomHeight)
                        }
                    }
                }
                Divider()
                StatusBarView(
                    selectionCount: activeVM.selectedItems.count,
                    volumeStatusText: activeVM.volumeStatusText
                )
            }
            .frame(minWidth: 400)
            if showRightPanel {
                RightPanelView(
                    selectedItems: Binding(
                        get: { activeVM.selectedItems },
                        set: { activeVM.selectedItems = $0 }
                    ),
                    currentDirectory: activeVM.currentURL,
                    topWidget: $rightTopWidget,
                    bottomWidget: $rightBottomWidget
                )
            }
        }
        .toolbarBackground(Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0), for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button {
                    showDualPane.toggle()
                } label: {
                    Image(systemName: "rectangle.split.2x1")
                        .foregroundStyle(showDualPane ? Color.accentColor : Color.secondary)
                }
                .help("Dual Pane")
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
                
                Spacer()

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
                activeVM.searchFilter = newValue
            }
        }
        .onChange(of: fileListVM.currentURL) { _, _ in
            if !activePaneIsSecond {
                searchText = ""
                fileListVM.searchFilter = ""
            }
        }
        .onChange(of: secondFileListVM.currentURL) { _, _ in
            if activePaneIsSecond && showDualPane {
                searchText = ""
                secondFileListVM.searchFilter = ""
            }
        }
        .onChange(of: showDualPane) { _, isShowing in
            if isShowing {
                Task { await secondFileListVM.reload() }
            } else {
                activePaneIsSecond = false
            }
        }
        .onChange(of: sidebarSelection) { _, newURL in
            if let url = newURL {
                activeVM.navigate(to: url)
            }
        }
        .environment(clipboardService)
        .focusedSceneValue(\.activeFileListVM, activeVM)
        .task {
            fileListVM.clipboardService = clipboardService
            secondFileListVM.clipboardService = clipboardService
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

    private func updateCenterPanelHeight(_ h: CGFloat) {
        if centerPanelHeight != h {
            DispatchQueue.main.async { centerPanelHeight = h }
        }
    }
}

