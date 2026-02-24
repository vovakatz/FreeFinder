import SwiftUI

struct FileRowView: View {
    let item: FileItem
    let dateWidth: CGFloat
    let sizeWidth: CGFloat
    let kindWidth: CGFloat

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 18, height: 18)

                Text(item.name)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer().frame(width: 8)

            Text(item.dateModified?.fileDateString ?? "--")
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
                .frame(width: dateWidth, alignment: .leading)

            Spacer().frame(width: 8)

            Text(item.isDirectory ? "--" : item.fileSize.formattedFileSize)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
                .frame(width: sizeWidth, alignment: .trailing)

            Spacer().frame(width: 8)

            Text(item.kind)
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundStyle(.secondary)
                .frame(width: kindWidth, alignment: .leading)
        }
        .font(.system(size: 13))
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
}
