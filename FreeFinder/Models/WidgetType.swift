enum WidgetType: String, CaseIterable, Identifiable {
    case info = "Info"
    case preview = "Preview"
    case terminal = "Terminal"
    case images = "Images"
    case git = "Git"
    case clipboard = "Clipboard"
    case systemMonitor = "System Monitor"

    var id: String { rawValue }
}
