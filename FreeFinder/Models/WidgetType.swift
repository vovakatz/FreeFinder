enum WidgetType: String, CaseIterable, Identifiable {
    case info = "Info"
    case preview = "Preview"
    case terminal = "Terminal"
    case images = "Images"
    case git = "Git"
    case clipboard = "Clipboard"

    var id: String { rawValue }
}
