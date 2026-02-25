import SwiftUI

struct FileIconView: View {
    let item: FileItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(nsImage: item.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)

            Text(item.name)
                .font(.system(size: 11))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if !item.isDirectory {
                Text(item.fileSize.formattedFileSize)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 110)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        )
    }
}
