import Foundation
import AppKit

@Observable
final class FileListViewModel {
    private let fileSystemService = FileSystemService()

    private(set) var navigationState: NavigationState
    private(set) var items: [FileItem] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var sortCriteria = SortCriteria()
    var showHiddenFiles = false

    var currentURL: URL { navigationState.currentURL }
    var canGoBack: Bool { navigationState.canGoBack }
    var canGoForward: Bool { navigationState.canGoForward }
    var canGoToParent: Bool { navigationState.canGoToParent }

    var pathComponents: [(name: String, url: URL)] {
        navigationState.pathComponents
    }

    var directoryTitle: String {
        currentURL.displayName
    }

    init(startURL: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.navigationState = NavigationState(url: startURL)
    }

    func navigate(to url: URL) {
        navigationState.navigate(to: url)
        Task { await reload() }
    }

    func openItem(_ item: FileItem) {
        if item.isDirectory {
            navigate(to: item.url)
        } else {
            NSWorkspace.shared.open(item.url)
        }
    }

    func goBack() {
        if let _ = navigationState.goBack() {
            Task { await reload() }
        }
    }

    func goForward() {
        if let _ = navigationState.goForward() {
            Task { await reload() }
        }
    }

    func navigateToParent() {
        if let parent = navigationState.parentURL {
            navigate(to: parent)
        }
    }

    func toggleSort(by field: SortField) {
        if sortCriteria.field == field {
            sortCriteria.ascending.toggle()
        } else {
            sortCriteria.field = field
            sortCriteria.ascending = true
        }
        Task { await reload() }
    }

    func reload() async {
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await fileSystemService.loadContents(
                of: currentURL,
                showHiddenFiles: showHiddenFiles,
                sortedBy: sortCriteria
            )
            items = loaded
        } catch {
            errorMessage = error.localizedDescription
            items = []
        }
        isLoading = false
    }
}
