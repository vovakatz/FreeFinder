import Foundation
import AppKit

enum ViewMode {
    case list
    case icons
}

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
    var needsFullDiskAccess = false
    var sortCriteria = SortCriteria()
    var showHiddenFiles = false
    var expandedFolders: Set<URL> = []
    var childItems: [URL: [FileItem]] = [:]
    var selectedItems: Set<URL> = []
    var viewMode: ViewMode = .list

    // Clipboard & delete state
    var clipboard: (urls: Set<URL>, isCut: Bool)?
    var showDeleteConfirmation = false
    var itemsToDelete: Set<URL> = []
    var showOverwriteConfirmation = false
    var conflictingNames: [String] = []

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

    private static let trashURL = try? FileManager.default.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)

    var isTrash: Bool {
        guard let trashURL = Self.trashURL else { return false }
        return currentURL.standardizedFileURL == trashURL.standardizedFileURL
    }

    func reload() async {
        expandedFolders.removeAll()
        childItems.removeAll()
        isLoading = true
        errorMessage = nil
        needsFullDiskAccess = false
        do {
            let loaded = try await fileSystemService.loadContents(
                of: currentURL,
                showHiddenFiles: showHiddenFiles,
                sortedBy: sortCriteria
            )
            items = loaded
        } catch {
            if isTrash, (error as NSError).domain == NSCocoaErrorDomain,
               (error as NSError).code == NSFileReadNoPermissionError {
                needsFullDiskAccess = true
                errorMessage = "FreeFinder needs Full Disk Access to view the Trash."
            } else {
                errorMessage = error.localizedDescription
            }
            items = []
        }
        isLoading = false
    }

    func openFullDiskAccessSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
    }

    // MARK: - Rename

    func renameItem(at url: URL, to newName: String) {
        let newURL = url.deletingLastPathComponent().appendingPathComponent(newName)
        guard newURL != url else { return }
        do {
            try FileManager.default.moveItem(at: url, to: newURL)
        } catch {
            errorMessage = error.localizedDescription
        }
        Task { await reload() }
    }

    // MARK: - Create operations

    func createFolder(name: String) {
        let folderURL = currentURL.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false)
        } catch {
            errorMessage = error.localizedDescription
        }
        Task { await reload() }
    }

    func createFile(name: String) {
        let fileURL = currentURL.appendingPathComponent(name)
        if !FileManager.default.createFile(atPath: fileURL.path, contents: nil) {
            errorMessage = "Could not create file \"\(name)\"."
        }
        Task { await reload() }
    }

    // MARK: - Clipboard operations

    func copyItems(_ urls: Set<URL>) {
        clipboard = (urls: urls, isCut: false)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls.map { $0 as NSURL })
    }

    func cutItems(_ urls: Set<URL>) {
        clipboard = (urls: urls, isCut: true)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls.map { $0 as NSURL })
    }

    func pasteItems() {
        guard let clipboard else { return }
        let fm = FileManager.default

        // Check for conflicts
        let conflicts = clipboard.urls.filter { sourceURL in
            let destURL = currentURL.appendingPathComponent(sourceURL.lastPathComponent)
            return fm.fileExists(atPath: destURL.path)
        }

        if !conflicts.isEmpty {
            conflictingNames = conflicts.map { $0.lastPathComponent }.sorted()
            showOverwriteConfirmation = true
            return
        }

        performPaste()
    }

    func confirmOverwritePaste() {
        performPaste(overwrite: true)
    }

    private func performPaste(overwrite: Bool = false) {
        guard let clipboard else { return }
        let fm = FileManager.default
        for sourceURL in clipboard.urls {
            let destURL = currentURL.appendingPathComponent(sourceURL.lastPathComponent)
            do {
                if overwrite && fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                if clipboard.isCut {
                    try fm.moveItem(at: sourceURL, to: destURL)
                } else {
                    try fm.copyItem(at: sourceURL, to: destURL)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        if clipboard.isCut {
            self.clipboard = nil
        }
        Task { await reload() }
    }

    func moveToTrash(_ urls: Set<URL>) {
        let fm = FileManager.default
        for url in urls {
            do {
                try fm.trashItem(at: url, resultingItemURL: nil)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        selectedItems.subtract(urls)
        Task { await reload() }
    }

    func requestDelete(_ urls: Set<URL>) {
        itemsToDelete = urls
        showDeleteConfirmation = true
    }

    func confirmDelete() {
        let fm = FileManager.default
        for url in itemsToDelete {
            do {
                try fm.removeItem(at: url)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        selectedItems.subtract(itemsToDelete)
        itemsToDelete.removeAll()
        Task { await reload() }
    }
}
