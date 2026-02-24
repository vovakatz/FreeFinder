import Foundation

enum SortField: String, CaseIterable {
    case name
    case dateModified
    case size
    case kind
}

struct SortCriteria: Equatable {
    var field: SortField = .name
    var ascending: Bool = true
}
