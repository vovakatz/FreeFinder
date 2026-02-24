import Foundation

enum SidebarCategory: String {
    case favorites
    case volumes
}

struct SidebarItem: Identifiable, Hashable {
    let id: URL
    let name: String
    let icon: String
    let category: SidebarCategory

    var url: URL { id }
}
