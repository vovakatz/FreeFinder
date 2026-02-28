import Foundation
import AppKit

struct ClipboardEntry: Identifiable {
    let id = UUID()
    let urls: Set<URL>
    let isCut: Bool
    let timestamp: Date
}

@Observable
final class ClipboardService {
    private(set) var current: ClipboardEntry?
    private(set) var history: [ClipboardEntry] = []

    private let maxHistory = 50

    func setCopy(_ urls: Set<URL>) {
        let entry = ClipboardEntry(urls: urls, isCut: false, timestamp: Date())
        current = entry
        pushHistory(entry)
        syncToPasteboard(urls)
    }

    func setCut(_ urls: Set<URL>) {
        let entry = ClipboardEntry(urls: urls, isCut: true, timestamp: Date())
        current = entry
        pushHistory(entry)
        syncToPasteboard(urls)
    }

    func restore(_ entry: ClipboardEntry) {
        current = entry
        syncToPasteboard(entry.urls)
    }

    func clearCurrent() {
        current = nil
    }

    func removeFromHistory(_ entry: ClipboardEntry) {
        history.removeAll { $0.id == entry.id }
        if current?.id == entry.id {
            current = nil
        }
    }

    func clearHistory() {
        history.removeAll()
        current = nil
    }

    private func pushHistory(_ entry: ClipboardEntry) {
        history.insert(entry, at: 0)
        if history.count > maxHistory {
            history = Array(history.prefix(maxHistory))
        }
    }

    private func syncToPasteboard(_ urls: Set<URL>) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls.map { $0 as NSURL })
    }
}
