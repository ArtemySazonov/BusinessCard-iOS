import Foundation
import os

struct SignRequest: Encodable {
    struct FilePayload: Encodable {
        let name: String
        let data: String
    }

    let passJson: String
    let files: [FilePayload]
}

enum SigningError: LocalizedError {
    case invalidURL
    case networkError
    case serverError(code: String, message: String)
    case invalidResponse
    case invalidPass

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The signer URL is invalid."
        case .networkError:
            return "Could not reach the signer service."
        case .serverError(let code, let message):
            return "Signer error (\(code)): \(message)"
        case .invalidResponse:
            return "The signer returned an unexpected response."
        case .invalidPass:
            return "The signer returned an invalid pass file."
        }
    }
}

struct SigningClient {
    let settings: SettingsStore
    let logger = Logger(subsystem: "BusinessCardWallet", category: "SigningClient")

    func sign(payload: PassPayload) async throws -> Data {
        guard let url = URL(string: settings.signerBaseURL + "/sign-pass") else {
            throw SigningError.invalidURL
        }

        let files = payload.files.map { key, value in
            SignRequest.FilePayload(name: key, data: value.base64EncodedString())
        }
        let requestBody = SignRequest(passJson: payload.passJSON.base64EncodedString(), files: files)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        var attempts = 0
        var lastError: Error?
        while attempts < 3 {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw SigningError.invalidResponse
                }
                if http.statusCode >= 400 {
                    if let serverError = try? JSONDecoder().decode(ServerError.self, from: data) {
                        throw SigningError.serverError(code: serverError.code, message: serverError.message)
                    }
                    throw SigningError.invalidResponse
                }
                return data
            } catch {
                lastError = error
                logger.error("Signing attempt failed: \(error.localizedDescription, privacy: .public)")
                attempts += 1
                try await Task.sleep(nanoseconds: UInt64(500_000_000 * attempts))
            }
        }
        throw lastError ?? SigningError.networkError
    }

    func testConnection() async throws -> HealthResponse {
        guard let url = URL(string: settings.signerBaseURL + "/health") else {
            throw SigningError.invalidURL
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode < 400 else {
            throw SigningError.invalidResponse
        }
        return try JSONDecoder().decode(HealthResponse.self, from: data)
    }
}

struct ServerError: Decodable {
    let code: String
    let message: String
}

struct HealthResponse: Decodable {
    let status: String
    let version: String
}
