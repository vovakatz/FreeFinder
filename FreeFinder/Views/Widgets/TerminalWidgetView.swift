import SwiftUI

struct TerminalWidgetView: View {
    let currentDirectory: URL
    @Binding var widgetType: WidgetType
    @State private var session = TerminalSession()

    var body: some View {
        VStack(spacing: 0) {
            WidgetHeaderView(widgetType: $widgetType) {
                Button {
                    session.clearTerminal()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .fixedSize(horizontal: false, vertical: true)

            TerminalEmulatorView(session: session, initialDirectory: currentDirectory)
        }
        .onChange(of: currentDirectory) { _, newVal in
            session.changeDirectory(to: newVal)
        }
        .onDisappear {
            session.stop()
        }
    }
}
