import Foundation

struct VCardBuilder {
    func build(for card: BusinessCard) -> String {
        var lines: [String] = [
            "BEGIN:VCARD",
            "VERSION:3.0",
            "FN:\(card.fullName)"
        ]

        if !card.company.isEmpty {
            lines.append("ORG:\(card.company)")
        }

        if !card.title.isEmpty {
            lines.append("TITLE:\(card.title)")
        }

        if !card.email.isEmpty {
            lines.append("EMAIL;TYPE=INTERNET:\(card.email)")
        }

        if !card.phone.isEmpty {
            lines.append("TEL;TYPE=CELL:\(card.phone)")
        }

        if !card.website.isEmpty {
            lines.append("URL:\(card.website)")
        }

        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }
}
