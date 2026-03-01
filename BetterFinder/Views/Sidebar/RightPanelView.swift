import SwiftUI

struct RightPanelView: View {
    @Binding var selectedItems: Set<URL>
    let currentDirectory: URL
    @Binding var topWidget: WidgetType
    @Binding var bottomWidget: WidgetType
    @Binding var splitFraction: Double

    @State private var dragStartFraction: Double?

    var body: some View {
        GeometryReader { geo in
            let topHeight = max(50, geo.size.height * CGFloat(splitFraction))
            let bottomHeight = max(50, geo.size.height - topHeight - 5)
            VStack(spacing: 0) {
                WidgetSlotView(widgetType: $topWidget, selectedURLs: $selectedItems, currentDirectory: currentDirectory)
                    .frame(height: topHeight)
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 5)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .global)
                            .onChanged { value in
                                if dragStartFraction == nil {
                                    dragStartFraction = splitFraction
                                }
                                let delta = value.translation.height / geo.size.height
                                let newFraction = (dragStartFraction ?? splitFraction) + Double(delta)
                                splitFraction = max(50 / Double(geo.size.height), min(newFraction, 1.0 - 55 / Double(geo.size.height)))
                            }
                            .onEnded { _ in
                                dragStartFraction = nil
                            }
                    )
                    .onHover { hovering in
                        if hovering {
                            NSCursor.resizeUpDown.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                WidgetSlotView(widgetType: $bottomWidget, selectedURLs: $selectedItems, currentDirectory: currentDirectory)
                    .frame(height: bottomHeight)
            }
        }
        .background(.white)
    }
}
