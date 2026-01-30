import SwiftUI
import PassKit

struct AddPassView: UIViewControllerRepresentable {
    let passData: Data

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        let pass = try? PKPass(data: passData)
        return PKAddPassesViewController(pass: pass!)
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {}
}
