import Foundation

/// UPS OAuth service for managing access tokens with automatic refresh
@MainActor
public class UPSOAuthService {
    
    // MARK: - Properties
    
    private let config: Config
    private let httpClient: HTTPClient
    private let tokenExpirationThreshold: TimeInterval
    
    // Token storage
    private var cachedToken: UPSToken?
    private var refreshTask: Task<UPSToken, Error>?
    
    // MARK: - Initialization
    
    /// Initialize the OAuth service
    /// - Parameters:
    ///   - config: UPS configuration containing credentials and URLs
    ///   - httpClient: HTTP client for making requests
    ///   - tokenExpirationThreshold: Threshold in seconds to refresh token before expiration (default: 60s)
    public init(
        config: Config,
        httpClient: HTTPClient = HTTPClient(),
        tokenExpirationThreshold: TimeInterval = 60
    ) {
        self.config = config
        self.httpClient = httpClient
        self.tokenExpirationThreshold = tokenExpirationThreshold
    }
    
    // MARK: - Public Methods
    
    /// Get a valid access token, refreshing if necessary
    /// - Returns: Valid UPS access token
    /// - Throws: UPSError if token retrieval fails
    public func getValidToken() async throws -> UPSToken {
        // Check if we have a valid cached token
        if let token = cachedToken, !token.isExpired(threshold: tokenExpirationThreshold) {
            return token
        }
        
        // Check if there's already a refresh in progress
        if let existingRefreshTask = refreshTask {
            return try await existingRefreshTask.value
        }
        
        // Start a new refresh task
        let refreshTask = Task<UPSToken, Error> {
            do {
                let newToken = try await refreshToken()
                await MainActor.run {
                    self.cachedToken = newToken
                    self.refreshTask = nil
                }
                return newToken
            } catch {
                await MainActor.run {
                    self.refreshTask = nil
                }
                throw error
            }
        }
        
        self.refreshTask = refreshTask
        return try await refreshTask.value
    }
    
    /// Get authorization header for API requests
    /// - Returns: Authorization header value
    /// - Throws: UPSError if token retrieval fails
    public func getAuthorizationHeader() async throws -> String {
        let token = try await getValidToken()
        return token.authorizationHeader
    }
    
    /// Invalidate the current token and force refresh on next request
    public func invalidateToken() {
        cachedToken = nil
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    /// Execute an API request with automatic token refresh on 401 errors
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method
    ///   - headers: Additional headers (Authorization will be added automatically)
    ///   - body: Request body
    /// - Returns: Response data and HTTP response
    /// - Throws: UPSError on failure
    public func authenticatedRequest(
        url: URL,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        return try await performAuthenticatedRequest(
            url: url,
            method: method,
            headers: headers,
            body: body,
            isRetry: false
        )
    }
    
    /// Execute a JSON API request with automatic token refresh
    /// - Parameters:
    ///   - url: The URL to request
    ///   - method: HTTP method
    ///   - headers: Additional headers
    ///   - json: Encodable object to send as JSON
    /// - Returns: Response data and HTTP response
    /// - Throws: UPSError on failure
    public func authenticatedJSONRequest<T: Encodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String] = [:],
        json: T
    ) async throws -> (Data, HTTPURLResponse) {
        let authHeader = try await getAuthorizationHeader()
        var requestHeaders = headers
        requestHeaders["Authorization"] = authHeader
        
        do {
            return try await httpClient.requestJSON(
                url: url,
                method: method,
                headers: requestHeaders,
                json: json
            )
        } catch HTTPClientError.statusCode(401, _) {
            // Token expired, invalidate and retry once
            invalidateToken()
            let newAuthHeader = try await getAuthorizationHeader()
            requestHeaders["Authorization"] = newAuthHeader
            
            return try await httpClient.requestJSON(
                url: url,
                method: method,
                headers: requestHeaders,
                json: json
            )
        } catch {
            throw mapHTTPClientError(error)
        }
    }
    
    // MARK: - Private Methods
    
    private func performAuthenticatedRequest(
        url: URL,
        method: HTTPMethod,
        headers: [String: String],
        body: Data?,
        isRetry: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        let authHeader = try await getAuthorizationHeader()
        var requestHeaders = headers
        requestHeaders["Authorization"] = authHeader
        
        do {
            return try await httpClient.request(
                url: url,
                method: method,
                headers: requestHeaders,
                body: body
            )
        } catch HTTPClientError.statusCode(401, _) where !isRetry {
            // Token expired, invalidate and retry once
            invalidateToken()
            return try await performAuthenticatedRequest(
                url: url,
                method: method,
                headers: headers,
                body: body,
                isRetry: true
            )
        } catch {
            throw mapHTTPClientError(error)
        }
    }
    
    /// Refresh the OAuth token using client credentials grant
    private func refreshToken() async throws -> UPSToken {
        // Construct OAuth endpoint URL
        guard let baseURL = URL(string: config.oauthBaseURL) else {
            throw UPSError.configurationError("Invalid OAuth base URL: \(config.oauthBaseURL)")
        }
        
        let tokenURL = baseURL.appendingPathComponent("security/v1/oauth/token")
        
        // Prepare Basic Auth header
        let credentials = "\(config.clientID):\(config.clientSecret)"
        guard let credentialsData = credentials.data(using: .utf8) else {
            throw UPSError.configurationError("Failed to encode credentials")
        }
        let base64Credentials = credentialsData.base64EncodedString()
        
        // Prepare headers
        var headers = [
            "Authorization": "Basic \(base64Credentials)",
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "application/json"
        ]
        
        // Add merchant ID if available
        if let merchantID = config.merchantID, merchantID != "<FILL-ME>", !merchantID.isEmpty {
            headers["x-merchant-id"] = merchantID
        }
        
        // Prepare form data
        let formData = ["grant_type": "client_credentials"]
        
        do {
            let (data, response) = try await httpClient.requestForm(
                url: tokenURL,
                method: .POST,
                headers: headers,
                formData: formData
            )
            
            // Check response status
            guard response.isSuccessful else {
                throw try handleOAuthErrorResponse(data: data, statusCode: response.statusCode)
            }
            
            // Decode OAuth response
            let decoder = JSONDecoder()
            let oauthResponse = try decoder.decode(UPSOAuthResponse.self, from: data)
            
            // Create cached token
            let token = UPSToken(
                accessToken: oauthResponse.accessToken,
                tokenType: oauthResponse.tokenType,
                expiresAt: oauthResponse.expiresAt,
                scope: oauthResponse.scope
            )
            
            return token
            
        } catch {
            if let upsError = error as? UPSError {
                throw upsError
            } else {
                throw UPSError.tokenRefreshFailed(error)
            }
        }
    }
    
    /// Handle OAuth error responses
    private func handleOAuthErrorResponse(data: Data, statusCode: Int) throws -> UPSError {
        // Try to decode UPS error response
        if let errorResponse = try? JSONDecoder().decode(UPSErrorResponse.self, from: data),
           let firstError = errorResponse.response.errors.first {
            
            switch statusCode {
            case 401:
                return UPSError.authenticationFailed(statusCode, firstError.message)
            case 429:
                return UPSError.rateLimited(retryAfter: nil)
            case 500...599:
                return UPSError.serverError(statusCode, firstError.message)
            default:
                return UPSError.httpError(statusCode, data)
            }
        }
        
        // Fallback to generic HTTP error
        switch statusCode {
        case 401:
            return UPSError.invalidCredentials
        case 429:
            return UPSError.rateLimited(retryAfter: nil)
        case 500...599:
            return UPSError.serverError(statusCode, nil)
        default:
            return UPSError.httpError(statusCode, data)
        }
    }
    
    /// Map HTTPClientError to UPSError
    private func mapHTTPClientError(_ error: Error) -> UPSError {
        if let httpError = error as? HTTPClientError {
            switch httpError {
            case .networkError(let underlyingError):
                return UPSError.networkError(underlyingError)
            case .statusCode(let code, let data):
                switch code {
                case 401:
                    return UPSError.authenticationFailed(code, nil)
                case 429:
                    return UPSError.rateLimited(retryAfter: nil)
                case 500...599:
                    return UPSError.serverError(code, nil)
                default:
                    return UPSError.httpError(code, data)
                }
            case .invalidURL:
                return UPSError.configurationError("Invalid URL")
            case .noData:
                return UPSError.invalidResponse("No data received")
            case .retryLimitExceeded:
                return UPSError.networkError(httpError)
            case .invalidResponse:
                return UPSError.invalidResponse("Invalid response format")
            }
        } else if error is DecodingError {
            return UPSError.decodingError(error)
        } else {
            return UPSError.unknown(error)
        }
    }
}

// MARK: - Token Debugging

#if DEBUG
extension UPSOAuthService {
    /// Get current token information for debugging
    public var currentTokenInfo: String? {
        guard let token = cachedToken else {
            return "No token cached"
        }
        
        let timeRemaining = token.timeUntilExpiration
        let status = token.isExpired(threshold: tokenExpirationThreshold) ? "EXPIRED" : "VALID"
        
        return """
        Token Status: \(status)
        Type: \(token.tokenType)
        Expires: \(token.expiresAt)
        Time Remaining: \(String(format: "%.1f", timeRemaining))s
        Scope: \(token.scope ?? "none")
        """
    }
}
#endif
