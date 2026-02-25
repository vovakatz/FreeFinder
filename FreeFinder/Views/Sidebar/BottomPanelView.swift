import SwiftUI

struct BottomPanelView: View {
    let currentDirectory: URL

    var body: some View {
        TerminalWidgetView(currentDirectory: currentDirectory)
            .frame(maxWidth: .infinity, minHeight: 50, idealHeight: 150, maxHeight: .infinity)
            .background(.white)
    }
}
