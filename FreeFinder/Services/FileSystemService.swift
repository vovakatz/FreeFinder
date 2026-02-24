import Foundation
import AppKit
import UniformTypeIdentifiers

struct FileSystemService {
    static let resourceKeys: Set<URLResourceKey> = [
        .nameKey,
        .isDirectoryKey,
        .isPackageKey,
        .isHiddenKey,
        .fileSizeKey,
        .contentModificationDateKey,
        .localizedTypeDescriptionKey,
        .effectiveIconKey,
    ]

    nonisolated func loadContents(
        of url: URL,
        showHiddenFiles: Bool,
        sortedBy criteria: SortCriteria
    ) async throws -> [FileItem] {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: Array(Self.resourceKeys),
            options: showHiddenFiles ? [] : [.skipsHiddenFiles]
        )

        let items: [FileItem] = contents.compactMap { url in
            guard let values = try? url.resourceValues(forKeys: Self.resourceKeys) else {
                return nil
            }
            let isDir = values.isDirectory ?? false
            let isPackage = values.isPackage ?? false
            return FileItem(
                id: url,
                name: values.name ?? url.lastPathComponent,
                isDirectory: isDir && !isPackage,
                isPackage: isPackage,
                isHidden: values.isHidden ?? false,
                fileSize: Int64(values.fileSize ?? 0),
                dateModified: values.contentModificationDate,
                kind: values.localizedTypeDescription ?? "Unknown",
                icon: values.effectiveIcon as? NSImage ?? NSWorkspace.shared.icon(for: .data)
            )
        }

        return sortItems(items, by: criteria)
    }

    private nonisolated func sortItems(_ items: [FileItem], by criteria: SortCriteria) -> [FileItem] {
        let sorted = items.sorted { a, b in
            if a.isDirectory != b.isDirectory {
                return a.isDirectory
            }

            let result: Bool
            switch criteria.field {
            case .name:
                result = a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .dateModified:
                let dateA = a.dateModified ?? .distantPast
                let dateB = b.dateModified ?? .distantPast
                result = dateA < dateB
            case .size:
                result = a.fileSize < b.fileSize
            case .kind:
                result = a.kind.localizedStandardCompare(b.kind) == .orderedAscending
            }

            return criteria.ascending ? result : !result
        }
        return sorted
    }
}
