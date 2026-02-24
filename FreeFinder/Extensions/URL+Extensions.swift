import Foundation

extension URL {
    var displayName: String {
        FileManager.default.displayName(atPath: path(percentEncoded: false))
    }

    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    var isPackage: Bool {
        (try? resourceValues(forKeys: [.isPackageKey]))?.isPackage == true
    }
}
