import Foundation

class GeminiService {
    static let shared = GeminiService()
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    private init() {}

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: "gemini_api_key") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "gemini_api_key") }
    }

    var hasApiKey: Bool { !apiKey.isEmpty }

    // MARK: - Parse PDF Statement
    func parseStatement(pdfData: Data) async throws -> ParsedStatement {
        guard hasApiKey else {
            throw GeminiError.noApiKey
        }

        let base64PDF = pdfData.base64EncodedString()

        let systemPrompt = """
        Kredi kartı ekstresini analiz et. JSON döndür:
        {"card_info":{"bank":"X","card_name":"X","last_four":"1234"},"statement_info":{"period_start":"YYYY-MM-DD","period_end":"YYYY-MM-DD","total_amount":0,"min_payment":0,"due_date":"YYYY-MM-DD"},"transactions":[{"date":"YYYY-MM-DD","description":"kısa","merchant":"kısa","amount":0,"category":"X"}]}

        Kurallar:
        - Kategoriler: Market,Restoran,Ulaşım,Giyim,Teknoloji,Sağlık,Eğlence,Fatura,Abonelik,Eşya,Kırtasiye, İade, Diğer
        - description ve merchant KISA olsun (max 20 karakter)
        - Kredi kartı ödemelerini dahil etme
        - Sadece JSON döndür ayrıca açıklama yok
        - Negatif değerleri İade kategorisine ekle
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": systemPrompt],
                        [
                            "inline_data": [
                                "mime_type": "application/pdf",
                                "data": base64PDF
                            ]
                        ],
                        ["text": "Bu kredi kartı ekstresini analiz et ve JSON formatında döndür."]
                    ]
                ]
            ],
            "generationConfig": [
                "responseMimeType": "application/json",
                "maxOutputTokens": 65536
            ]
        ]

        let model = "gemini-2.0-flash"
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            if let errorResponse = try? JSONDecoder().decode(GeminiErrorResponse.self, from: data) {
                throw GeminiError.apiError(errorResponse.error.message)
            }
            throw GeminiError.apiError("HTTP \(httpResponse.statusCode)")
        }

        let geminiResponse: GeminiResponse
        do {
            geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        } catch {
            throw GeminiError.apiError("Response parse error: \(error.localizedDescription)")
        }

        guard let candidate = geminiResponse.candidates?.first else {
            throw GeminiError.invalidResponse
        }

        guard let part = candidate.content?.parts?.first else {
            throw GeminiError.invalidResponse
        }

        guard var content = part.text else {
            throw GeminiError.invalidResponse
        }

        // Clean up JSON if wrapped in markdown code block
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        if content.hasPrefix("```json") {
            content = String(content.dropFirst(7))
        } else if content.hasPrefix("```") {
            content = String(content.dropFirst(3))
        }
        if content.hasSuffix("```") {
            content = String(content.dropLast(3))
        }
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = content.data(using: .utf8) else {
            throw GeminiError.invalidResponse
        }

        // Check if response is an array and extract first element
        if content.trimmingCharacters(in: .whitespaces).hasPrefix("[") {
            do {
                let array = try JSONDecoder().decode([ParsedStatement].self, from: jsonData)
                guard let first = array.first else {
                    throw GeminiError.invalidResponse
                }
                return first
            } catch {
                throw GeminiError.apiError("JSON parse error: \(error.localizedDescription)")
            }
        }

        do {
            let parsed = try JSONDecoder().decode(ParsedStatement.self, from: jsonData)
            return parsed
        } catch {
            throw GeminiError.apiError("JSON parse error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Response Models
struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]?
}

struct GeminiCandidate: Codable {
    let content: GeminiContent?
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]?
}

struct GeminiPart: Codable {
    let text: String?
}

struct GeminiErrorResponse: Codable {
    let error: GeminiErrorDetail
}

struct GeminiErrorDetail: Codable {
    let message: String
}

// MARK: - Errors
enum GeminiError: LocalizedError {
    case noApiKey
    case invalidURL
    case invalidResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "Gemini API anahtarı ayarlanmamış. Lütfen Ayarlar'dan API key girin."
        case .invalidURL:
            return "Geçersiz URL"
        case .invalidResponse:
            return "Gemini'den geçersiz yanıt alındı"
        case .apiError(let message):
            return "API Hatası: \(message)"
        }
    }
}
