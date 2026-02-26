import SwiftUI

struct BottomPanelView: View {
    let currentDirectory: URL
    @Binding var selectedItems: Set<URL>
    @Binding var widgetType: WidgetType

    var body: some View {
        WidgetSlotView(widgetType: $widgetType, selectedURLs: $selectedItems, currentDirectory: currentDirectory)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.white)
    }
}
