import SwiftUI
import SwiftTerm

struct TerminalEmulatorView: NSViewRepresentable {
    let session: TerminalSession
    let initialDirectory: URL
    var theme: TerminalTheme

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)
        tv.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.processDelegate = context.coordinator
        tv.autoresizingMask = [.width, .height]

        context.coordinator.appliedTheme = theme
        theme.apply(to: tv)

        session.terminalView = tv
        session.start(in: initialDirectory)

        return tv
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        if context.coordinator.appliedTheme != theme {
            context.coordinator.appliedTheme = theme
            theme.apply(to: nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var appliedTheme: TerminalTheme?

        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }
}
