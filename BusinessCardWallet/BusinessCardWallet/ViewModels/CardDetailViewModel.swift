import Foundation
import PassKit
import os

@MainActor
final class CardDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var signedPassData: Data?

    private let settings: SettingsStore
    private let signingClient: SigningClient
    private let logger = Logger(subsystem: "BusinessCardWallet", category: "CardDetailViewModel")

    init(settings: SettingsStore) {
        self.settings = settings
        self.signingClient = SigningClient(settings: settings)
    }

    func generateAndSign(card: BusinessCard) async {
        isLoading = true
        errorMessage = nil
        signedPassData = nil

        do {
            let payload = try PassPayloadBuilder(settings: settings).build(for: card)
            let signedData = try await signingClient.sign(payload: payload)
            _ = try PKPass(data: signedData)
            signedPassData = signedData
        } catch {
            logger.error("Failed to sign pass: \(error.localizedDescription, privacy: .public)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
