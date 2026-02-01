import SwiftUI
import Charts

struct ComparisonView: View {
    @State private var month1: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var month2: Date = Date()
    @State private var comparison: MonthComparison?
    @State private var availableMonths: [Date] = []

    private let database = DatabaseService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Month Selectors
                monthSelectorsSection

                if let comparison = comparison {
                    // Total Comparison Cards
                    totalComparisonSection(comparison)

                    // Bar Chart Comparison
                    chartSection(comparison)

                    // Category Table
                    categoryTableSection(comparison)

                    // Top Changes
                    topChangesSection(comparison)
                } else {
                    ContentUnavailableView(
                        "Karşılaştırma Yok",
                        systemImage: "arrow.left.arrow.right",
                        description: Text("İki ay seçerek karşılaştırma yapabilirsiniz.")
                    )
                }
            }
            .padding()
        }
        .background(Color(.windowBackgroundColor))
        .navigationTitle("Karşılaştırma")
        .onAppear {
            loadAvailableMonths()
            loadComparison()
        }
    }

    // MARK: - Month Selectors
    private var monthSelectorsSection: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Ay 1")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Ay 1", selection: $month1) {
                    ForEach(availableMonths, id: \.self) { date in
                        Text(formatMonth(date)).tag(date)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 150)
                .onChange(of: month1) { _, _ in
                    loadComparison()
                }
            }

            Image(systemName: "arrow.right")
                .font(.title2)
                .foregroundColor(.secondary)

            VStack(alignment: .leading) {
                Text("Ay 2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Ay 2", selection: $month2) {
                    ForEach(availableMonths, id: \.self) { date in
                        Text(formatMonth(date)).tag(date)
                    }
                }
                .labelsHidden()
                .frame(minWidth: 150)
                .onChange(of: month2) { _, _ in
                    loadComparison()
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Total Comparison
    private func totalComparisonSection(_ comparison: MonthComparison) -> some View {
        HStack(spacing: 20) {
            // Month 1 Total
            totalCard(
                title: formatMonth(comparison.month1),
                amount: comparison.month1Total,
                color: .blue
            )

            // VS divider
            VStack {
                Text("vs")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }

            // Month 2 Total
            totalCard(
                title: formatMonth(comparison.month2),
                amount: comparison.month2Total,
                color: .purple
            )

            // Change Badge
            changeBadge(comparison)
        }
    }

    private func totalCard(title: String, amount: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(formatCurrency(amount))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    private func changeBadge(_ comparison: MonthComparison) -> some View {
        let isIncrease = comparison.totalDifference >= 0
        let color: Color = isIncrease ? .red : .green
        let icon = isIncrease ? "arrow.up.right" : "arrow.down.right"

        return VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
            Text(String(format: "%.1f%%", abs(comparison.totalPercentageChange)))
                .font(.headline)
            Text(formatCurrency(abs(comparison.totalDifference)))
                .font(.caption)
        }
        .foregroundColor(color)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Chart Section
    private func chartSection(_ comparison: MonthComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Kategori Karşılaştırması")
                .font(.headline)

            Chart {
                ForEach(comparison.categoryComparisons.prefix(8)) { item in
                    BarMark(
                        x: .value("Kategori", item.category),
                        y: .value("Tutar", item.month1Amount)
                    )
                    .foregroundStyle(.blue)
                    .position(by: .value("Ay", formatMonth(comparison.month1)))

                    BarMark(
                        x: .value("Kategori", item.category),
                        y: .value("Tutar", item.month2Amount)
                    )
                    .foregroundStyle(.purple)
                    .position(by: .value("Ay", formatMonth(comparison.month2)))
                }
            }
            .chartForegroundStyleScale([
                formatMonth(comparison.month1): .blue,
                formatMonth(comparison.month2): .purple
            ])
            .frame(height: 250)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    // MARK: - Category Table
    private func categoryTableSection(_ comparison: MonthComparison) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detaylı Karşılaştırma")
                .font(.headline)

            // Header
            HStack {
                Text("Kategori")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(formatMonth(comparison.month1))
                    .frame(width: 100, alignment: .trailing)
                Text(formatMonth(comparison.month2))
                    .frame(width: 100, alignment: .trailing)
                Text("Fark")
                    .frame(width: 100, alignment: .trailing)
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 8)

            Divider()

            // Rows
            ForEach(comparison.categoryComparisons) { item in
                categoryRow(item, comparison: comparison)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(12)
    }

    private func categoryRow(_ item: CategoryComparison, comparison: MonthComparison) -> some View {
        HStack {
            HStack(spacing: 8) {
                let categoryInfo = Category.defaults.first { $0.name == item.category }
                Image(systemName: categoryInfo?.icon ?? "circle.fill")
                    .foregroundColor(Color(hex: categoryInfo?.color ?? "#6b7280"))
                Text(item.category)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(formatCurrency(item.month1Amount))
                .frame(width: 100, alignment: .trailing)
                .foregroundColor(.blue)

            Text(formatCurrency(item.month2Amount))
                .frame(width: 100, alignment: .trailing)
                .foregroundColor(.purple)

            HStack(spacing: 4) {
                let isIncrease = item.difference >= 0
                Image(systemName: isIncrease ? "arrow.up" : "arrow.down")
                    .font(.caption)
                Text(String(format: "%.0f%%", abs(item.percentageChange)))
            }
            .frame(width: 100, alignment: .trailing)
            .foregroundColor(item.difference >= 0 ? .red : .green)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Top Changes
    private func topChangesSection(_ comparison: MonthComparison) -> some View {
        HStack(spacing: 20) {
            // Top Increases
            VStack(alignment: .leading, spacing: 12) {
                Label("En Çok Artan", systemImage: "arrow.up.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)

                let increases = comparison.categoryComparisons
                    .filter { $0.difference > 0 }
                    .sorted { $0.difference > $1.difference }
                    .prefix(3)

                if increases.isEmpty {
                    Text("Artış yok")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(Array(increases)) { item in
                        changeItemRow(item, isIncrease: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(12)

            // Top Decreases
            VStack(alignment: .leading, spacing: 12) {
                Label("En Çok Azalan", systemImage: "arrow.down.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)

                let decreases = comparison.categoryComparisons
                    .filter { $0.difference < 0 }
                    .sorted { $0.difference < $1.difference }
                    .prefix(3)

                if decreases.isEmpty {
                    Text("Azalış yok")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    ForEach(Array(decreases)) { item in
                        changeItemRow(item, isIncrease: false)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.green.opacity(0.05))
            .cornerRadius(12)
        }
    }

    private func changeItemRow(_ item: CategoryComparison, isIncrease: Bool) -> some View {
        HStack {
            let categoryInfo = Category.defaults.first { $0.name == item.category }
            Image(systemName: categoryInfo?.icon ?? "circle.fill")
                .foregroundColor(Color(hex: categoryInfo?.color ?? "#6b7280"))
            Text(item.category)
            Spacer()
            Text(formatCurrency(abs(item.difference)))
                .fontWeight(.medium)
            Text(String(format: "(%.0f%%)", abs(item.percentageChange)))
                .foregroundColor(.secondary)
                .font(.caption)
        }
    }

    // MARK: - Helper Functions
    private func loadAvailableMonths() {
        availableMonths = database.getAvailableMonths()
        if availableMonths.count >= 2 {
            month2 = availableMonths[0]
            month1 = availableMonths[1]
        } else if availableMonths.count == 1 {
            month1 = availableMonths[0]
            month2 = availableMonths[0]
        }
    }

    private func loadComparison() {
        comparison = database.getMonthlyComparison(month1: month1, month2: month2)
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: date)
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.currencySymbol = "₺"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }
}

#Preview {
    ComparisonView()
}
