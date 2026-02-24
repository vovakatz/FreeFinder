import SwiftUI

struct SidebarView: View {
    let viewModel: SidebarViewModel
    @Binding var selection: URL?

    var body: some View {
        List(selection: $selection) {
            Section("Favorites") {
                ForEach(viewModel.favorites) { item in
                    Label(item.name, systemImage: item.icon)
                        .tag(item.url)
                        .contextMenu {
                            Button("Remove") {
                                viewModel.removeFavorite(item)
                            }
                        }
                }
                .dropDestination(for: URL.self) { urls, index in
                    for url in urls {
                        viewModel.insertFavorite(url: url, at: index)
                    }
                }
            }

            Section("Volumes") {
                ForEach(viewModel.volumes) { item in
                    Label(item.name, systemImage: item.icon)
                        .tag(item.url)
                }
            }
        }
        .listStyle(.sidebar)
    }
}
