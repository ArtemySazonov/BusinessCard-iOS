import CoreImage
import UIKit

struct QRGenerator {
    func generatePNG(from message: String, size: CGFloat = 220) throws -> Data {
        let data = Data(message.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            throw QRGeneratorError.unavailable
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else {
            throw QRGeneratorError.generationFailed
        }

        let scaleX = size / outputImage.extent.size.width
        let scaleY = size / outputImage.extent.size.height
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else {
            throw QRGeneratorError.generationFailed
        }

        let uiImage = UIImage(cgImage: cgImage)
        guard let png = uiImage.pngData() else {
            throw QRGeneratorError.generationFailed
        }
        return png
    }

    enum QRGeneratorError: Error {
        case unavailable
        case generationFailed
    }
}
