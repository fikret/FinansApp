import SwiftUI

struct CardsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingAddCard = false
    @State private var editingCard: Card?
    @State private var cardToDelete: Card?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Kayıtlı Kartlar (\(appState.cards.count))")
                    .font(.headline)
                Spacer()
                Button {
                    showingAddCard = true
                } label: {
                    Label("Yeni Kart", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()

            // Cards List
            if appState.cards.isEmpty {
                ContentUnavailableView(
                    "Kart Yok",
                    systemImage: "creditcard",
                    description: Text("Ekstre yükleyebilmek için önce bir kart ekleyin")
                )
            } else {
                List {
                    ForEach(appState.cards) { card in
                        CardRow(card: card)
                            .contextMenu {
                                Button {
                                    editingCard = card
                                } label: {
                                    Label("Düzenle", systemImage: "pencil")
                                }

                                Button(role: .destructive) {
                                    cardToDelete = card
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("Kartlar")
        .sheet(isPresented: $showingAddCard) {
            CardFormView(mode: .add)
        }
        .sheet(item: $editingCard) { card in
            CardFormView(mode: .edit(card))
        }
        .alert("Kartı Sil", isPresented: .init(
            get: { cardToDelete != nil },
            set: { if !$0 { cardToDelete = nil } }
        )) {
            Button("İptal", role: .cancel) {
                cardToDelete = nil
            }
            Button("Sil", role: .destructive) {
                if let card = cardToDelete {
                    appState.deleteCard(card.id)
                }
                cardToDelete = nil
            }
        } message: {
            Text("Bu kartı silmek istediğinizden emin misiniz? Karta ait tüm ekstreler ve işlemler de silinecek.")
        }
    }
}

struct CardRow: View {
    let card: Card

    var body: some View {
        HStack(spacing: 16) {
            // Card Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 50, height: 35)

                Image(systemName: "creditcard.fill")
                    .foregroundStyle(.white)
            }

            // Card Info
            VStack(alignment: .leading, spacing: 2) {
                Text(card.name)
                    .fontWeight(.medium)

                HStack {
                    if let bank = card.bank {
                        Text(bank)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let lastFour = card.lastFour {
                        if card.bank != nil {
                            Text("•")
                                .foregroundStyle(.secondary)
                        }
                        Text("**** \(lastFour)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
    }
}

struct CardFormView: View {
    enum Mode {
        case add
        case edit(Card)
    }

    let mode: Mode
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var bank = ""
    @State private var lastFour = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("İptal") {
                    dismiss()
                }
                Spacer()
                Text(isEditing ? "Kartı Düzenle" : "Yeni Kart")
                    .fontWeight(.semibold)
                Spacer()
                Button(isEditing ? "Kaydet" : "Ekle") {
                    saveCard()
                }
                .disabled(name.isEmpty)
                .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    TextField("Kart Adı", text: $name)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Kart Adı *")
                }

                Section {
                    TextField("Örn: Garanti", text: $bank)
                        .textFieldStyle(.roundedBorder)
                } header: {
                    Text("Banka")
                }

                Section {
                    TextField("1234", text: $lastFour)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: lastFour) { _, newValue in
                            // Only allow digits and max 4 characters
                            lastFour = String(newValue.filter { $0.isNumber }.prefix(4))
                        }
                } header: {
                    Text("Son 4 Hane")
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 350)
        .onAppear {
            if case .edit(let card) = mode {
                name = card.name
                bank = card.bank ?? ""
                lastFour = card.lastFour ?? ""
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func saveCard() {
        let bankValue = bank.isEmpty ? nil : bank
        let lastFourValue = lastFour.isEmpty ? nil : lastFour

        if case .edit(let card) = mode {
            var updatedCard = card
            updatedCard.name = name
            updatedCard.bank = bankValue
            updatedCard.lastFour = lastFourValue
            appState.updateCard(updatedCard)
        } else {
            appState.addCard(name: name, bank: bankValue, lastFour: lastFourValue)
        }

        dismiss()
    }
}

#Preview {
    CardsView()
        .environmentObject(AppState())
}
