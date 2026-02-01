import Foundation
import SQLite3

class DatabaseService {
    static let shared = DatabaseService()
    private var db: OpaquePointer?

    private init() {
        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    // MARK: - Database Setup
    private func openDatabase() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("FinansApp", isDirectory: true)

        try? fileManager.createDirectory(at: appFolder, withIntermediateDirectories: true)

        let dbPath = appFolder.appendingPathComponent("finans.db").path

        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("Error opening database")
        }
    }

    private func createTables() {
        let createCardsTable = """
            CREATE TABLE IF NOT EXISTS cards (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                bank TEXT,
                last_four TEXT,
                created_at REAL
            );
        """

        let createStatementsTable = """
            CREATE TABLE IF NOT EXISTS statements (
                id TEXT PRIMARY KEY,
                card_id TEXT REFERENCES cards(id),
                period_start REAL,
                period_end REAL,
                total_amount REAL,
                min_payment REAL,
                due_date REAL,
                pdf_path TEXT,
                raw_json TEXT,
                created_at REAL
            );
        """

        let createTransactionsTable = """
            CREATE TABLE IF NOT EXISTS transactions (
                id TEXT PRIMARY KEY,
                statement_id TEXT REFERENCES statements(id),
                date REAL,
                description TEXT,
                merchant TEXT,
                amount REAL,
                currency TEXT DEFAULT 'TRY',
                category TEXT,
                created_at REAL
            );
        """

        let createCategoriesTable = """
            CREATE TABLE IF NOT EXISTS categories (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                icon TEXT NOT NULL,
                color TEXT NOT NULL,
                is_custom INTEGER DEFAULT 1,
                created_at REAL
            );
        """

        execute(createCardsTable)
        execute(createStatementsTable)
        execute(createTransactionsTable)
        execute(createCategoriesTable)
    }

    private func execute(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Card Operations
    func getCards() -> [Card] {
        var cards: [Card] = []
        let query = "SELECT id, name, bank, last_four, created_at FROM cards ORDER BY created_at DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let bank = sqlite3_column_text(statement, 2).map { String(cString: $0) }
                let lastFour = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))

                cards.append(Card(id: id, name: name, bank: bank, lastFour: lastFour, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)
        return cards
    }

    func createCard(_ card: Card) {
        let query = "INSERT INTO cards (id, name, bank, last_four, created_at) VALUES (?, ?, ?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (card.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (card.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if let bank = card.bank {
                sqlite3_bind_text(statement, 3, (bank as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            if let lastFour = card.lastFour {
                sqlite3_bind_text(statement, 4, (lastFour as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 4)
            }
            sqlite3_bind_double(statement, 5, card.createdAt.timeIntervalSince1970)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func updateCard(_ card: Card) {
        let query = "UPDATE cards SET name = ?, bank = ?, last_four = ? WHERE id = ?"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (card.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if let bank = card.bank {
                sqlite3_bind_text(statement, 2, (bank as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 2)
            }
            if let lastFour = card.lastFour {
                sqlite3_bind_text(statement, 3, (lastFour as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 3)
            }
            sqlite3_bind_text(statement, 4, (card.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func deleteCard(_ id: String) {
        // Delete related transactions first
        execute("DELETE FROM transactions WHERE statement_id IN (SELECT id FROM statements WHERE card_id = '\(id)')")
        // Delete related statements
        execute("DELETE FROM statements WHERE card_id = '\(id)'")
        // Delete the card
        execute("DELETE FROM cards WHERE id = '\(id)'")
    }

    func findCardByLastFour(_ lastFour: String) -> Card? {
        let query = "SELECT id, name, bank, last_four, created_at FROM cards WHERE last_four = ?"
        var statement: OpaquePointer?
        var card: Card?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
            sqlite3_bind_text(statement, 1, (lastFour as NSString).utf8String, -1, SQLITE_TRANSIENT)

            if sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let bank = sqlite3_column_text(statement, 2).map { String(cString: $0) }
                let lastFour = sqlite3_column_text(statement, 3).map { String(cString: $0) }
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 4))
                card = Card(id: id, name: name, bank: bank, lastFour: lastFour, createdAt: createdAt)
            }
        }
        sqlite3_finalize(statement)
        return card
    }

    // MARK: - Statement Operations
    func getStatements(cardId: String? = nil) -> [Statement] {
        var statements: [Statement] = []
        var query = "SELECT id, card_id, period_start, period_end, total_amount, min_payment, due_date, pdf_path, raw_json, created_at FROM statements"
        if let cardId = cardId {
            query += " WHERE card_id = '\(cardId)'"
        }
        query += " ORDER BY created_at DESC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let cardId = String(cString: sqlite3_column_text(statement, 1))
                let periodStart = sqlite3_column_type(statement, 2) != SQLITE_NULL ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 2)) : nil
                let periodEnd = sqlite3_column_type(statement, 3) != SQLITE_NULL ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 3)) : nil
                let totalAmount = sqlite3_column_type(statement, 4) != SQLITE_NULL ? sqlite3_column_double(statement, 4) : nil
                let minPayment = sqlite3_column_type(statement, 5) != SQLITE_NULL ? sqlite3_column_double(statement, 5) : nil
                let dueDate = sqlite3_column_type(statement, 6) != SQLITE_NULL ? Date(timeIntervalSince1970: sqlite3_column_double(statement, 6)) : nil
                let pdfPath = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let rawJson = sqlite3_column_text(statement, 8).map { String(cString: $0) }
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 9))

                statements.append(Statement(id: id, cardId: cardId, periodStart: periodStart, periodEnd: periodEnd, totalAmount: totalAmount, minPayment: minPayment, dueDate: dueDate, pdfPath: pdfPath, rawJson: rawJson, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)
        return statements
    }

    func deleteStatement(_ id: String) {
        // Önce ilgili işlemleri sil
        execute("DELETE FROM transactions WHERE statement_id = '\(id)'")
        // Sonra ekstreyi sil
        execute("DELETE FROM statements WHERE id = '\(id)'")
    }

    func createStatement(_ stmt: Statement) {
        let query = "INSERT INTO statements (id, card_id, period_start, period_end, total_amount, min_payment, due_date, pdf_path, raw_json, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (stmt.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (stmt.cardId as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if let ps = stmt.periodStart { sqlite3_bind_double(statement, 3, ps.timeIntervalSince1970) } else { sqlite3_bind_null(statement, 3) }
            if let pe = stmt.periodEnd { sqlite3_bind_double(statement, 4, pe.timeIntervalSince1970) } else { sqlite3_bind_null(statement, 4) }
            if let ta = stmt.totalAmount { sqlite3_bind_double(statement, 5, ta) } else { sqlite3_bind_null(statement, 5) }
            if let mp = stmt.minPayment { sqlite3_bind_double(statement, 6, mp) } else { sqlite3_bind_null(statement, 6) }
            if let dd = stmt.dueDate { sqlite3_bind_double(statement, 7, dd.timeIntervalSince1970) } else { sqlite3_bind_null(statement, 7) }
            if let pp = stmt.pdfPath { sqlite3_bind_text(statement, 8, (pp as NSString).utf8String, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(statement, 8) }
            if let rj = stmt.rawJson { sqlite3_bind_text(statement, 9, (rj as NSString).utf8String, -1, SQLITE_TRANSIENT) } else { sqlite3_bind_null(statement, 9) }
            sqlite3_bind_double(statement, 10, stmt.createdAt.timeIntervalSince1970)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    // MARK: - Transaction Operations
    func getTransactions(statementId: String? = nil, cardId: String? = nil, category: String? = nil, searchQuery: String? = nil) -> [Transaction] {
        var transactions: [Transaction] = []
        var query = "SELECT t.id, t.statement_id, t.date, t.description, t.merchant, t.amount, t.currency, t.category, t.created_at FROM transactions t"

        if cardId != nil {
            query += " INNER JOIN statements s ON t.statement_id = s.id"
        }
        query += " WHERE 1=1"

        if let statementId = statementId {
            query += " AND t.statement_id = '\(statementId)'"
        }
        if let cardId = cardId {
            query += " AND s.card_id = '\(cardId)'"
        }
        if let category = category {
            query += " AND t.category = '\(category)'"
        }
        if let search = searchQuery, !search.isEmpty {
            query += " AND (t.description LIKE '%\(search)%' OR t.merchant LIKE '%\(search)%')"
        }
        query += " ORDER BY t.date DESC"

        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let statementId = String(cString: sqlite3_column_text(statement, 1))
                let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
                let description = String(cString: sqlite3_column_text(statement, 3))
                let merchant = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let amount = sqlite3_column_double(statement, 5)
                let currency = String(cString: sqlite3_column_text(statement, 6))
                let category = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))

                transactions.append(Transaction(id: id, statementId: statementId, date: date, description: description, merchant: merchant, amount: amount, currency: currency, category: category, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)
        return transactions
    }

    func getTransactionCount(for statementId: String) -> Int {
        let query = "SELECT COUNT(*) FROM transactions WHERE statement_id = ?"
        var statement: OpaquePointer?
        var count = 0
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (statementId as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if sqlite3_step(statement) == SQLITE_ROW {
                count = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)
        return count
    }

    func createTransactions(_ transactions: [Transaction]) {
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        for txn in transactions {
            let query = "INSERT INTO transactions (id, statement_id, date, description, merchant, amount, currency, category, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
            var statement: OpaquePointer?

            if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_text(statement, 1, (txn.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_text(statement, 2, (txn.statementId as NSString).utf8String, -1, SQLITE_TRANSIENT)
                sqlite3_bind_double(statement, 3, txn.date.timeIntervalSince1970)
                sqlite3_bind_text(statement, 4, (txn.description as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if let m = txn.merchant {
                    sqlite3_bind_text(statement, 5, (m as NSString).utf8String, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 5)
                }
                sqlite3_bind_double(statement, 6, txn.amount)
                sqlite3_bind_text(statement, 7, (txn.currency as NSString).utf8String, -1, SQLITE_TRANSIENT)
                if let c = txn.category {
                    sqlite3_bind_text(statement, 8, (c as NSString).utf8String, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(statement, 8)
                }
                sqlite3_bind_double(statement, 9, txn.createdAt.timeIntervalSince1970)
                sqlite3_step(statement)
            }
            sqlite3_finalize(statement)
        }
    }

    // MARK: - Category Operations
    func getCategories() -> [Category] {
        var categories = Category.defaults
        let query = "SELECT id, name, icon, color FROM categories ORDER BY name"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                let icon = String(cString: sqlite3_column_text(statement, 2))
                let color = String(cString: sqlite3_column_text(statement, 3))

                categories.append(Category(id: id, name: name, icon: icon, color: color, isCustom: true))
            }
        }
        sqlite3_finalize(statement)
        return categories
    }

    func createCategory(_ category: Category) {
        let query = "INSERT INTO categories (id, name, icon, color, is_custom, created_at) VALUES (?, ?, ?, ?, 1, ?)"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (category.id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 2, (category.name as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 3, (category.icon as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(statement, 4, (category.color as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_double(statement, 5, Date().timeIntervalSince1970)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func deleteCategory(_ id: String) {
        execute("DELETE FROM categories WHERE id = '\(id)'")
    }

    func updateTransactionCategory(transactionId: String, category: String?) {
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        let query = "UPDATE transactions SET category = ? WHERE id = ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if let category = category {
                sqlite3_bind_text(statement, 1, (category as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 1)
            }
            sqlite3_bind_text(statement, 2, (transactionId as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func updateTransactionsCategoryBulk(transactionIds: [String], category: String?) {
        guard !transactionIds.isEmpty else { return }

        let placeholders = transactionIds.map { _ in "?" }.joined(separator: ", ")
        let query = "UPDATE transactions SET category = ? WHERE id IN (\(placeholders))"
        var statement: OpaquePointer?
        let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if let category = category {
                sqlite3_bind_text(statement, 1, (category as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(statement, 1)
            }

            for (index, id) in transactionIds.enumerated() {
                sqlite3_bind_text(statement, Int32(index + 2), (id as NSString).utf8String, -1, SQLITE_TRANSIENT)
            }

            sqlite3_step(statement)
        }
        sqlite3_finalize(statement)
    }

    func deleteTransaction(_ transactionId: String) {
        execute("DELETE FROM transactions WHERE id = '\(transactionId)'")
    }

    func deleteTransactionsBulk(transactionIds: [String]) {
        guard !transactionIds.isEmpty else { return }
        let ids = transactionIds.map { "'\($0)'" }.joined(separator: ", ")
        execute("DELETE FROM transactions WHERE id IN (\(ids))")
    }

    // MARK: - Clear All Data
    func clearAllData() {
        execute("DELETE FROM transactions")
        execute("DELETE FROM statements")
        execute("DELETE FROM cards")
        execute("DELETE FROM categories")
    }

    // MARK: - Month Comparison
    func getMonthlyComparison(month1: Date, month2: Date) -> MonthComparison {
        let calendar = Calendar.current

        // Get start and end of month1
        let month1Start = calendar.date(from: calendar.dateComponents([.year, .month], from: month1))!
        let month1End = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: month1Start)!

        // Get start and end of month2
        let month2Start = calendar.date(from: calendar.dateComponents([.year, .month], from: month2))!
        let month2End = calendar.date(byAdding: DateComponents(month: 1, second: -1), to: month2Start)!

        // Get totals for each month
        let month1Total = getMonthTotal(from: month1Start, to: month1End)
        let month2Total = getMonthTotal(from: month2Start, to: month2End)

        // Get category breakdown for each month
        let month1Categories = getCategoryBreakdown(from: month1Start, to: month1End)
        let month2Categories = getCategoryBreakdown(from: month2Start, to: month2End)

        // Merge categories from both months
        let allCategories = Set(month1Categories.keys).union(month2Categories.keys)

        var categoryComparisons: [CategoryComparison] = []
        for category in allCategories {
            let m1Amount = month1Categories[category] ?? 0
            let m2Amount = month2Categories[category] ?? 0
            categoryComparisons.append(CategoryComparison(
                category: category,
                month1Amount: m1Amount,
                month2Amount: m2Amount
            ))
        }

        // Sort by absolute difference (largest changes first)
        categoryComparisons.sort { abs($0.difference) > abs($1.difference) }

        return MonthComparison(
            month1: month1,
            month2: month2,
            month1Total: month1Total,
            month2Total: month2Total,
            categoryComparisons: categoryComparisons
        )
    }

    private func getMonthTotal(from startDate: Date, to endDate: Date) -> Double {
        var total: Double = 0
        let query = "SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE date >= ? AND date <= ?"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            if sqlite3_step(statement) == SQLITE_ROW {
                total = sqlite3_column_double(statement, 0)
            }
        }
        sqlite3_finalize(statement)
        return total
    }

    private func getCategoryBreakdown(from startDate: Date, to endDate: Date) -> [String: Double] {
        var breakdown: [String: Double] = [:]
        let query = "SELECT COALESCE(category, 'Diğer'), SUM(amount) FROM transactions WHERE date >= ? AND date <= ? GROUP BY category"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            while sqlite3_step(statement) == SQLITE_ROW {
                let category = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? "Diğer"
                let amount = sqlite3_column_double(statement, 1)
                breakdown[category] = amount
            }
        }
        sqlite3_finalize(statement)
        return breakdown
    }

    func getAvailableMonths() -> [Date] {
        var months: [Date] = []
        let calendar = Calendar.current
        let query = "SELECT DISTINCT strftime('%Y-%m', date, 'unixepoch') as month FROM transactions ORDER BY month DESC"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                if let monthStr = sqlite3_column_text(statement, 0).map({ String(cString: $0) }) {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM"
                    if let date = formatter.date(from: monthStr) {
                        months.append(date)
                    }
                }
            }
        }
        sqlite3_finalize(statement)

        // If no months found, return last 12 months
        if months.isEmpty {
            for i in 0..<12 {
                if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
                    months.append(monthStart)
                }
            }
        }

        return months
    }

    // MARK: - Dashboard Stats
    func getDashboardStats(from startDate: Date, to endDate: Date) -> DashboardStats {
        let calendar = Calendar.current

        // Total spending
        var totalSpending: Double = 0
        let totalQuery = "SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE date >= ? AND date <= ?"
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, totalQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            if sqlite3_step(statement) == SQLITE_ROW {
                totalSpending = sqlite3_column_double(statement, 0)
            }
        }
        sqlite3_finalize(statement)

        // Category breakdown
        var categoryBreakdown: [CategoryBreakdown] = []
        let categoryQuery = "SELECT category, SUM(amount) as total FROM transactions WHERE date >= ? AND date <= ? GROUP BY category ORDER BY total DESC"
        if sqlite3_prepare_v2(db, categoryQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            while sqlite3_step(statement) == SQLITE_ROW {
                let category = sqlite3_column_text(statement, 0).map { String(cString: $0) } ?? "Diğer"
                let amount = sqlite3_column_double(statement, 1)
                let percentage = totalSpending > 0 ? (amount / totalSpending) * 100 : 0
                let color = Category.defaults.first { $0.name == category }?.color ?? "#6b7280"
                categoryBreakdown.append(CategoryBreakdown(category: category, amount: amount, percentage: percentage, color: color))
            }
        }
        sqlite3_finalize(statement)

        // Monthly comparison (last 6 months from end date)
        var monthlyComparison: [MonthlyData] = []
        let monthNames = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"]
        for i in (0..<6).reversed() {
            let targetMonth = calendar.date(byAdding: .month, value: -i, to: endDate)!
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: targetMonth))!
            let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart)!

            var monthTotal: Double = 0
            let monthQuery = "SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE date >= ? AND date <= ?"
            if sqlite3_prepare_v2(db, monthQuery, -1, &statement, nil) == SQLITE_OK {
                sqlite3_bind_double(statement, 1, monthStart.timeIntervalSince1970)
                sqlite3_bind_double(statement, 2, monthEnd.timeIntervalSince1970)
                if sqlite3_step(statement) == SQLITE_ROW {
                    monthTotal = sqlite3_column_double(statement, 0)
                }
            }
            sqlite3_finalize(statement)

            let monthIndex = calendar.component(.month, from: targetMonth) - 1
            monthlyComparison.append(MonthlyData(month: monthNames[monthIndex], amount: monthTotal))
        }

        // Transaction count for selected period
        var transactionCount = 0
        let countQuery = "SELECT COUNT(*) FROM transactions WHERE date >= ? AND date <= ?"
        if sqlite3_prepare_v2(db, countQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            if sqlite3_step(statement) == SQLITE_ROW {
                transactionCount = Int(sqlite3_column_int(statement, 0))
            }
        }
        sqlite3_finalize(statement)

        // Recent transactions (filtered by date range)
        var recentTransactions: [Transaction] = []
        let recentQuery = "SELECT id, statement_id, date, description, merchant, amount, currency, category, created_at FROM transactions WHERE date >= ? AND date <= ? ORDER BY date DESC LIMIT 10"
        if sqlite3_prepare_v2(db, recentQuery, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_double(statement, 1, startDate.timeIntervalSince1970)
            sqlite3_bind_double(statement, 2, endDate.timeIntervalSince1970)
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = String(cString: sqlite3_column_text(statement, 0))
                let statementId = String(cString: sqlite3_column_text(statement, 1))
                let date = Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
                let description = String(cString: sqlite3_column_text(statement, 3))
                let merchant = sqlite3_column_text(statement, 4).map { String(cString: $0) }
                let amount = sqlite3_column_double(statement, 5)
                let currency = String(cString: sqlite3_column_text(statement, 6))
                let category = sqlite3_column_text(statement, 7).map { String(cString: $0) }
                let createdAt = Date(timeIntervalSince1970: sqlite3_column_double(statement, 8))

                recentTransactions.append(Transaction(id: id, statementId: statementId, date: date, description: description, merchant: merchant, amount: amount, currency: currency, category: category, createdAt: createdAt))
            }
        }
        sqlite3_finalize(statement)

        return DashboardStats(
            totalSpending: totalSpending,
            transactionCount: transactionCount,
            categoryBreakdown: categoryBreakdown,
            monthlyComparison: monthlyComparison,
            recentTransactions: recentTransactions
        )
    }
}
