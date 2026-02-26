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
            .background(.white, ignoresSafeAreaEdges: [])
            .overlay(alignment: .bottom) {
                Color(red: 0xE5/255.0, green: 0xE5/255.0, blue: 0xE5/255.0)
                    .frame(height: 1)
            }
        }
    }
}

extension WidgetHeaderView where ExtraContent == EmptyView {
    init(widgetType: Binding<WidgetType>) {
        self._widgetType = widgetType
        self.extraButtons = EmptyView()
    }
}
