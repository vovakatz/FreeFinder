import SwiftUI

struct TerminalWidgetView: View {
    let currentDirectory: URL
    @State private var session = TerminalSession()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                WidgetHeaderView(title: "Terminal")
                HStack {
                    Spacer()
                    Button {
                        session.clearTerminal()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                    .padding(.bottom, 1)
                }
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
