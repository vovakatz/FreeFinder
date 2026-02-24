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
        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsInternalKey]
        guard let urls = fm.mountedVolumeURLs(
            includingResourceValuesForKeys: keys,
            options: [.skipHiddenVolumes]
        ) else { return }

        volumes = urls.map { url in
            let name = (try? url.resourceValues(forKeys: [.volumeNameKey]))?.volumeName
                ?? url.lastPathComponent
            return SidebarItem(
                id: url,
                name: name,
                icon: "externaldrive",
                category: .volumes
            )
        }
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
