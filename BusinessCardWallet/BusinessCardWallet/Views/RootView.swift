import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Query(sort: \BusinessCard.fullName) private var cards: [BusinessCard]
    @StateObject private var settings = SettingsStore()
    @State private var selection: BusinessCard?

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationStack {
                    List {
                        ForEach(cards) { card in
                            NavigationLink(value: card) {
                                CardListRow(card: card)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                    .navigationTitle("Business Cards")
                    .navigationDestination(for: BusinessCard.self) { card in
                        CardDetailView(card: card, settings: settings)
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: addCard) {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
                }
            } else {
                NavigationSplitView {
                    List(selection: $selection) {
                        ForEach(cards) { card in
                            NavigationLink(value: card) {
                                CardListRow(card: card)
                            }
                        }
                        .onDelete(perform: deleteCards)
                    }
                    .navigationTitle("Business Cards")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: addCard) {
                                Label("Add", systemImage: "plus")
                            }
                        }
                    }
                } detail: {
                    if let selection {
                        CardDetailView(card: selection, settings: settings)
                    } else {
                        ContentUnavailableView("Select a card", systemImage: "creditcard")
                    }
                }
            }
        }
        .environmentObject(settings)
    }

    private func addCard() {
        let newCard = BusinessCard(fullName: "")
        modelContext.insert(newCard)
        selection = newCard
    }

    private func deleteCards(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(cards[index])
        }
    }
}
