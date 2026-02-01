import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCategory: CategoryBreakdown?
    @State private var selectedMonth: MonthlyData?

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        df.locale = Locale(identifier: "tr_TR")
        return df
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Harcama özetiniz")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    DateFilterPicker(selectedFilter: $appState.selectedDateFilter)
                        .onChange(of: appState.selectedDateFilter) { _, newValue in
                            appState.setDateFilter(newValue)
                        }
                }

                // Stats Cards
                HStack(spacing: 16) {
                    StatCard(
                        title: "Toplam Harcama",
                        value: formatCurrency(appState.dashboardStats?.totalSpending ?? 0),
                        icon: "wallet.pass.fill",
                        color: .blue
                    )

                    StatCard(
                        title: "Kayıtlı Kart",
                        value: "\(appState.cards.count)",
                        icon: "creditcard.fill",
                        color: .green
                    )

                    StatCard(
                        title: "İşlem Sayısı",
                        value: "\(appState.dashboardStats?.transactionCount ?? 0)",
                        icon: "list.bullet.rectangle.fill",
                        color: .purple
                    )
                }

                // Charts
                HStack(alignment: .top, spacing: 16) {
                    // Pie Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Kategori Dağılımı")
                            .font(.headline)

                        if let breakdown = appState.dashboardStats?.categoryBreakdown, !breakdown.isEmpty {
                            ZStack {
                                Chart(breakdown) { item in
                                    SectorMark(
                                        angle: .value("Tutar", item.amount),
                                        innerRadius: .ratio(0.5),
                                        angularInset: 2
                                    )
                                    .foregroundStyle(Color(hex: item.color))
                                    .cornerRadius(4)
                                    .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.4)
                                }
                                .chartOverlay { proxy in
                                    GeometryReader { geometry in
                                        Rectangle()
                                            .fill(Color.clear)
                                            .contentShape(Rectangle())
                                            .onContinuousHover { phase in
                                                switch phase {
                                                case .active(let location):
                                                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                                                    let angle = angleFromCenter(center: center, point: location)
                                                    selectedCategory = categoryForAngle(angle, breakdown: breakdown)
                                                case .ended:
                                                    selectedCategory = nil
                                                }
                                            }
                                    }
                                }
                                .frame(height: 200)

                                // Center tooltip
                                if let selected = selectedCategory {
                                    VStack(spacing: 4) {
                                        Text(selected.category)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                        Text(formatCurrency(selected.amount))
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        Text("%\(String(format: "%.1f", selected.percentage))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .transition(.opacity)
                                }
                            }

                            // Legend (clickable)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(breakdown) { item in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color(hex: item.color))
                                            .frame(width: 10, height: 10)
                                        Text(item.category)
                                            .font(.caption)
                                        Spacer()
                                        Text(formatCurrency(item.amount))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 6)
                                    .background(selectedCategory?.id == item.id ? Color(hex: item.color).opacity(0.2) : Color.clear)
                                    .cornerRadius(6)
                                    .opacity(selectedCategory == nil || selectedCategory?.id == item.id ? 1.0 : 0.5)
                                    .onTapGesture {
                                        withAnimation(.easeInOut) {
                                            if selectedCategory?.id == item.id {
                                                selectedCategory = nil
                                            } else {
                                                selectedCategory = item
                                            }
                                        }
                                    }
                                    .onHover { hovering in
                                        withAnimation(.easeInOut(duration: 0.15)) {
                                            if hovering {
                                                selectedCategory = item
                                            } else if selectedCategory?.id == item.id {
                                                selectedCategory = nil
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView("Veri Yok", systemImage: "chart.pie", description: Text("Henüz harcama verisi yok"))
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)

                    // Bar Chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Aylık Karşılaştırma")
                            .font(.headline)

                        if let monthly = appState.dashboardStats?.monthlyComparison, monthly.contains(where: { $0.amount > 0 }) {
                            Chart(monthly) { item in
                                BarMark(
                                    x: .value("Ay", item.month),
                                    y: .value("Tutar", item.amount)
                                )
                                .foregroundStyle(selectedMonth?.id == item.id ? Color.blue : Color.blue.opacity(0.7))
                                .cornerRadius(4)
                                .annotation(position: .top) {
                                    if selectedMonth?.id == item.id {
                                        Text(formatCurrency(item.amount))
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color(.windowBackgroundColor))
                                            .cornerRadius(4)
                                            .shadow(radius: 1)
                                    }
                                }
                            }
                            .frame(height: 200)
                            .chartOverlay { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(Color.clear)
                                        .contentShape(Rectangle())
                                        .onContinuousHover { phase in
                                            switch phase {
                                            case .active(let location):
                                                if let month: String = proxy.value(atX: location.x) {
                                                    selectedMonth = monthly.first { $0.month == month }
                                                }
                                            case .ended:
                                                selectedMonth = nil
                                            }
                                        }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
                                    AxisValueLabel {
                                        if let amount = value.as(Double.self) {
                                            Text("\(Int(amount / 1000))K")
                                        }
                                    }
                                }
                            }
                        } else {
                            ContentUnavailableView("Veri Yok", systemImage: "chart.bar", description: Text("Henüz harcama verisi yok"))
                                .frame(height: 200)
                        }
                    }
                    .padding()
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(maxWidth: .infinity)
                }

                // Recent Transactions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Son İşlemler")
                        .font(.headline)

                    if let transactions = appState.dashboardStats?.recentTransactions, !transactions.isEmpty {
                        ForEach(transactions) { txn in
                            TransactionRow(transaction: txn)
                        }
                    } else {
                        ContentUnavailableView("İşlem Yok", systemImage: "doc.text", description: Text("Henüz işlem kaydı yok"))
                    }
                }
                .padding()
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }

    private func angleFromCenter(center: CGPoint, point: CGPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        var angle = atan2(dy, dx) * 180 / .pi
        angle = angle + 90 // Adjust for chart starting at top
        if angle < 0 { angle += 360 }
        return angle
    }

    private func categoryForAngle(_ angle: Double, breakdown: [CategoryBreakdown]) -> CategoryBreakdown? {
        let total = breakdown.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return nil }

        var currentAngle: Double = 0
        for item in breakdown {
            let sectorAngle = (item.amount / total) * 360
            if angle >= currentAngle && angle < currentAngle + sectorAngle {
                return item
            }
            currentAngle += sectorAngle
        }
        return breakdown.last
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
            }
            Spacer()
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .padding()
                .background(color.opacity(0.1))
                .clipShape(Circle())
        }
        .padding()
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity)
    }
}

struct DateFilterPicker: View {
    @Binding var selectedFilter: DateFilter

    var body: some View {
        Picker("Dönem", selection: $selectedFilter) {
            Section("Hızlı Seçim") {
                ForEach(DateFilter.presets) { filter in
                    Text(filter.displayName)
                        .tag(filter)
                }
            }
            Section("Aylar") {
                ForEach(DateFilter.recentMonths) { filter in
                    Text(filter.displayName)
                        .tag(filter)
                }
            }
        }
        .pickerStyle(.menu)
        .frame(width: 160)
    }
}

struct TransactionRow: View {
    let transaction: Transaction

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        df.locale = Locale(identifier: "tr_TR")
        return df
    }()

    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4, height: 40)

            VStack(alignment: .leading) {
                Text(transaction.merchant ?? transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(dateFormatter.string(from: transaction.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let category = transaction.category {
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.1))
                    .foregroundStyle(categoryColor)
                    .clipShape(Capsule())
            }

            Text(formatCurrency(transaction.amount))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        let colorHex = Category.defaults.first { $0.name == transaction.category }?.color ?? "#6b7280"
        return Color(hex: colorHex)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState())
}
