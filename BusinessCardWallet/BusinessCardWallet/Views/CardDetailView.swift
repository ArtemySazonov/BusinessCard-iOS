import SwiftUI
import PassKit

struct CardDetailView: View {
    @Bindable var card: BusinessCard
    @StateObject private var viewModel: CardDetailViewModel
    @State private var showSettings = false
    @State private var showShareSheet = false

    init(card: BusinessCard, settings: SettingsStore) {
        self._card = Bindable(wrappedValue: card)
        _viewModel = StateObject(wrappedValue: CardDetailViewModel(settings: settings))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                PassPreviewView(card: card)
                CardEditorView(card: $card)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                HStack(spacing: 16) {
                    Button {
                        Task { await viewModel.generateAndSign(card: card) }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Label("Generate Pass", systemImage: "wallet.pass")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(card.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        showShareSheet = true
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .disabled(viewModel.signedPassData == nil)
                }
            }
            .padding(.vertical, 24)
        }
        .navigationTitle(card.fullName.isEmpty ? "Business Card" : card.fullName)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(item: $viewModel.signedPassData) { data in
            AddPassView(passData: data)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = viewModel.signedPassData {
                ShareSheet(activityItems: [data])
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}
