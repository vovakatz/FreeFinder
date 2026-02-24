import Foundation

@Observable
final class SidebarViewModel {
    let volumeService = VolumeService()

    var favorites: [SidebarItem]

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        favorites = [
            SidebarItem(id: home, name: "Home", icon: "house", category: .favorites),
            SidebarItem(id: home.appending(path: "Desktop"), name: "Desktop", icon: "menubar.dock.rectangle", category: .favorites),
            SidebarItem(id: home.appending(path: "Documents"), name: "Documents", icon: "doc", category: .favorites),
            SidebarItem(id: home.appending(path: "Downloads"), name: "Downloads", icon: "arrow.down.circle", category: .favorites),
            SidebarItem(id: URL(filePath: "/Applications"), name: "Applications", icon: "app.dashed", category: .favorites),
        ]
    }

    func removeFavorite(_ item: SidebarItem) {
        favorites.removeAll { $0.id == item.id }
    }

    func insertFavorite(url: URL, at index: Int) {
        guard url.isDirectory, !favorites.contains(where: { $0.id == url }) else { return }
        let name = url.displayName
        let item = SidebarItem(id: url, name: name, icon: "folder", category: .favorites)
        let clampedIndex = min(index, favorites.count)
        favorites.insert(item, at: clampedIndex)
    }

    var volumes: [SidebarItem] {
        volumeService.volumes
    }
}
