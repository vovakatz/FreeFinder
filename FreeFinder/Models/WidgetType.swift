enum WidgetType: String, CaseIterable, Identifiable {
    case info = "Info"
    case preview = "Preview"
    case terminal = "Terminal"
    case images = "Images"

    var id: String { rawValue }
}
