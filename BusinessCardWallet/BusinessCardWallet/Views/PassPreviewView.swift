import SwiftUI

struct PassPreviewView: View {
    let card: BusinessCard
    private let qrGenerator = QRGenerator()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CARD")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(card.fullName.isEmpty ? "Your Name" : card.fullName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)

            if !card.company.isEmpty || !card.title.isEmpty {
                Text([card.company, card.title].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(Color.white.opacity(0.8))
            }

            Spacer()

            HStack {
                Spacer()
                qrImage
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 96, height: 96)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: 340, minHeight: 220)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Wallet style pass preview for \(card.fullName)")
    }

    private var qrImage: Image {
        let message: String
        switch card.qrPayloadType {
        case .vCard:
            message = VCardBuilder().build(for: card)
        case .url:
            message = card.qrCustomURL
        }

        if let data = try? qrGenerator.generatePNG(from: message, size: 200),
           let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "qrcode")
    }
}
