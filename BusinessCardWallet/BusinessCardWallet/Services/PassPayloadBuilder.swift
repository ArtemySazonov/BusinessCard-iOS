import Foundation
import UIKit

struct PassPayload {
    let passJSON: Data
    let files: [String: Data]
}

struct PassPayloadBuilder {
    let settings: SettingsStore
    let vCardBuilder = VCardBuilder()
    let qrGenerator = QRGenerator()

    func build(for card: BusinessCard) throws -> PassPayload {
        let message: String
        switch card.qrPayloadType {
        case .vCard:
            message = vCardBuilder.build(for: card)
        case .url:
            message = card.qrCustomURL
        }

        let qrPNG = try qrGenerator.generatePNG(from: message)
        let iconPNG = ImageRenderer.circleIconPNG(size: 29)
        let icon2xPNG = ImageRenderer.circleIconPNG(size: 58)
        let icon3xPNG = ImageRenderer.circleIconPNG(size: 87)

        let pass = PassJSON(
            formatVersion: 1,
            serialNumber: card.id.uuidString,
            passTypeIdentifier: settings.passTypeIdentifier,
            teamIdentifier: settings.teamIdentifier,
            organizationName: settings.organizationName,
            description: settings.passDescription,
            backgroundColor: "rgb(28,28,30)",
            foregroundColor: "rgb(255,255,255)",
            labelColor: "rgb(174,174,178)",
            barcodeMessage: message,
            card: card
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let passJSON = try encoder.encode(pass)

        var files: [String: Data] = [
            "icon.png": iconPNG,
            "icon@2x.png": icon2xPNG,
            "icon@3x.png": icon3xPNG,
            "thumbnail.png": qrPNG
        ]

        return PassPayload(passJSON: passJSON, files: files)
    }
}

struct PassJSON: Codable {
    struct Barcode: Codable {
        let format: String
        let message: String
        let messageEncoding: String
    }

    struct Generic: Codable {
        struct Field: Codable {
            let key: String
            let label: String
            let value: String
        }

        let primaryFields: [Field]
        let secondaryFields: [Field]
        let auxiliaryFields: [Field]
        let backFields: [Field]
    }

    let formatVersion: Int
    let serialNumber: String
    let passTypeIdentifier: String
    let teamIdentifier: String
    let organizationName: String
    let description: String
    let backgroundColor: String
    let foregroundColor: String
    let labelColor: String
    let barcode: Barcode
    let barcodes: [Barcode]
    let generic: Generic

    init(
        formatVersion: Int,
        serialNumber: String,
        passTypeIdentifier: String,
        teamIdentifier: String,
        organizationName: String,
        description: String,
        backgroundColor: String,
        foregroundColor: String,
        labelColor: String,
        barcodeMessage: String,
        card: BusinessCard
    ) {
        self.formatVersion = formatVersion
        self.serialNumber = serialNumber
        self.passTypeIdentifier = passTypeIdentifier
        self.teamIdentifier = teamIdentifier
        self.organizationName = organizationName
        self.description = description
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.labelColor = labelColor
        let barcode = Barcode(format: "PKBarcodeFormatQR", message: barcodeMessage, messageEncoding: "iso-8859-1")
        self.barcode = barcode
        self.barcodes = [barcode]
        let generic = Generic(
            primaryFields: [
                .init(key: "name", label: "NAME", value: card.fullName)
            ],
            secondaryFields: [
                .init(key: "company", label: "COMPANY", value: card.company),
                .init(key: "title", label: "TITLE", value: card.title)
            ].filter { !$0.value.isEmpty },
            auxiliaryFields: [
                .init(key: "email", label: "EMAIL", value: card.email),
                .init(key: "phone", label: "PHONE", value: card.phone),
                .init(key: "website", label: "WEB", value: card.website)
            ].filter { !$0.value.isEmpty },
            backFields: [
                .init(key: "note", label: "NOTE", value: card.subtitle)
            ].filter { !$0.value.isEmpty }
        )
        self.generic = generic
    }
}

enum ImageRenderer {
    static func circleIconPNG(size: CGFloat) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { context in
            UIColor.black.setFill()
            context.fill(CGRect(origin: .zero, size: CGSize(width: size, height: size)))
            let inset = size * 0.15
            let circleRect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: circleRect)
        }
        return image.pngData() ?? Data()
    }
}
