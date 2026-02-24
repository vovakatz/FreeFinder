import Foundation

struct NavigationState {
    private(set) var backStack: [URL] = []
    private(set) var forwardStack: [URL] = []
    private(set) var currentURL: URL

    init(url: URL = FileManager.default.homeDirectoryForCurrentUser) {
        self.currentURL = url
    }

    var canGoBack: Bool { !backStack.isEmpty }
    var canGoForward: Bool { !forwardStack.isEmpty }

    var canGoToParent: Bool {
        currentURL.pathComponents.count > 1
    }

    var parentURL: URL? {
        canGoToParent ? currentURL.deletingLastPathComponent() : nil
    }

    var pathComponents: [(name: String, url: URL)] {
        var components: [(name: String, url: URL)] = []
        var url = currentURL.standardizedFileURL
        while url.pathComponents.count > 1 {
            components.insert((name: url.displayName, url: url), at: 0)
            url = url.deletingLastPathComponent()
        }
        let rootURL = URL(filePath: "/")
        let volumeName = rootURL.displayName
        components.insert((name: volumeName, url: rootURL), at: 0)
        return components
    }

    mutating func navigate(to url: URL) {
        guard url != currentURL else { return }
        backStack.append(currentURL)
        forwardStack.removeAll()
        currentURL = url
    }

    mutating func goBack() -> URL? {
        guard let previous = backStack.popLast() else { return nil }
        forwardStack.append(currentURL)
        currentURL = previous
        return previous
    }

    mutating func goForward() -> URL? {
        guard let next = forwardStack.popLast() else { return nil }
        backStack.append(currentURL)
        currentURL = next
        return next
    }
}
