import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cards: [BusinessCard]
    @Binding var card: BusinessCard

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Section {
                TextField("Full Name", text: $card.fullName)
                    .textContentType(.name)
                    .font(.title2)
            } header: {
                Text("Identity")
                    .font(.headline)
            }

            Toggle("Primary Card", isOn: Binding(
                get: { card.isPrimary },
                set: { isPrimary in
                    card.isPrimary = isPrimary
                    if isPrimary {
                        setPrimary(card)
                    }
                }
            ))

            VStack(spacing: 12) {
                TextField("Company", text: $card.company)
                TextField("Title / Role", text: $card.title)
                TextField("Subtitle / Note", text: $card.subtitle)
            }
            .textInputAutocapitalization(.words)

            VStack(spacing: 12) {
                TextField("Email", text: $card.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                TextField("Phone", text: $card.phone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)
                TextField("Website", text: $card.website)
                    .textContentType(.URL)
                    .keyboardType(.URL)
            }

            Picker("QR Payload", selection: $card.qrPayloadType) {
                Text("vCard").tag(QrPayloadType.vCard)
                Text("URL").tag(QrPayloadType.url)
            }
            .pickerStyle(.segmented)

            if card.qrPayloadType == .url {
                TextField("Custom URL", text: $card.qrCustomURL)
                    .keyboardType(.URL)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
    }

    private func setPrimary(_ selected: BusinessCard) {
        for other in cards where other.id != selected.id {
            other.isPrimary = false
        }
        try? modelContext.save()
    }
}
