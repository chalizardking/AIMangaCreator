import Foundation

class APIClient {
    static let shared = APIClient()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    private struct CacheEntry {
        let data: Any
        let expiry: Date
        let typeInfo: Any.Type
    }
    
    // Cache for deduplication
    private var requestCache: [String: CacheEntry] = [:]
    private let cacheLock = NSLock()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300 // 5 minutes for large uploads
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }
    
    func post<Request: Encodable, Response: Decodable>(
        endpoint: String,
        body: Request,
        headers: [String: String] = [:],
        baseURL: String = "https://api.openai.com"
    ) async throws -> Response {
        let url = try buildURL(endpoint, baseURL: baseURL)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        request.httpBody = try encoder.encode(body)
        
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        
        return try decoder.decode(Response.self, from: data)
    }
    
    func cachedPost<Request: Encodable & Hashable, Response: Decodable>(
        endpoint: String,
        body: Request,
        cacheDuration: TimeInterval = 3600,
        baseURL: String = "https://api.openai.com"
    ) async throws -> Response {
        let cacheKey = "\(baseURL)\(endpoint)_\(body.hashValue)"
        
        var cachedResponse: Response?
        cacheLock.lock()
        if let cached = requestCache[cacheKey] {
            if cached.expiry <= Date() {
                requestCache.removeValue(forKey: cacheKey)
            } else if cached.typeInfo == Response.self,
                      let typedData = cached.data as? Response {
                cachedResponse = typedData
            } else {
                // Evict entries whose stored type no longer matches the request
                requestCache.removeValue(forKey: cacheKey)
            }
        }
        cacheLock.unlock()
        if let cachedResponse {
            return cachedResponse
        }
        
        let result = try await post(endpoint: endpoint, body: body, baseURL: baseURL) as Response
        
        cacheLock.lock()
        requestCache[cacheKey] = CacheEntry(
            data: result,
            expiry: Date().addingTimeInterval(cacheDuration),
            typeInfo: Response.self
        )
        cacheLock.unlock()
        
        return result
    }
    
    private func buildURL(_ endpoint: String, baseURL: String) throws -> URL {
        // Handle full URLs passed as endpoint
        if endpoint.lowercased().hasPrefix("http") {
            guard let url = URL(string: endpoint) else {
                throw AppError.invalidInput("Invalid URL: \(endpoint)")
            }
            return url
        }
        
        guard let base = URL(string: baseURL) else {
            throw AppError.invalidInput("Invalid base URL: \(baseURL)")
        }
        return base.appendingPathComponent(endpoint)
    }
    
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.networkError(URLError(.badServerResponse))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw AppError.unauthorized("Invalid API key")
        case 429:
            let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init) ?? 60
            throw AppError.rateLimited(retryAfter: retryAfter)
        case 400:
            throw AppError.invalidInput("Invalid request")
        default:
            throw AppError.apiError(.server, "HTTP \(httpResponse.statusCode)")
        }
    }
}
