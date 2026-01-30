import XCTest
@testable import BusinessCardWallet

final class VCardBuilderTests: XCTestCase {
    func testVCardIncludesRequiredFields() {
        let card = BusinessCard(
            fullName: "Alex Johnson",
            company: "Example Co",
            title: "Designer",
            email: "alex@example.com",
            phone: "+1-555-0100",
            website: "https://example.com"
        )

        let vcard = VCardBuilder().build(for: card)

        XCTAssertTrue(vcard.contains("FN:Alex Johnson"))
        XCTAssertTrue(vcard.contains("ORG:Example Co"))
        XCTAssertTrue(vcard.contains("TITLE:Designer"))
        XCTAssertTrue(vcard.contains("EMAIL;TYPE=INTERNET:alex@example.com"))
        XCTAssertTrue(vcard.contains("TEL;TYPE=CELL:+1-555-0100"))
        XCTAssertTrue(vcard.contains("URL:https://example.com"))
    }
}
