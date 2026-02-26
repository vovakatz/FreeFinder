import SwiftUI

@main
struct FreeFinderApp: App {
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
        }
    }
}

extension Notification.Name {
    static let connectToServer = Notification.Name("connectToServer")
}
