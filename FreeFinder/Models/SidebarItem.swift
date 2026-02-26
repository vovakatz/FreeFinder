import Foundation

enum SidebarCategory: String {
    case favorites
    case volumes
    case network
}

struct SidebarItem: Identifiable, Hashable {
    let id: URL
    let name: String
    let icon: String
    let category: SidebarCategory
    var isDefault: Bool = false

    var url: URL { id }
}
