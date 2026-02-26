import Foundation
import AppKit

@Observable
final class VolumeService {
    private(set) var volumes: [SidebarItem] = []
    private var observers: [NSObjectProtocol] = []

    init() {
        refreshVolumes()
        observeMountEvents()
    }

    deinit {
        for observer in observers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    func refreshVolumes() {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsInternalKey, .volumeIsLocalKey]
        guard let urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return }

        volumes = urls.map { url in
            let values = try? url.resourceValues(forKeys: [.volumeNameKey, .volumeIsLocalKey])
            let name = values?.volumeName ?? url.lastPathComponent
            let isLocal = values?.volumeIsLocal ?? true
            let icon = isLocal ? "externaldrive" : "externaldrive.connected.to.line.below"
            let category: SidebarCategory = isLocal ? .volumes : .network
            return SidebarItem(
                id: url,
                name: name,
                icon: icon,
                category: category
            )
        }
    }

    func isNetworkVolume(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.volumeIsLocalKey])
        return values?.volumeIsLocal == false
    }

    var localVolumes: [SidebarItem] {
        volumes.filter { $0.category == .volumes }
    }

    var networkVolumes: [SidebarItem] {
        volumes.filter { $0.category == .network }
    }

    private func observeMountEvents() {
        let center = NSWorkspace.shared.notificationCenter
        let names: [NSNotification.Name] = [
            NSWorkspace.didMountNotification,
            NSWorkspace.didUnmountNotification,
        ]
        for name in names {
            let observer = center.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.refreshVolumes()
            }
            observers.append(observer)
        }
    }
}
