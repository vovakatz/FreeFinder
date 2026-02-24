import SwiftUI

struct RightPanelView: View {
    let selectedItems: Set<URL>

    var body: some View {
        VSplitView {
            InfoWidgetView(selectedURLs: selectedItems)
                .frame(minHeight: 50, idealHeight: 200, maxHeight: .infinity)
            PreviewWidgetView(selectedURLs: selectedItems)
                .frame(minHeight: 50, idealHeight: 200, maxHeight: .infinity)
        }
        .background(.white)
        .frame(minWidth: 150, idealWidth: 220)
    }
}
