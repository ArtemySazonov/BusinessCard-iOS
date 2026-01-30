import Foundation
import SwiftUI

@MainActor
final class SettingsStore: ObservableObject {
    @AppStorage("signerBaseURL") var signerBaseURL: String = "http://192.168.1.2:8080"
    @AppStorage("passTypeIdentifier") var passTypeIdentifier: String = "pass.com.example.businesscard"
    @AppStorage("teamIdentifier") var teamIdentifier: String = "TEAMID1234"
    @AppStorage("organizationName") var organizationName: String = "Example Org"
    @AppStorage("passDescription") var passDescription: String = "Business Card"
}
