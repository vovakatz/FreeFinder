import SwiftUI

struct ConnectToServerSheet: View {
    let onConnect: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var serverAddress = "smb://"
    @FocusState private var isFocused: Bool

    private var recentServers: [String] {
        UserDefaults.standard.stringArray(forKey: "recentServers") ?? []
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text("Connect to Server")
                .font(.headline)

            TextField("Server Address", text: $serverAddress)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .onSubmit {
                    connect()
                }

            if !recentServers.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Servers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    List(recentServers, id: \.self) { server in
                        Text(server)
                            .onTapGesture {
                                serverAddress = server
                            }
                    }
                    .frame(height: min(CGFloat(recentServers.count) * 24, 120))
                    .listStyle(.plain)
                }
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Connect") {
                    connect()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(serverAddress.count <= 6)
            }
        }
        .padding(20)
        .frame(width: 400)
        .onAppear { isFocused = true }
    }

    private func connect() {
        let address = serverAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !address.isEmpty, address != "smb://", address != "afp://" else { return }
        onConnect(address)
        dismiss()
    }
}
