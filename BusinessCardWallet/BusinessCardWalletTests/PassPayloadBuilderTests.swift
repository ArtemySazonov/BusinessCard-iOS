import XCTest
@testable import BusinessCardWallet

final class PassPayloadBuilderTests: XCTestCase {
    @MainActor
    func testPassJSONHasRequiredKeys() throws {
        let settings = SettingsStore()
        settings.passTypeIdentifier = "pass.com.example.test"
        settings.teamIdentifier = "TEAM123"
        settings.organizationName = "Org"
        settings.passDescription = "Desc"

        let card = BusinessCard(fullName: "Alex", company: "Org")
        let payload = try PassPayloadBuilder(settings: settings).build(for: card)

        let json = try JSONSerialization.jsonObject(with: payload.passJSON) as? [String: Any]
        XCTAssertNotNil(json?["formatVersion"])
        XCTAssertNotNil(json?["passTypeIdentifier"])
        XCTAssertNotNil(json?["serialNumber"])
        XCTAssertNotNil(json?["teamIdentifier"])
        XCTAssertNotNil(json?["organizationName"])
        XCTAssertNotNil(json?["description"])
        XCTAssertNotNil(json?["barcode"])
        XCTAssertNotNil(json?["generic"])
    }
}
