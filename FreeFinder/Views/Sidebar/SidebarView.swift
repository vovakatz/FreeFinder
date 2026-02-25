import SwiftUI

struct SidebarView: View {
    let viewModel: SidebarViewModel
    @Binding var selection: URL?

    var body: some View {
        List(selection: $selection) {
            Section(header: Text("Favorites").fontWeight(.bold)) {
                ForEach(viewModel.favorites) { item in
                    Label(item.name, systemImage: item.icon)
                        .tag(item.url)
                        .contextMenu {
                            Button("Remove") {
                                viewModel.removeFavorite(item)
                            }
                            .disabled(item.isDefault)
                        }
                }
                .dropDestination(for: URL.self) { urls, index in
                    for url in urls {
                        viewModel.insertFavorite(url: url, at: index)
                    }
                }
            }

            Section(header: Text("Volumes").fontWeight(.bold)) {
                ForEach(viewModel.volumes) { item in
                    Label(item.name, systemImage: item.icon)
                        .tag(item.url)
                }
            }
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(Color.black.opacity(0.15))
    }
}
