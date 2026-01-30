import SwiftUI

struct CardListRow: View {
    let card: BusinessCard

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.fullName.isEmpty ? "Untitled" : card.fullName)
                .font(.headline)
            if !card.company.isEmpty || !card.title.isEmpty {
                Text([card.company, card.title].filter { !$0.isEmpty }.joined(separator: " • "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(card.fullName), \(card.company) \(card.title)")
    }
}
