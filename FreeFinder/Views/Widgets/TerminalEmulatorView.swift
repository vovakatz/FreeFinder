import SwiftUI
import SwiftTerm

struct TerminalEmulatorView: NSViewRepresentable {
    let session: TerminalSession
    let initialDirectory: URL

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let tv = LocalProcessTerminalView(frame: .zero)
        tv.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.configureNativeColors()
        tv.processDelegate = context.coordinator
        tv.autoresizingMask = [.width, .height]

        session.terminalView = tv
        session.start(in: initialDirectory)

        return tv
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {}
        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {}
        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {}
        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {}
    }
}
