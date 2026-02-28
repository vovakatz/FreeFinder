import Foundation

@Observable
final class SidebarViewModel {
    let volumeService = VolumeService()

    var favorites: [SidebarItem]

    init() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let trashURL = try? FileManager.default.url(for: .trashDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        var items = [
            SidebarItem(id: home, name: "Home", icon: "house", category: .favorites, isDefault: true),
            SidebarItem(id: home.appending(path: "Desktop"), name: "Desktop", icon: "menubar.dock.rectangle", category: .favorites, isDefault: true),
            SidebarItem(id: home.appending(path: "Documents"), name: "Documents", icon: "doc", category: .favorites, isDefault: true),
            SidebarItem(id: home.appending(path: "Downloads"), name: "Downloads", icon: "arrow.down.circle", category: .favorites, isDefault: true),
            SidebarItem(id: URL(filePath: "/Applications"), name: "Applications", icon: "app.dashed", category: .favorites, isDefault: true),
        ]
        if let trashURL {
            items.append(SidebarItem(id: trashURL, name: "Trash", icon: "trash", category: .favorites, isDefault: true))
        }
        favorites = items
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

    var networkItem: SidebarItem {
        SidebarItem(
            id: URL(string: "network://")!,
            name: "Network",
            icon: "network",
            category: .network
        )
    }

    var localVolumes: [SidebarItem] {
        volumeService.localVolumes
    }

    var networkVolumes: [SidebarItem] {
        volumeService.networkVolumes
    }

    var volumes: [SidebarItem] {
        volumeService.volumes
    }
}
