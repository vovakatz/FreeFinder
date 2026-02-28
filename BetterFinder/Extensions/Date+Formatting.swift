import Foundation

extension Date {
    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()

    var fileDateString: String {
        Date.fileDateFormatter.string(from: self)
    }
}
