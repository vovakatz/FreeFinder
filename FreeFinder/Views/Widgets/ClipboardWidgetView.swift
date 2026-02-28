import SwiftUI

struct ClipboardWidgetView: View {
    let currentDirectory: URL
    @Binding var widgetType: WidgetType
    @Environment(ClipboardService.self) private var clipboardService

    var body: some View {
        VStack(spacing: 0) {
            WidgetHeaderView(widgetType: $widgetType) {
                Button {
                    clipboardService.clearHistory()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear history")
                .disabled(clipboardService.history.isEmpty)
            }
            .fixedSize(horizontal: false, vertical: true)

            if clipboardService.history.isEmpty {
                emptyView
            } else {
                contentView
            }
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack {
            Spacer()
            Text("No clipboard history")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text("Copy or cut files to see them here")
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Content

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if let current = clipboardService.current {
                    sectionHeader("Current")
                    entryRow(current, isCurrent: true)
                    Divider()
                }

                let pastEntries = clipboardService.history.filter { $0.id != clipboardService.current?.id }
                if !pastEntries.isEmpty {
                    sectionHeader("History")
                    ForEach(pastEntries) { entry in
                        entryRow(entry, isCurrent: false)
                    }
                }
            }
        }
    }

    // MARK: - Entry Row

    private func entryRow(_ entry: ClipboardEntry, isCurrent: Bool) -> some View {
        HStack(spacing: 6) {
            // CUT/COPY badge
            Text(entry.isCut ? "CUT" : "COPY")
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(entry.isCut ? Color.orange : Color.blue)
                )

            // File info
            VStack(alignment: .leading, spacing: 1) {
                let names = entry.urls.map(\.lastPathComponent).sorted()
                let count = names.count
                Text(count == 1 ? "1 item" : "\(count) items")
                    .font(.system(size: 10, weight: .medium))
                ForEach(names.prefix(3), id: \.self) { name in
                    Text(name)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                if count > 3 {
                    Text("+ \(count - 3) more")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Timestamp
            Text(entry.timestamp.relativeString)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)

            // Actions
            if !isCurrent {
                Button {
                    clipboardService.restore(entry)
                } label: {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("Restore to clipboard")
            }

            Button {
                clipboardService.removeFromHistory(entry)
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove from history")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isCurrent ? Color.accentColor.opacity(0.08) : Color.clear)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
}

private extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
