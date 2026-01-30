import Foundation
import SwiftData

enum QrPayloadType: String, Codable, CaseIterable, Identifiable {
    case vCard
    case url

    var id: String { rawValue }
}

@Model
final class BusinessCard {
    @Attribute(.unique) var id: UUID
    var fullName: String
    var company: String
    var title: String
    var email: String
    var phone: String
    var website: String
    var subtitle: String
    var isPrimary: Bool
    var qrPayloadTypeRaw: String
    var qrCustomURL: String

    init(
        id: UUID = UUID(),
        fullName: String = "",
        company: String = "",
        title: String = "",
        email: String = "",
        phone: String = "",
        website: String = "",
        subtitle: String = "",
        isPrimary: Bool = false,
        qrPayloadType: QrPayloadType = .vCard,
        qrCustomURL: String = ""
    ) {
        self.id = id
        self.fullName = fullName
        self.company = company
        self.title = title
        self.email = email
        self.phone = phone
        self.website = website
        self.subtitle = subtitle
        self.isPrimary = isPrimary
        self.qrPayloadTypeRaw = qrPayloadType.rawValue
        self.qrCustomURL = qrCustomURL
    }

    var qrPayloadType: QrPayloadType {
        get { QrPayloadType(rawValue: qrPayloadTypeRaw) ?? .vCard }
        set { qrPayloadTypeRaw = newValue.rawValue }
    }
}
