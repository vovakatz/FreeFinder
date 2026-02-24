import SwiftUI
import UniformTypeIdentifiers

struct FileMetadata {
    var name: String = ""
    var kind: String = ""
    var uti: String = ""
    var sizeLogical: Int64 = 0
    var sizePhysical: Int64 = 0
    var created: Date?
    var modified: Date?
    var lastOpened: Date?
    var added: Date?
    var attributes: String = ""
    var owner: String = ""
    var group: String = ""
    var permissions: String = ""
    var path: String = ""
    var application: String = ""
    var volumeName: String = ""
    var volumeCapacity: Int64 = 0
    var volumeFree: Int64 = 0
    var volumeFormat: String = ""
    var mountPoint: String = ""
    var device: String = ""

    static func fetch(from url: URL) -> FileMetadata? {
        let resourceKeys: Set<URLResourceKey> = [
            .nameKey, .localizedTypeDescriptionKey, .contentTypeKey,
            .fileSizeKey, .fileAllocatedSizeKey,
            .creationDateKey, .contentModificationDateKey,
            .contentAccessDateKey, .addedToDirectoryDateKey,
            .isHiddenKey, .isReadableKey, .isWritableKey, .isExecutableKey,
            .volumeNameKey, .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeLocalizedFormatDescriptionKey,
        ]

        guard let values = try? url.resourceValues(forKeys: resourceKeys) else {
            return nil
        }

        var meta = FileMetadata()
        meta.name = values.name ?? url.lastPathComponent
        meta.kind = values.localizedTypeDescription ?? "Unknown"
        meta.uti = values.contentType?.identifier ?? ""
        meta.sizeLogical = Int64(values.fileSize ?? 0)
        meta.sizePhysical = Int64(values.fileAllocatedSize ?? 0)
        meta.created = values.creationDate
        meta.modified = values.contentModificationDate
        meta.lastOpened = values.contentAccessDate
        meta.added = values.addedToDirectoryDate
        meta.path = url.path

        // Attributes
        var attrs: [String] = []
        if values.isHidden == true { attrs.append("Hidden") }
        if values.isReadable == true { attrs.append("Readable") }
        if values.isWritable == true { attrs.append("Writable") }
        if values.isExecutable == true { attrs.append("Executable") }
        meta.attributes = attrs.joined(separator: ", ")

        // Owner, group, permissions from FileManager
        if let fileAttrs = try? FileManager.default.attributesOfItem(atPath: url.path) {
            meta.owner = fileAttrs[.ownerAccountName] as? String ?? ""
            meta.group = fileAttrs[.groupOwnerAccountName] as? String ?? ""
            if let posix = fileAttrs[.posixPermissions] as? Int {
                meta.permissions = formatPermissions(posix)
            }
        }

        // Default application
        if let appURL = NSWorkspace.shared.urlForApplication(toOpen: url) {
            meta.application = appURL.deletingPathExtension().lastPathComponent
        }

        // Volume info
        meta.volumeName = values.volumeName ?? ""
        meta.volumeCapacity = values.volumeTotalCapacity.map { Int64($0) } ?? 0
        meta.volumeFree = values.volumeAvailableCapacityForImportantUsage ?? 0
        meta.volumeFormat = values.volumeLocalizedFormatDescription ?? ""
        if let (mount, dev) = mountAndDevice(for: url.path) {
            meta.mountPoint = mount
            meta.device = dev
        }

        return meta
    }
}

private func formatPermissions(_ mode: Int) -> String {
    let chars: [(Int, Character)] = [
        (0o400, "r"), (0o200, "w"), (0o100, "x"),
        (0o040, "r"), (0o020, "w"), (0o010, "x"),
        (0o004, "r"), (0o002, "w"), (0o001, "x"),
    ]
    var str = ""
    for (mask, ch) in chars {
        str.append(mode & mask != 0 ? ch : "-")
    }
    let octal = String(format: "%o", mode & 0o777)
    return "\(str) (\(octal))"
}

private func mountAndDevice(for path: String) -> (mount: String, device: String)? {
    var buf = statfs()
    guard statfs(path, &buf) == 0 else { return nil }
    let device = withUnsafePointer(to: &buf.f_mntfromname) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
            String(cString: $0)
        }
    }
    let mount = withUnsafePointer(to: &buf.f_mntonname) { ptr in
        ptr.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
            String(cString: $0)
        }
    }
    return (mount, device)
}

struct InfoWidgetView: View {
    let selectedURLs: Set<URL>
    @State private var metadata: FileMetadata?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(title: "Info")

            Group {
                if selectedURLs.count == 0 {
                    Text("No Selection")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else if selectedURLs.count > 1 {
                    Text("\(selectedURLs.count) items selected")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else if let meta = metadata {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            infoRow("Name", meta.name)
                            infoRow("Kind", meta.kind)
                            if !meta.uti.isEmpty {
                                infoRow("UTI", meta.uti)
                            }
                            infoRow("Size", meta.sizeLogical.formattedFileSize)
                            HStack(alignment: .top, spacing: 4) {
                                Text("")
                                    .frame(width: 70, alignment: .trailing)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Data: \(meta.sizeLogical) bytes")
                                    Text("Physical: \(meta.sizePhysical) bytes")
                                }
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            }
                            Divider().padding(.vertical, 4)
                            if let d = meta.created {
                                infoRow("Created", d.fileDateString)
                            }
                            if let d = meta.modified {
                                infoRow("Modified", d.fileDateString)
                            }
                            if let d = meta.lastOpened {
                                infoRow("Opened", d.fileDateString)
                            }
                            if let d = meta.added {
                                infoRow("Added", d.fileDateString)
                            }
                            Divider().padding(.vertical, 4)
                            if !meta.attributes.isEmpty {
                                infoRow("Attrs", meta.attributes)
                            }
                            if !meta.owner.isEmpty {
                                infoRow("Owner", meta.owner)
                            }
                            if !meta.group.isEmpty {
                                infoRow("Group", meta.group)
                            }
                            if !meta.permissions.isEmpty {
                                infoRow("Perms", meta.permissions)
                            }
                            if !meta.application.isEmpty {
                                infoRow("Opens with", meta.application)
                            }
                            infoRow("Path", meta.path)
                            Divider().padding(.vertical, 4)
                            if !meta.volumeName.isEmpty {
                                infoRow("Volume", meta.volumeName)
                            }
                            if meta.volumeCapacity > 0 {
                                infoRow("Capacity", meta.volumeCapacity.formattedFileSize)
                            }
                            if meta.volumeFree > 0 {
                                infoRow("Free", meta.volumeFree.formattedFileSize)
                            }
                            if !meta.volumeFormat.isEmpty {
                                infoRow("Format", meta.volumeFormat)
                            }
                            if !meta.mountPoint.isEmpty {
                                infoRow("Mount", meta.mountPoint)
                            }
                            if !meta.device.isEmpty {
                                infoRow("Device", meta.device)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
        .onAppear { fetchMetadata() }
        .onChange(of: selectedURLs) { _, _ in fetchMetadata() }
    }

    private func fetchMetadata() {
        if selectedURLs.count == 1, let url = selectedURLs.first {
            metadata = FileMetadata.fetch(from: url)
        } else {
            metadata = nil
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label)
                .frame(width: 70, alignment: .trailing)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
        .font(.system(size: 11))
    }
}
