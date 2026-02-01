import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("AI Önerileri")
                    .font(.headline)
                Spacer()
                Button {
                    Task {
                        await appState.loadInsights()
                    }
                } label: {
                    Label("Yenile", systemImage: "arrow.clockwise")
                }
                .disabled(appState.isLoading || !appState.hasApiKey)
            }
            .padding()

            if !appState.hasApiKey {
                ContentUnavailableView(
                    "API Key Gerekli",
                    systemImage: "key.fill",
                    description: Text("AI önerilerini görmek için Ayarlar'dan OpenAI API key ekleyin")
                )
            } else if appState.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analiz ediliyor...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else if appState.insights.isEmpty {
                ContentUnavailableView(
                    "Öneri Yok",
                    systemImage: "sparkles",
                    description: Text("Henüz öneri yok. Ekstre yükledikten sonra AI önerileri burada görünecek.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(appState.insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                    .padding()
                }
            }

            if let error = appState.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                    Text(error)
                        .font(.caption)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
        .navigationTitle("AI Önerileri")
        .onAppear {
            if appState.insights.isEmpty && appState.hasApiKey && !appState.transactions.isEmpty {
                Task {
                    await appState.loadInsights()
                }
            }
        }
    }
}

struct InsightCard: View {
    let insight: AIInsight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 40, height: 40)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .fontWeight(.semibold)

                Text(insight.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    if let category = insight.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }

                    if let amount = insight.amount {
                        Text(formatCurrency(amount))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private var iconName: String {
        switch insight.type {
        case .trend: return "chart.line.uptrend.xyaxis"
        case .warning: return "exclamationmark.triangle.fill"
        case .tip: return "lightbulb.fill"
        case .subscription: return "repeat"
        }
    }

    private var iconColor: Color {
        switch insight.type {
        case .trend: return .blue
        case .warning: return .orange
        case .tip: return .green
        case .subscription: return .purple
        }
    }

    private var backgroundColor: Color {
        iconColor.opacity(0.05)
    }

    private var borderColor: Color {
        iconColor.opacity(0.2)
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
    InsightsView()
        .environmentObject(AppState())
}
