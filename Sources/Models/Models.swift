import Foundation

// MARK: - AI Provider
enum AIProvider: String, CaseIterable, Identifiable {
    case openai = "OpenAI"
    case gemini = "Google Gemini"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .openai: return "brain"
        case .gemini: return "sparkles"
        }
    }
}

// MARK: - Card
struct Card: Identifiable, Codable {
    let id: String
    var name: String
    var bank: String?
    var lastFour: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, bank: String? = nil, lastFour: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.bank = bank
        self.lastFour = lastFour
        self.createdAt = createdAt
    }
}

// MARK: - Statement
struct Statement: Identifiable, Codable {
    let id: String
    var cardId: String
    var periodStart: Date?
    var periodEnd: Date?
    var totalAmount: Double?
    var minPayment: Double?
    var dueDate: Date?
    var pdfPath: String?
    var rawJson: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, cardId: String, periodStart: Date? = nil, periodEnd: Date? = nil, totalAmount: Double? = nil, minPayment: Double? = nil, dueDate: Date? = nil, pdfPath: String? = nil, rawJson: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.cardId = cardId
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.totalAmount = totalAmount
        self.minPayment = minPayment
        self.dueDate = dueDate
        self.pdfPath = pdfPath
        self.rawJson = rawJson
        self.createdAt = createdAt
    }
}

// MARK: - Transaction
struct Transaction: Identifiable, Codable {
    let id: String
    var statementId: String
    var date: Date
    var description: String
    var merchant: String?
    var amount: Double
    var currency: String
    var category: String?
    var createdAt: Date

    init(id: String = UUID().uuidString, statementId: String, date: Date, description: String, merchant: String? = nil, amount: Double, currency: String = "TRY", category: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.statementId = statementId
        self.date = date
        self.description = description
        self.merchant = merchant
        self.amount = amount
        self.currency = currency
        self.category = category
        self.createdAt = createdAt
    }
}

// MARK: - Category
struct Category: Identifiable, Codable {
    let id: String
    var name: String
    var icon: String
    var color: String
    var isCustom: Bool

    init(id: String = UUID().uuidString, name: String, icon: String, color: String, isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.isCustom = isCustom
    }

    static let defaults: [Category] = [
        Category(id: "1", name: "Market", icon: "cart.fill", color: "#22c55e"),
        Category(id: "2", name: "Restoran", icon: "fork.knife", color: "#f97316"),
        Category(id: "3", name: "Ulaşım", icon: "car.fill", color: "#3b82f6"),
        Category(id: "4", name: "Giyim", icon: "tshirt.fill", color: "#a855f7"),
        Category(id: "5", name: "Teknoloji", icon: "laptopcomputer", color: "#6366f1"),
        Category(id: "6", name: "Sağlık", icon: "heart.fill", color: "#ef4444"),
        Category(id: "7", name: "Eğlence", icon: "film.fill", color: "#ec4899"),
        Category(id: "8", name: "Fatura", icon: "doc.text.fill", color: "#84cc16"),
        Category(id: "9", name: "Abonelik", icon: "repeat", color: "#14b8a6"),
        Category(id: "10", name: "Eşya", icon: "shippingbox.fill", color: "#f59e0b"),
        Category(id: "11", name: "Kırtasiye", icon: "pencil.and.ruler.fill", color: "#eab308"),
        Category(id: "12", name: "İade", icon: "arrow.uturn.backward.circle.fill", color: "#06b6d4"),
        Category(id: "13", name: "Diğer", icon: "ellipsis.circle.fill", color: "#6b7280")
    ]

    static let defaultIcons = [
        // Alışveriş & Market
        "cart.fill", "bag.fill", "basket.fill", "storefront.fill",
        // Yeme & İçme
        "fork.knife", "cup.and.saucer.fill", "mug.fill", "wineglass.fill", "birthday.cake.fill",
        // Ulaşım
        "car.fill", "bus.fill", "tram.fill", "airplane", "fuelpump.fill", "bicycle",
        // Giyim & Kişisel
        "tshirt.fill", "shoe.fill", "eyeglasses", "comb.fill",
        // Teknoloji
        "laptopcomputer", "desktopcomputer", "iphone", "headphones", "tv.fill", "gamecontroller.fill",
        // Sağlık
        "heart.fill", "cross.case.fill", "pills.fill", "figure.walk", "dumbbell.fill",
        // Eğlence & Medya
        "film.fill", "music.note", "ticket.fill", "theatermasks.fill", "book.fill",
        // Ev & Fatura
        "house.fill", "lightbulb.fill", "drop.fill", "flame.fill", "wifi",
        // Finans & İş
        "doc.text.fill", "briefcase.fill", "banknote.fill", "creditcard.fill", "chart.line.uptrend.xyaxis",
        // Eğitim
        "graduationcap.fill", "books.vertical.fill", "pencil.and.ruler.fill",
        // Diğer
        "gift.fill", "pawprint.fill", "leaf.fill", "camera.fill", "paintbrush.fill",
        "wrench.and.screwdriver.fill", "scissors", "repeat", "star.fill", "tag.fill",
        "phone.fill", "envelope.fill", "map.fill", "bed.double.fill", "party.popper.fill"
    ]

    static let defaultColors = [
        "#22c55e", "#f97316", "#3b82f6", "#a855f7", "#6366f1",
        "#ef4444", "#ec4899", "#84cc16", "#14b8a6", "#f59e0b",
        "#06b6d4", "#8b5cf6", "#d946ef", "#0ea5e9", "#10b981"
    ]
}

// MARK: - OpenAI Response Models
struct ParsedStatement: Codable {
    let cardInfo: CardInfo
    let statementInfo: StatementInfo
    let transactions: [ParsedTransaction]

    enum CodingKeys: String, CodingKey {
        case cardInfo = "card_info"
        case statementInfo = "statement_info"
        case transactions
    }
}

struct CardInfo: Codable {
    let bank: String?
    let cardName: String?
    let lastFour: String?

    enum CodingKeys: String, CodingKey {
        case bank
        case cardName = "card_name"
        case lastFour = "last_four"
    }
}

struct StatementInfo: Codable {
    let periodStart: String?
    let periodEnd: String?
    let totalAmount: Double?
    let minPayment: Double?
    let dueDate: String?

    enum CodingKeys: String, CodingKey {
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case totalAmount = "total_amount"
        case minPayment = "min_payment"
        case dueDate = "due_date"
    }
}

struct ParsedTransaction: Codable {
    let date: String
    let description: String
    let merchant: String?
    let amount: Double
    let category: String?
}

// MARK: - AI Insight
struct AIInsight: Identifiable {
    let id: String
    let type: InsightType
    let title: String
    let description: String
    let category: String?
    let amount: Double?

    enum InsightType: String {
        case trend, warning, tip, subscription
    }
}

// MARK: - Dashboard Stats
struct DashboardStats {
    var totalSpending: Double
    var transactionCount: Int
    var categoryBreakdown: [CategoryBreakdown]
    var monthlyComparison: [MonthlyData]
    var recentTransactions: [Transaction]
}

struct CategoryBreakdown: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
    let percentage: Double
    let color: String
}

struct MonthlyData: Identifiable {
    let id = UUID()
    let month: String
    let amount: Double
}

// MARK: - Date Filter
enum DateFilter: Hashable, Identifiable {
    case thisMonth
    case lastMonth
    case last3Months
    case last6Months
    case thisYear
    case lastYear
    case specificMonth(Date)

    var id: String {
        switch self {
        case .thisMonth: return "thisMonth"
        case .lastMonth: return "lastMonth"
        case .last3Months: return "last3Months"
        case .last6Months: return "last6Months"
        case .thisYear: return "thisYear"
        case .lastYear: return "lastYear"
        case .specificMonth(let date): return "month_\(date.timeIntervalSince1970)"
        }
    }

    var displayName: String {
        switch self {
        case .thisMonth: return "Bu Ay"
        case .lastMonth: return "Geçen Ay"
        case .last3Months: return "Son 3 Ay"
        case .last6Months: return "Son 6 Ay"
        case .thisYear: return "Bu Yıl"
        case .lastYear: return "Son 1 Yıl"
        case .specificMonth(let date):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "tr_TR")
            return formatter.string(from: date)
        }
    }

    var dateRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)

        case .lastMonth:
            let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let start = calendar.date(byAdding: .month, value: -1, to: thisMonthStart)!
            let end = calendar.date(byAdding: .day, value: -1, to: thisMonthStart)!
            return (start, end)

        case .last3Months:
            let start = calendar.date(byAdding: .month, value: -3, to: now)!
            return (start, now)

        case .last6Months:
            let start = calendar.date(byAdding: .month, value: -6, to: now)!
            return (start, now)

        case .thisYear:
            let start = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return (start, now)

        case .lastYear:
            let start = calendar.date(byAdding: .year, value: -1, to: now)!
            return (start, now)

        case .specificMonth(let date):
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date))!
            let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start)!
            return (start, end)
        }
    }

    static var presets: [DateFilter] {
        [.thisMonth, .lastMonth, .last3Months, .last6Months, .thisYear, .lastYear]
    }

    static var recentMonths: [DateFilter] {
        var months: [DateFilter] = []
        let calendar = Calendar.current
        for i in 0..<12 {
            if let date = calendar.date(byAdding: .month, value: -i, to: Date()) {
                months.append(.specificMonth(date))
            }
        }
        return months
    }
}

// MARK: - Month Comparison
struct MonthComparison {
    let month1: Date
    let month2: Date
    let month1Total: Double
    let month2Total: Double
    let categoryComparisons: [CategoryComparison]

    var totalDifference: Double { month2Total - month1Total }
    var totalPercentageChange: Double {
        month1Total > 0 ? ((month2Total - month1Total) / month1Total) * 100 : 0
    }
}

struct CategoryComparison: Identifiable {
    let id = UUID()
    let category: String
    let month1Amount: Double
    let month2Amount: Double
    var difference: Double { month2Amount - month1Amount }
    var percentageChange: Double {
        month1Amount > 0 ? ((month2Amount - month1Amount) / month1Amount) * 100 : 0
    }
}

// MARK: - Navigation
enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case statements = "Ekstreler"
    case transactions = "İşlemler"
    case cards = "Kartlar"
    case comparison = "Karşılaştırma"
    case insights = "AI Öneriler"
    case settings = "Ayarlar"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dashboard: return "chart.pie.fill"
        case .statements: return "doc.text.fill"
        case .transactions: return "list.bullet.rectangle.fill"
        case .cards: return "creditcard.fill"
        case .comparison: return "arrow.left.arrow.right"
        case .insights: return "sparkles"
        case .settings: return "gearshape.fill"
        }
    }
}
