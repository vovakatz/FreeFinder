import SwiftUI
import SwiftTerm

@Observable
class TerminalSession {
    var terminalView: LocalProcessTerminalView?

    func start(in directory: URL) {
        terminalView?.startProcess(
            executable: "/bin/zsh",
            execName: "-zsh",
            currentDirectory: directory.path
        )
    }

    func changeDirectory(to url: URL) {
        let escapedPath = url.path.replacingOccurrences(of: "'", with: "'\\''")
        terminalView?.send(txt: " cd '\(escapedPath)'\n")
    }

    func clearTerminal() {
        terminalView?.send(txt: "\u{03}")
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            terminalView?.send(txt: "clear\n")
        }
    }

    func stop() {
        terminalView?.terminate()
        terminalView = nil
    }
}
