import SwiftUI

struct BottomPanelView: View {
    let currentDirectory: URL

    var body: some View {
        TerminalWidgetView(currentDirectory: currentDirectory)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
    }
}
