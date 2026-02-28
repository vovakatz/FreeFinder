import SwiftUI

struct TerminalWidgetView: View {
    let currentDirectory: URL
    @Binding var widgetType: WidgetType
    @State private var session = TerminalSession()
    @State private var theme: TerminalTheme = .default

    var body: some View {
        VStack(spacing: 0) {
            WidgetHeaderView(widgetType: $widgetType) {
                Menu {
                    ForEach(TerminalTheme.allCases) { t in
                        Button {
                            theme = t
                        } label: {
                            if t == theme {
                                Label(t.rawValue, systemImage: "checkmark")
                            } else {
                                Text(t.rawValue)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } extraButtons: {
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

            TerminalEmulatorView(session: session, initialDirectory: currentDirectory, theme: theme)
        }
        .onChange(of: currentDirectory) { _, newVal in
            session.changeDirectory(to: newVal)
        }
        .onDisappear {
            session.stop()
        }
    }
}
