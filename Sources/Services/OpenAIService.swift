import Foundation

class OpenAIService {
    static let shared = OpenAIService()
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private init() {}

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "openai_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "openai_api_key") }
    }

    var hasApiKey: Bool { !apiKey.isEmpty }

    // MARK: - Parse PDF Statement
    func parseStatement(pdfData: Data) async throws -> ParsedStatement {
        guard hasApiKey else {
            throw OpenAIError.noApiKey
        }

        let base64PDF = pdfData.base64EncodedString()

        let systemPrompt = """
        Sen bir kredi kartı ekstre analiz uzmanısın.
        Verilen PDF ekstresinden aşağıdaki JSON formatında veri çıkar:

        {
          "card_info": {
            "bank": "string - banka adı",
            "card_name": "string - kart adı",
            "last_four": "string - kartın son 4 hanesi"
          },
          "statement_info": {
            "period_start": "YYYY-MM-DD - ekstre dönem başlangıcı",
            "period_end": "YYYY-MM-DD - ekstre dönem sonu",
            "total_amount": number - toplam borç tutarı,
            "min_payment": number - minimum ödeme tutarı,
            "due_date": "YYYY-MM-DD - son ödeme tarihi"
          },
          "transactions": [
            {
              "date": "YYYY-MM-DD - işlem tarihi",
              "description": "string - işlem açıklaması",
              "merchant": "string - işyeri adı",
              "amount": number - tutar (pozitif sayı),
              "category": "string - kategori"
            }
          ]
        }

        Kategoriler şunlardan biri olmalı: Market, Restoran, Ulaşım, Giyim, Teknoloji, Sağlık, Eğlence, Fatura, Abonelik, Eşya, Kırtasiye, İade, Diğer

        Önemli kurallar:
        1. Tarihleri YYYY-MM-DD formatında ver
        2. Kategorileri doğru tahmin et
        3. Sadece JSON döndür, başka açıklama ekleme
        4. Kredi kartı ödemesini gözardı et.
        5. Açıklamalar birden çok satırdaysa bunları birleştir.
        6. description ve merchant KISA olsun (max 20 karakter)
        7. Negatif değerleri İade kategorisine ekle
        """

        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "file",
                            "file": [
                                "filename": "ekstre.pdf",
                                "file_data": "data:application/pdf;base64,\(base64PDF)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": "Bu kredi kartı ekstresini analiz et ve JSON formatında döndür."
                        ]
                    ]
                ]
            ],
            "response_format": ["type": "json_object"],
            "max_completion_tokens": 16384
        ]

        let response: ChatCompletionResponse = try await makeRequest(body: requestBody)

        guard let content = response.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }

        return try JSONDecoder().decode(ParsedStatement.self, from: data)
    }

    // MARK: - Get AI Insights
    func getInsights(transactions: [Transaction]) async throws -> [AIInsight] {
        guard hasApiKey else {
            throw OpenAIError.noApiKey
        }

        guard !transactions.isEmpty else {
            return []
        }

        let transactionSummary = transactions.map { txn in
            [
                "date": ISO8601DateFormatter().string(from: txn.date),
                "merchant": txn.merchant ?? txn.description,
                "amount": txn.amount,
                "category": txn.category ?? "Diğer"
            ] as [String : Any]
        }

        let systemPrompt = """
        Sen bir kişisel finans danışmanısın.
        Verilen harcama verilerini analiz et ve kullanıcıya yardımcı olacak içgörüler sun.

        JSON formatında yanıt ver:
        {
          "insights": [
            {
              "type": "trend | warning | tip | subscription",
              "title": "string - kısa başlık",
              "description": "string - detaylı açıklama",
              "category": "string - ilgili kategori (opsiyonel)",
              "amount": number - ilgili tutar (opsiyonel)
            }
          ]
        }

        İçgörü türleri:
        - trend: Harcama trendi analizi
        - warning: Dikkat edilmesi gereken durum
        - tip: Tasarruf önerisi
        - subscription: Abonelik tespiti

        En fazla 5 içgörü sun. Türkçe yaz.
        """

        let requestBody: [String: Any] = [
            "model": "gpt-5-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": "Son harcamalar:\n\(try! JSONSerialization.data(withJSONObject: transactionSummary, options: .prettyPrinted).toString())"]
            ],
            "response_format": ["type": "json_object"],
            "max_completion_tokens": 16384
        ]

        let response: ChatCompletionResponse = try await makeRequest(body: requestBody)

        guard let content = response.choices.first?.message.content,
              let data = content.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }

        struct InsightsResponse: Codable {
            let insights: [InsightData]
        }

        struct InsightData: Codable {
            let type: String
            let title: String
            let description: String
            let category: String?
            let amount: Double?
        }

        let insightsResponse = try JSONDecoder().decode(InsightsResponse.self, from: data)

        return insightsResponse.insights.enumerated().map { index, insight in
            AIInsight(
                id: "\(index)-\(Date().timeIntervalSince1970)",
                type: AIInsight.InsightType(rawValue: insight.type) ?? .tip,
                title: insight.title,
                description: insight.description,
                category: insight.category,
                amount: insight.amount
            )
        }
    }

    // MARK: - Network Request
    private func makeRequest<T: Decodable>(body: [String: Any]) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                throw OpenAIError.apiError(errorResponse.error.message)
            }
            throw OpenAIError.apiError("HTTP \(httpResponse.statusCode)")
        }

        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Response Models
struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message
    }

    struct Message: Codable {
        let content: String?
    }
}

struct OpenAIErrorResponse: Codable {
    let error: ErrorDetail

    struct ErrorDetail: Codable {
        let message: String
    }
}

// MARK: - Errors
enum OpenAIError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "OpenAI API anahtarı ayarlanmamış. Lütfen Ayarlar'dan API key girin."
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "OpenAI'dan geçersiz yanıt alındı"
        case .apiError(let message):
            return "API Hatası: \(message)"
        }
    }
}

// MARK: - Extensions
extension Data {
    func toString() -> String {
        String(data: self, encoding: .utf8) ?? ""
    }
}
