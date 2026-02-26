import SwiftUI

struct WidgetHeaderView<ExtraContent: View>: View {
    @Binding var widgetType: WidgetType
    var extraButtons: ExtraContent

    init(widgetType: Binding<WidgetType>, @ViewBuilder extraButtons: () -> ExtraContent) {
        self._widgetType = widgetType
        self.extraButtons = extraButtons()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Menu {
                    ForEach(WidgetType.allCases) { type in
                        Button(type.rawValue) { widgetType = type }
                    }
                } label: {
                    Text(widgetType.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                Spacer()
                extraButtons
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.black.opacity(0.08))
            Divider()
        }
    }
}

extension WidgetHeaderView where ExtraContent == EmptyView {
    init(widgetType: Binding<WidgetType>) {
        self._widgetType = widgetType
        self.extraButtons = EmptyView()
    }
}
