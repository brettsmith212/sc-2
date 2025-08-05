import Foundation

/// HTTP method enum for different request types
public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

/// HTTP Client error types
public enum HTTPClientError: LocalizedError {
    case invalidURL
    case noData
    case statusCode(Int, Data?)
    case networkError(Error)
    case retryLimitExceeded
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL provided"
        case .noData:
            return "No data received from server"
        case .statusCode(let code, _):
            return "HTTP error with status code: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .retryLimitExceeded:
            return "Maximum retry attempts exceeded"
        case .invalidResponse:
            return "Invalid response received from server"
        }
    }
}

/// Configuration for retry behavior
public struct RetryConfiguration {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        retryableStatusCodes: Set<Int> = [408, 429, 502, 503, 504]
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.retryableStatusCodes = retryableStatusCodes
    }
    
    public static let `default` = RetryConfiguration()
}

/// Generic HTTP Client for making network requests
public class HTTPClient {
    private let session: URLSession
    private let retryConfiguration: RetryConfiguration
    
    public init(
        session: URLSession = .shared,
        retryConfiguration: RetryConfiguration = .default
    ) {
        self.session = session
        self.retryConfiguration = retryConfiguration
    }
    
    /// Make an HTTP request with automatic retry logic
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method (default: GET)
    ///   - headers: Additional headers to include
    ///   - body: Request body data
    /// - Returns: Tuple of response data and HTTP response
    /// - Throws: HTTPClientError on failure
    public func request(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        return try await requestWithRetry(
            url: url,
            method: method,
            headers: headers,
            body: body,
            attempt: 1
        )
    }
    
    /// Convenience method for JSON requests
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method
    ///   - headers: Additional headers to include
    ///   - json: Encodable object to send as JSON
    /// - Returns: Tuple of response data and HTTP response
    /// - Throws: HTTPClientError on failure
    public func requestJSON<T: Encodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        json: T
    ) async throws -> (Data, HTTPURLResponse) {
        let encoder = JSONEncoder()
        let body = try encoder.encode(json)
        
        var jsonHeaders = headers
        jsonHeaders["Content-Type"] = "application/json"
        if jsonHeaders["Accept"] == nil {
            jsonHeaders["Accept"] = "application/json"
        }
        
        return try await request(
            url: url,
            method: method,
            headers: jsonHeaders,
            body: body
        )
    }
    
    /// Convenience method for form-encoded requests
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method
    ///   - headers: Additional headers to include
    ///   - formData: Dictionary of form parameters
    /// - Returns: Tuple of response data and HTTP response
    /// - Throws: HTTPClientError on failure
    public func requestForm(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        formData: [String: String]
    ) async throws -> (Data, HTTPURLResponse) {
        let formBody = formData
            .map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
            .joined(separator: "&")
            .data(using: .utf8)
        
        var formHeaders = headers
        formHeaders["Content-Type"] = "application/x-www-form-urlencoded"
        
        return try await request(
            url: url,
            method: method,
            headers: formHeaders,
            body: formBody
        )
    }
    
    // MARK: - Private Methods
    
    private func requestWithRetry(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        attempt: Int
    ) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await performRequest(
                url: url,
                method: method,
                headers: headers,
                body: body
            )
            
            // Check if we should retry based on status code
            if retryConfiguration.retryableStatusCodes.contains(response.statusCode) && 
               attempt <= retryConfiguration.maxRetries {
                
                let delay = calculateDelay(attempt: attempt, response: response)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await requestWithRetry(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body,
                    attempt: attempt + 1
                )
            }
            
            return (data, response)
            
        } catch {
            // Retry on network errors if we haven't exceeded max attempts
            if attempt <= retryConfiguration.maxRetries {
                let delay = calculateDelay(attempt: attempt, response: nil)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await requestWithRetry(
                    url: url,
                    method: method,
                    headers: headers,
                    body: body,
                    attempt: attempt + 1
                )
            }
            
            if attempt > retryConfiguration.maxRetries {
                throw HTTPClientError.retryLimitExceeded
            }
            
            throw error
        }
    }
    
    private func performRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        // Set headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HTTPClientError.invalidResponse
            }
            
            return (data, httpResponse)
            
        } catch {
            throw HTTPClientError.networkError(error)
        }
    }
    
    private func calculateDelay(attempt: Int, response: HTTPURLResponse?) -> TimeInterval {
        // Check for Retry-After header (common with 429 Too Many Requests)
        if let response = response,
           let retryAfterString = response.value(forHTTPHeaderField: "Retry-After"),
           let retryAfter = TimeInterval(retryAfterString) {
            return min(retryAfter, retryConfiguration.maxDelay)
        }
        
        // Exponential backoff: baseDelay * (2 ^ (attempt - 1))
        let exponentialDelay = retryConfiguration.baseDelay * pow(2.0, Double(attempt - 1))
        
        // Add jitter (±25%) to prevent thundering herd
        let jitter = exponentialDelay * 0.25 * (Double.random(in: -1...1))
        let delayWithJitter = exponentialDelay + jitter
        
        return min(delayWithJitter, retryConfiguration.maxDelay)
    }
}

// MARK: - Response Helpers

public extension HTTPURLResponse {
    /// Check if the status code indicates success (200-299)
    var isSuccessful: Bool {
        return (200...299).contains(statusCode)
    }
    
    /// Check if the status code indicates a client error (400-499)
    var isClientError: Bool {
        return (400...499).contains(statusCode)
    }
    
    /// Check if the status code indicates a server error (500-599)
    var isServerError: Bool {
        return (500...599).contains(statusCode)
    }
}

// MARK: - Data Helpers

public extension Data {
    /// Decode JSON data to a Decodable type
    /// - Parameter type: The type to decode to
    /// - Returns: Decoded object
    /// - Throws: DecodingError on failure
    func decoded<T: Decodable>(as type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        return try decoder.decode(type, from: self)
    }
    
    /// Convert data to a pretty-printed JSON string for debugging
    var prettyPrintedJSON: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
