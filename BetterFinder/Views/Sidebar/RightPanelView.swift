import SwiftUI

struct RightPanelView: View {
    @Binding var selectedItems: Set<URL>
    let currentDirectory: URL
    @Binding var topWidget: WidgetType
    @Binding var bottomWidget: WidgetType

    var body: some View {
        VSplitView {
            WidgetSlotView(widgetType: $topWidget, selectedURLs: $selectedItems, currentDirectory: currentDirectory)
                .frame(minHeight: 50, idealHeight: 200, maxHeight: .infinity)
            WidgetSlotView(widgetType: $bottomWidget, selectedURLs: $selectedItems, currentDirectory: currentDirectory)
                .frame(minHeight: 50, idealHeight: 200, maxHeight: .infinity)
        }
        .background(.white)
        .frame(minWidth: 150, idealWidth: 220)
    }
}
