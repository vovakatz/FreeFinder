import Foundation

enum NetworkServiceType: String, Hashable {
    case smb
    case afp
}

struct NetworkHost: Identifiable, Hashable {
    let id: String
    let name: String
    let hostname: String
    var services: Set<NetworkServiceType>

    var networkURL: URL {
        URL(string: "network://\(hostname)")!
    }
}

struct NetworkShare: Identifiable, Hashable {
    let id: String
    let name: String
    let hostname: String
    let type: NetworkServiceType

    var mountURL: URL {
        URL(string: "\(type.rawValue)://\(hostname)/\(name)")!
    }
}

struct NetworkCredentials {
    var username = ""
    var password = ""
    var saveToKeychain = false
}

enum ShareEnumerationResult {
    case success([NetworkShare])
    case authRequired
    case error(String)
}
