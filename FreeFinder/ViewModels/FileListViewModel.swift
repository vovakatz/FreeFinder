import Foundation
import AppKit

struct DisplayItem: Identifiable {
    let fileItem: FileItem
    let depth: Int
    var id: URL { fileItem.id }
}

@Observable
final class FileListViewModel {
    private let fileSystemService = FileSystemService()

    private(set) var navigationState: NavigationState
    private(set) var items: [FileItem] = []
    private(set) var isLoading = false
    var errorMessage: String?
    var sortCriteria = SortCriteria()
    var showHiddenFiles = false
    var expandedFolders: Set<URL> = []
    var childItems: [URL: [FileItem]] = [:]
    var selectedItems: Set<URL> = []

    var volumeStatusText: String {
        do {
            let values = try currentURL.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            if let available = values.volumeAvailableCapacityForImportantUsage,
               let total = values.volumeTotalCapacity {
                let availStr = available.formattedFileSize
                let totalStr = Int64(total).formattedFileSize
                return "\(availStr) of \(totalStr) available"
            }
        } catch {}
        return ""
    }

    var displayItems: [DisplayItem] {
        var result: [DisplayItem] = []
        func addItems(_ items: [FileItem], depth: Int) {
            for item in items {
                result.append(DisplayItem(fileItem: item, depth: depth))
                if item.isDirectory, expandedFolders.contains(item.url),
                   let children = childItems[item.url] {
                    addItems(children, depth: depth + 1)
                }
            }
        }
        addItems(items, depth: 0)
        return result
    }

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
        expandedFolders.removeAll()
        childItems.removeAll()
        navigationState.navigate(to: url)
        Task { await reload() }
    }

    func toggleExpanded(_ item: FileItem) {
        if expandedFolders.contains(item.url) {
            expandedFolders.remove(item.url)
        } else {
            expandedFolders.insert(item.url)
            if childItems[item.url] == nil {
                Task { await loadChildren(for: item.url) }
            }
        }
    }

    private func loadChildren(for url: URL) async {
        do {
            let children = try await fileSystemService.loadContents(
                of: url, showHiddenFiles: showHiddenFiles, sortedBy: sortCriteria
            )
            childItems[url] = children
        } catch {
            // Silently fail — folder just won't show children
        }
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
        expandedFolders.removeAll()
        childItems.removeAll()
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
