import SwiftUI
import SwiftData

@main
struct BusinessCardWalletApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: BusinessCard.self)
    }
}
