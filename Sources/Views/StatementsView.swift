import SwiftUI
import UniformTypeIdentifiers

struct StatementsView: View {
    @EnvironmentObject var appState: AppState
    @State private var isImporting = false

    var body: some View {
        HSplitView {
            // Left: Upload Area
            VStack(alignment: .leading, spacing: 16) {
                Text("PDF Ekstre Yükle")
                    .font(.headline)

                if !appState.hasApiKey {
                    ContentUnavailableView(
                        "API Key Gerekli",
                        systemImage: "key.fill",
                        description: Text("Önce Ayarlar bölümünden OpenAI API key girin")
                    )
                } else {
                    // Drop Zone
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(.secondary)

                        VStack(spacing: 12) {
                            if appState.isLoading {
                                ProgressView()
                                    .scaleEffect(1.5)
                                Text("AI ile analiz ediliyor...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            } else {
                                Image(systemName: "doc.badge.plus")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.secondary)
                                Text("PDF ekstre dosyası seçin")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Kart bilgileri otomatik algılanacak")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                Button("PDF Seç") {
                                    isImporting = true
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                    .frame(height: 220)
                    .fileImporter(
                        isPresented: $isImporting,
                        allowedContentTypes: [UTType.pdf],
                        allowsMultipleSelection: false
                    ) { result in
                        switch result {
                        case .success(let urls):
                            if let url = urls.first {
                                Task {
                                    guard url.startAccessingSecurityScopedResource() else { return }
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    await appState.uploadAndParseStatement(pdfURL: url)
                                }
                            }
                        case .failure(let error):
                            appState.error = error.localizedDescription
                        }
                    }

                    if let error = appState.error {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                Spacer()
            }
            .padding()
            .frame(minWidth: 300, maxWidth: 400)

            // Right: Statements List
            VStack(alignment: .leading, spacing: 16) {
                Text("Yüklenen Ekstreler")
                    .font(.headline)

                if appState.statements.isEmpty {
                    ContentUnavailableView(
                        "Ekstre Yok",
                        systemImage: "doc.text",
                        description: Text("Henüz ekstre yüklenmemiş")
                    )
                } else {
                    List {
                        ForEach(appState.statements) { statement in
                            StatementRow(
                                statement: statement,
                                cardName: cardName(for: statement.cardId),
                                transactionCount: transactionCount(for: statement.id)
                            )
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appState.deleteStatement(statement.id)
                                    } label: {
                                        Label("Sil", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                appState.deleteStatement(appState.statements[index].id)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Ekstreler")
    }

    private func cardName(for cardId: String) -> String {
        appState.cards.first { $0.id == cardId }?.name ?? "Bilinmeyen Kart"
    }

    private func transactionCount(for statementId: String) -> Int {
        DatabaseService.shared.getTransactionCount(for: statementId)
    }
}

struct StatementRow: View {
    let statement: Statement
    let cardName: String
    let transactionCount: Int

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMM yyyy"
        df.locale = Locale(identifier: "tr_TR")
        return df
    }()

    var body: some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(cardName)
                    .fontWeight(.medium)

                if let start = statement.periodStart, let end = statement.periodEnd {
                    Text("\(dateFormatter.string(from: start)) - \(dateFormatter.string(from: end))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("\(transactionCount) işlem")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let total = statement.totalAmount {
                    Text(formatCurrency(total))
                        .fontWeight(.semibold)
                }

                if let dueDate = statement.dueDate {
                    Text("Son ödeme: \(dateFormatter.string(from: dueDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }
}

#Preview {
    StatementsView()
        .environmentObject(AppState())
}
