import SwiftUI

struct StatusBarView: View {
    let selectionCount: Int
    let volumeStatusText: String

    var body: some View {
        HStack {
            if selectionCount > 0 {
                Text("\(selectionCount) items selected")
            }
            Spacer()
            Text(volumeStatusText)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.08))
    }
}
