import SwiftUI
import AppKit

@main
struct FreeFinderApp: App {
    @FocusedValue(\.activeFileListVM) var activeVM

    var body: some Scene {
        WindowGroup("") {
            ContentView()
        }
        .defaultSize(width: 1000, height: 650)
        .commands {
            CommandGroup(after: .newItem) {
                Button("Connect to Server...") {
                    NotificationCenter.default.post(name: .connectToServer, object: nil)
                }
                .keyboardShortcut("k", modifiers: .command)
            }
            CommandGroup(after: .pasteboard) {
                Button("Move to Trash") {
                    guard let vm = activeVM, !vm.selectedItems.isEmpty else { return }
                    vm.moveToTrash(vm.selectedItems)
                }
                .keyboardShortcut(.delete, modifiers: .command)
            }
            CommandGroup(replacing: .textEditing) {
                Button("Select All") {
                    if let firstResponder = NSApp.keyWindow?.firstResponder,
                       firstResponder is NSTextView {
                        NSApp.sendAction(#selector(NSResponder.selectAll(_:)), to: nil, from: nil)
                    } else if let vm = activeVM {
                        vm.selectedItems = Set(vm.displayItems.map(\.id))
                    }
                }
                .keyboardShortcut("a", modifiers: .command)
            }
        }
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connectToServer")
}
