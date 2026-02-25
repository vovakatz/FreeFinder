import SwiftUI
import UniformTypeIdentifiers

private enum PreviewContent {
    case none
    case text(String)
    case image(NSImage)
    case unsupported(String)
}

struct PreviewWidgetView: View {
    let selectedURLs: Set<URL>
    @State private var content: PreviewContent = .none

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeaderView(title: "Preview")
                .fixedSize(horizontal: false, vertical: true)

            Group {
                if selectedURLs.count == 0 {
                    Text("No Selection")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else if selectedURLs.count > 1 {
                    Text("\(selectedURLs.count) items selected")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                } else {
                    switch content {
                    case .none:
                        Color.clear
                    case .text(let string):
                        GeometryReader { proxy in
                            ScrollView([.horizontal, .vertical]) {
                                Text(string)
                                    .font(.system(size: 10, design: .monospaced))
                                    .textSelection(.enabled)
                                    .padding(8)
                                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height, alignment: .topLeading)
                            }
                        }
                    case .image(let nsImage):
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    case .unsupported(let kind):
                        Text("Preview not available for \(kind)")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 20)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(maxHeight: .infinity)
        .onAppear { loadPreview() }
        .onChange(of: selectedURLs) { _, _ in loadPreview() }
    }

    private func loadPreview() {
        guard selectedURLs.count == 1, let url = selectedURLs.first else {
            content = .none
            return
        }

        guard let resourceValues = try? url.resourceValues(forKeys: [.contentTypeKey]),
              let utType = resourceValues.contentType else {
            content = .unsupported("Unknown")
            return
        }

        if utType.conforms(to: .image) {
            if let nsImage = NSImage(contentsOf: url) {
                content = .image(nsImage)
            } else {
                content = .unsupported(utType.localizedDescription ?? utType.identifier)
            }
        } else if utType.conforms(to: .text)
                    || utType.conforms(to: .sourceCode)
                    || utType.conforms(to: .json)
                    || utType.conforms(to: .xml)
                    || utType.conforms(to: .yaml)
                    || utType.conforms(to: .propertyList) {
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attrs[.size] as? Int64 ?? 0
                if fileSize > 100_000 {
                    content = .text("[File too large to preview (\(fileSize.formattedFileSize))]")
                } else {
                    let text = try String(contentsOf: url, encoding: .utf8)
                    content = .text(text)
                }
            } catch {
                content = .unsupported(utType.localizedDescription ?? utType.identifier)
            }
        } else {
            // Unknown UTType — try reading as UTF-8 text as a fallback
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let fileSize = attrs[.size] as? Int64 ?? 0
                if fileSize > 100_000 {
                    content = .text("[File too large to preview (\(fileSize.formattedFileSize))]")
                } else {
                    let text = try String(contentsOf: url, encoding: .utf8)
                    content = .text(text)
                }
            } catch {
                content = .unsupported(utType.localizedDescription ?? utType.identifier)
            }
        }
    }
}
