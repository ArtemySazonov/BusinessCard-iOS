import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: SettingsStore
    @State private var statusMessage: String?
    @State private var isTesting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Signer") {
                    TextField("Base URL", text: $settings.signerBaseURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .textContentType(.URL)

                    Button {
                        Task { await testConnection() }
                    } label: {
                        if isTesting {
                            ProgressView()
                        } else {
                            Text("Connection Test")
                        }
                    }

                    if let statusMessage {
                        Text(statusMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Pass Identifiers") {
                    TextField("Pass Type Identifier", text: $settings.passTypeIdentifier)
                        .textInputAutocapitalization(.never)
                    TextField("Team Identifier", text: $settings.teamIdentifier)
                        .textInputAutocapitalization(.never)
                    TextField("Organization Name", text: $settings.organizationName)
                    TextField("Description", text: $settings.passDescription)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        do {
            let response = try await SigningClient(settings: settings).testConnection()
            statusMessage = "Signer OK (v\(response.version))"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
