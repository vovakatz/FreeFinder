import SwiftUI

struct WidgetSlotView: View {
    @Binding var widgetType: WidgetType
    @Binding var selectedURLs: Set<URL>
    let currentDirectory: URL

    var body: some View {
        switch widgetType {
        case .info:
            InfoWidgetView(selectedURLs: selectedURLs, widgetType: $widgetType)
        case .preview:
            PreviewWidgetView(selectedURLs: selectedURLs, widgetType: $widgetType)
        case .terminal:
            TerminalWidgetView(currentDirectory: currentDirectory, widgetType: $widgetType)
        case .images:
            ImagesWidgetView(currentDirectory: currentDirectory, selectedURLs: $selectedURLs, widgetType: $widgetType)
        case .git:
            GitWidgetView(currentDirectory: currentDirectory, widgetType: $widgetType)
        }
    }
}
