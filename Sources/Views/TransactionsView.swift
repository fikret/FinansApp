import SwiftUI
import UniformTypeIdentifiers

enum TransactionSortOption: String, CaseIterable {
    case date = "Tarih"
    case name = "İsim"
    case amount = "Tutar"

    var icon: String {
        switch self {
        case .date: return "calendar"
        case .name: return "textformat"
        case .amount: return "turkishlirasign"
        }
    }
}

struct TransactionsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingExport = false
    @State private var transactionForCategoryEdit: Transaction?
    @State private var showingNewCategory = false
    @State private var isSelectionMode = false
    @State private var selectedTransactionIds: Set<String> = []
    @State private var showingBulkCategoryPicker = false
    @State private var sortOption: TransactionSortOption = .date
    @State private var sortAscending = false
    @State private var transactionToDelete: Transaction?
    @State private var showDeleteAlert = false
    @State private var showBulkDeleteAlert = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with filters
            HStack {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("İşlem ara...", text: $appState.searchQuery)
                        .textFieldStyle(.plain)
                        .onChange(of: appState.searchQuery) { _, newValue in
                            appState.searchTransactions(newValue)
                        }
                }
                .padding(8)
                .background(.background.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: 250)

                // Card Filter
                Menu {
                    Button("Tüm Kartlar") {
                        appState.filterByCard(nil)
                    }
                    Divider()
                    ForEach(appState.cards) { card in
                        Button {
                            appState.filterByCard(card.id)
                        } label: {
                            Label(card.name, systemImage: "creditcard")
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "creditcard")
                        Text(selectedCardName)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Category Filter
                Menu {
                    Button("Tüm Kategoriler") {
                        appState.filterTransactions(category: nil)
                    }
                    Divider()
                    ForEach(appState.categories) { category in
                        Button {
                            appState.filterTransactions(category: category.name)
                        } label: {
                            Label(category.name, systemImage: category.icon)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(appState.selectedCategory ?? "Kategori")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Sort Menu
                Menu {
                    ForEach(TransactionSortOption.allCases, id: \.self) { option in
                        Button {
                            if sortOption == option {
                                sortAscending.toggle()
                            } else {
                                sortOption = option
                                sortAscending = false
                            }
                        } label: {
                            HStack {
                                Label(option.rawValue, systemImage: option.icon)
                                if sortOption == option {
                                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                        Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.background.secondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Spacer()

                // Selection Mode Toggle
                Button {
                    isSelectionMode.toggle()
                    if !isSelectionMode {
                        selectedTransactionIds.removeAll()
                    }
                } label: {
                    Label(isSelectionMode ? "İptal" : "Seç", systemImage: isSelectionMode ? "xmark" : "checkmark.circle")
                }
                .buttonStyle(.bordered)

                // Export Button
                Button {
                    exportCSV()
                } label: {
                    Label("CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            .padding()

            // Filter Pills
            if appState.selectedCategory != nil || appState.selectedCardId != nil {
                HStack {
                    Text("Filtre:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let cardId = appState.selectedCardId,
                       let card = appState.cards.first(where: { $0.id == cardId }) {
                        Button {
                            appState.filterByCard(nil)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "creditcard")
                                Text(card.name)
                                Image(systemName: "xmark.circle.fill")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.purple.opacity(0.1))
                            .foregroundStyle(.purple)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if let category = appState.selectedCategory {
                        Button {
                            appState.filterTransactions(category: nil)
                        } label: {
                            HStack(spacing: 4) {
                                Text(category)
                                Image(systemName: "xmark.circle.fill")
                            }
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }

            Divider()

            // Summary with Select All
            HStack(spacing: 12) {
                // Select All Checkbox (only in selection mode)
                if isSelectionMode {
                    Button {
                        if allSelected {
                            selectedTransactionIds.removeAll()
                        } else {
                            selectedTransactionIds = Set(appState.transactions.map { $0.id })
                        }
                    } label: {
                        Image(systemName: allSelected ? "checkmark.square.fill" : (selectedTransactionIds.isEmpty ? "square" : "minus.square.fill"))
                            .font(.title3)
                            .foregroundColor(selectedTransactionIds.isEmpty ? .secondary : .accentColor)
                    }
                    .buttonStyle(.plain)
                    .help(allSelected ? "Seçimi Kaldır" : "Tümünü Seç")
                }

                Text("\(appState.transactions.count) işlem")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if isSelectionMode && !selectedTransactionIds.isEmpty {
                    Text("(\(selectedTransactionIds.count) seçili)")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .fontWeight(.medium)
                }

                Spacer()

                if isSelectionMode && !selectedTransactionIds.isEmpty {
                    Button {
                        showingBulkCategoryPicker = true
                    } label: {
                        Label("Kategori Değiştir", systemImage: "tag")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button(role: .destructive) {
                        showBulkDeleteAlert = true
                    } label: {
                        Label("Sil", systemImage: "trash")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Text("Toplam: \(formatCurrency(totalAmount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding()
            .background(.background.secondary)

            // Transactions List
            if appState.transactions.isEmpty {
                let hasFilters = !appState.searchQuery.isEmpty || appState.selectedCategory != nil || appState.selectedCardId != nil
                ContentUnavailableView(
                    hasFilters ? "Sonuç Bulunamadı" : "İşlem Yok",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(hasFilters ?
                                       "Filtreye uygun işlem bulunamadı" :
                                       "Henüz işlem kaydı yok")
                )
            } else {
                List(sortedTransactions) { transaction in
                    HStack(spacing: 12) {
                        // Checkbox for selection mode
                        if isSelectionMode {
                            Button {
                                if selectedTransactionIds.contains(transaction.id) {
                                    selectedTransactionIds.remove(transaction.id)
                                } else {
                                    selectedTransactionIds.insert(transaction.id)
                                }
                            } label: {
                                Image(systemName: selectedTransactionIds.contains(transaction.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title2)
                                    .foregroundColor(selectedTransactionIds.contains(transaction.id) ? .accentColor : .secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        TransactionDetailRow(
                            transaction: transaction,
                            cardName: appState.getCardName(for: transaction),
                            categories: appState.categories,
                            onCategoryTap: {
                                if isSelectionMode {
                                    // In selection mode, toggle selection
                                    if selectedTransactionIds.contains(transaction.id) {
                                        selectedTransactionIds.remove(transaction.id)
                                    } else {
                                        selectedTransactionIds.insert(transaction.id)
                                    }
                                } else {
                                    transactionForCategoryEdit = transaction
                                }
                            }
                        )
                    }
                    .contextMenu {
                        Button {
                            transactionForCategoryEdit = transaction
                        } label: {
                            Label("Kategori Değiştir", systemImage: "tag")
                        }

                        Divider()

                        Button(role: .destructive) {
                            transactionToDelete = transaction
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            transactionToDelete = transaction
                            showDeleteAlert = true
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("İşlemler")
        .sheet(item: $transactionForCategoryEdit) { transaction in
            CategoryPickerSheet(
                transaction: transaction,
                categories: appState.categories,
                onSelect: { category in
                    appState.updateTransactionCategory(transactionId: transaction.id, category: category)
                    transactionForCategoryEdit = nil
                },
                onAddNew: {
                    transactionForCategoryEdit = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingNewCategory = true
                    }
                }
            )
        }
        .sheet(isPresented: $showingNewCategory) {
            NewCategorySheet { name, icon, color in
                appState.addCategory(name: name, icon: icon, color: color)
                showingNewCategory = false
            }
        }
        .sheet(isPresented: $showingBulkCategoryPicker) {
            BulkCategoryPickerSheet(
                selectedCount: selectedTransactionIds.count,
                categories: appState.categories,
                onSelect: { category in
                    appState.updateTransactionsCategoryBulk(transactionIds: selectedTransactionIds, category: category)
                    selectedTransactionIds.removeAll()
                    isSelectionMode = false
                    showingBulkCategoryPicker = false
                },
                onAddNew: {
                    showingBulkCategoryPicker = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingNewCategory = true
                    }
                }
            )
        }
        .alert("İşlemi Sil", isPresented: $showDeleteAlert) {
            Button("İptal", role: .cancel) {
                transactionToDelete = nil
            }
            Button("Sil", role: .destructive) {
                if let transaction = transactionToDelete {
                    appState.deleteTransaction(transaction.id)
                    transactionToDelete = nil
                }
            }
        } message: {
            if let transaction = transactionToDelete {
                Text("\"\(transaction.merchant ?? transaction.description)\" işlemi silinecek. Bu işlem geri alınamaz.")
            }
        }
        .alert("Seçili İşlemleri Sil", isPresented: $showBulkDeleteAlert) {
            Button("İptal", role: .cancel) { }
            Button("Sil", role: .destructive) {
                appState.deleteTransactionsBulk(transactionIds: selectedTransactionIds)
                selectedTransactionIds.removeAll()
                isSelectionMode = false
            }
        } message: {
            Text("\(selectedTransactionIds.count) işlem silinecek. Bu işlem geri alınamaz.")
        }
    }

    private var totalAmount: Double {
        appState.transactions.reduce(0) { $0 + $1.amount }
    }

    private var sortedTransactions: [Transaction] {
        let transactions = appState.transactions
        switch sortOption {
        case .date:
            return transactions.sorted { sortAscending ? $0.date < $1.date : $0.date > $1.date }
        case .name:
            return transactions.sorted {
                let name0 = $0.merchant ?? $0.description
                let name1 = $1.merchant ?? $1.description
                return sortAscending ? name0.localizedCompare(name1) == .orderedAscending : name0.localizedCompare(name1) == .orderedDescending
            }
        case .amount:
            return transactions.sorted { sortAscending ? $0.amount < $1.amount : $0.amount > $1.amount }
        }
    }

    private var allSelected: Bool {
        !appState.transactions.isEmpty && selectedTransactionIds.count == appState.transactions.count
    }

    private var selectedCardName: String {
        if let cardId = appState.selectedCardId,
           let card = appState.cards.first(where: { $0.id == cardId }) {
            return card.name
        }
        return "Tüm Kartlar"
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }

    private func exportCSV() {
        let csv = appState.exportTransactionsCSV()

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        savePanel.nameFieldStringValue = "islemler-\(Date().ISO8601Format(.iso8601Date(timeZone: .current))).csv"

        savePanel.begin { result in
            if result == .OK, let url = savePanel.url {
                try? csv.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

struct TransactionDetailRow: View {
    let transaction: Transaction
    let cardName: String?
    let categories: [Category]
    let onCategoryTap: () -> Void

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MMMM yyyy"
        df.locale = Locale(identifier: "tr_TR")
        return df
    }()

    var body: some View {
        HStack(spacing: 12) {
            // Category Color Bar
            RoundedRectangle(cornerRadius: 2)
                .fill(categoryColor)
                .frame(width: 4, height: 50)

            // Main Info
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchant ?? transaction.description)
                    .fontWeight(.medium)

                HStack {
                    Text(dateFormatter.string(from: transaction.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let cardName = cardName {
                        Text("•")
                            .foregroundStyle(.secondary)
                        HStack(spacing: 2) {
                            Image(systemName: "creditcard")
                                .font(.caption2)
                            Text(cardName)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if transaction.merchant != nil && transaction.description != transaction.merchant {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(transaction.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Category Badge (Clickable)
            Button(action: onCategoryTap) {
                HStack(spacing: 4) {
                    if let category = transaction.category {
                        let cat = categories.first { $0.name == category }
                        Image(systemName: cat?.icon ?? "tag")
                            .font(.caption)
                        Text(category)
                            .font(.caption)
                    } else {
                        Image(systemName: "tag")
                            .font(.caption)
                        Text("Kategori Seç")
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(categoryColor.opacity(0.1))
                .foregroundStyle(categoryColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            // Amount
            Text(formatCurrency(transaction.amount))
                .font(.headline)
                .monospacedDigit()
                .frame(width: 100, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        let colorHex = categories.first { $0.name == transaction.category }?.color ?? "#6b7280"
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

// MARK: - Category Picker Sheet
struct CategoryPickerSheet: View {
    let transaction: Transaction
    let categories: [Category]
    let onSelect: (String?) -> Void
    let onAddNew: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Kategori Seç")
                    .font(.headline)
                Spacer()
                Button("İptal") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Transaction Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.merchant ?? transaction.description)
                        .fontWeight(.medium)
                    Text(formatCurrency(transaction.amount))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))

            Divider()

            // Categories List
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                    // No Category Option
                    CategoryButton(
                        name: "Kategorisiz",
                        icon: "xmark.circle",
                        color: "#6b7280",
                        isSelected: transaction.category == nil
                    ) {
                        onSelect(nil)
                    }

                    // All Categories
                    ForEach(categories) { category in
                        CategoryButton(
                            name: category.name,
                            icon: category.icon,
                            color: category.color,
                            isSelected: transaction.category == category.name
                        ) {
                            onSelect(category.name)
                        }
                    }

                    // Add New Category
                    Button(action: onAddNew) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text("Yeni Kategori")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 450)
        .background(Color(.windowBackgroundColor))
    }

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "TRY"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: NSNumber(value: amount)) ?? "₺0"
    }
}

struct CategoryButton: View {
    let name: String
    let icon: String
    let color: String
    let isSelected: Bool
    let action: () -> Void

    private var buttonColor: Color {
        Color(hex: color)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(buttonColor)
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? buttonColor.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? buttonColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - New Category Sheet
struct NewCategorySheet: View {
    let onSave: (String, String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedIcon = "tag"
    @State private var selectedColor = "#3b82f6"

    private var currentColor: Color {
        Color(hex: selectedColor)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("İptal") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                Spacer()
                Text("Yeni Kategori")
                    .font(.headline)
                Spacer()
                Button("Kaydet") {
                    if !name.isEmpty {
                        onSave(name, selectedIcon, selectedColor)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Preview
                    VStack(spacing: 8) {
                        Image(systemName: selectedIcon)
                            .font(.largeTitle)
                            .foregroundColor(currentColor)
                        Text(name.isEmpty ? "Kategori Adı" : name)
                            .font(.headline)
                    }
                    .padding()
                    .frame(width: 150)
                    .background(currentColor.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.top)

                    // Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Kategori Adı")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Örn: Kahve", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding(.horizontal)

                    // Icon
                    VStack(alignment: .leading, spacing: 8) {
                        Text("İkon")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                            ForEach(Category.defaultIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .foregroundColor(selectedIcon == icon ? currentColor : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedIcon == icon ? currentColor.opacity(0.2) : Color.gray.opacity(0.1))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedIcon == icon ? currentColor : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Color
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Renk")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 8) {
                            ForEach(Category.defaultColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(Color(hex: color))
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                                .padding(2)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
        }
        .frame(width: 400, height: 500)
        .background(Color(.windowBackgroundColor))
    }
}

// MARK: - Bulk Category Picker Sheet
struct BulkCategoryPickerSheet: View {
    let selectedCount: Int
    let categories: [Category]
    let onSelect: (String?) -> Void
    let onAddNew: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Toplu Kategori Değiştir")
                    .font(.headline)
                Spacer()
                Button("İptal") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            // Info
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.accentColor)
                Text("\(selectedCount) işlem seçildi. Yeni kategori seçin.")
                    .font(.subheadline)
                Spacer()
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))

            Divider()

            // Categories List
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                    // No Category Option
                    CategoryButton(
                        name: "Kategorisiz",
                        icon: "xmark.circle",
                        color: "#6b7280",
                        isSelected: false
                    ) {
                        onSelect(nil)
                    }

                    // All Categories
                    ForEach(categories) { category in
                        CategoryButton(
                            name: category.name,
                            icon: category.icon,
                            color: category.color,
                            isSelected: false
                        ) {
                            onSelect(category.name)
                        }
                    }

                    // Add New Category
                    Button(action: onAddNew) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.accentColor)
                            Text("Yeni Kategori")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundColor(.secondary.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 450)
        .background(Color(.windowBackgroundColor))
    }
}

#Preview {
    TransactionsView()
        .environmentObject(AppState())
}
