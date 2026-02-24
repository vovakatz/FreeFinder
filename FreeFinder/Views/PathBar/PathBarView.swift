import SwiftUI

struct PathBarView: View {
    let components: [(name: String, url: URL)]
    let onNavigate: (URL) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(Array(components.enumerated()), id: \.offset) { index, component in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    Button {
                        onNavigate(component.url)
                    } label: {
                        Text(component.name)
                            .font(.system(size: 11))
                            .foregroundStyle(index == components.count - 1 ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
        .frame(height: 24)
        .background(Color(nsColor: .controlBackgroundColor))
    }
}
