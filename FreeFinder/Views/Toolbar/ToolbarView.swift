import SwiftUI

struct ToolbarView: View {
    let pathComponents: [(name: String, url: URL)]
    let onNavigate: (URL) -> Void
    var canGoBack: Bool = false
    var canGoForward: Bool = false
    var onGoBack: () -> Void = {}
    var onGoForward: () -> Void = {}

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onGoBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.borderless)
            .disabled(!canGoBack)

            Button(action: onGoForward) {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.borderless)
            .disabled(!canGoForward)

            Spacer()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 2) {
                    ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                        if index > 0 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        BreadcrumbItem(
                            name: component.name,
                            isCurrent: index == pathComponents.count - 1
                        ) {
                            onNavigate(component.url)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

private struct BreadcrumbItem: View {
    let name: String
    let isCurrent: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(name)
                .font(.system(size: 11))
                .foregroundStyle(isCurrent ? .primary : .secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.black.opacity(0.08) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
