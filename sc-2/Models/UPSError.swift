import Foundation

/// UPS API error types with detailed information
public enum UPSError: LocalizedError {
    case configurationError(String)
    case authenticationFailed(Int, String?)
    case invalidCredentials
    case invalidURL(String)
    case tokenExpired
    case tokenRefreshFailed(Error)
    case networkError(Error)
    case httpError(Int, Data?)
    case invalidResponse(String)
    case decodingError(Error)
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(Int, String?)
    case serviceUnavailable
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .authenticationFailed(let code, let message):
            return "Authentication failed (HTTP \(code)): \(message ?? "Unknown error")"
        case .invalidCredentials:
            return "Invalid UPS credentials provided"
        case .invalidURL(let details):
            return "Invalid URL: \(details)"
        case .tokenExpired:
            return "UPS access token has expired"
        case .tokenRefreshFailed(let error):
            return "Failed to refresh UPS token: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error \(code)"
        case .invalidResponse(let message):
            return "Invalid response from UPS API: \(message)"
        case .decodingError(let error):
            return "Failed to decode UPS response: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limited. Retry after \(Int(retryAfter)) seconds"
            } else {
                return "Rate limited. Please try again later"
            }
        case .serverError(let code, let message):
            return "UPS server error (HTTP \(code)): \(message ?? "Unknown server error")"
        case .serviceUnavailable:
            return "UPS service is temporarily unavailable"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    /// Indicates if the error is recoverable through retry
    public var isRetryable: Bool {
        switch self {
        case .networkError, .rateLimited, .serverError, .serviceUnavailable:
            return true
        case .httpError(let code, _):
            return code >= 500 || code == 429 || code == 408
        case .tokenExpired, .tokenRefreshFailed:
            return true
        default:
            return false
        }
    }
    
    /// Suggested retry delay in seconds
    public var retryDelay: TimeInterval? {
        switch self {
        case .rateLimited(let retryAfter):
            return retryAfter
        case .tokenExpired, .tokenRefreshFailed:
            return 1.0
        case .serverError, .serviceUnavailable:
            return 5.0
        default:
            return nil
        }
    }
}

/// UPS API response wrapper for errors
public struct UPSErrorResponse: Codable {
    public let response: UPSErrorWrapper
    
    public struct UPSErrorWrapper: Codable {
        public let errors: [UPSErrorDetail]
    }
    
    public struct UPSErrorDetail: Codable {
        public let code: String
        public let message: String
        public let location: String?
        
        /// Common UPS error codes
        public var errorType: UPSErrorType {
            switch code {
            case "100910":
                return .invalidAddress
            case "120002":
                return .authenticationError
            case "160002":
                return .invalidRequest
            case "250003":
                return .rateLimitExceeded
            default:
                return .unknown
            }
        }
    }
    
    public enum UPSErrorType {
        case invalidAddress
        case authenticationError
        case invalidRequest
        case rateLimitExceeded
        case unknown
    }
}

// MARK: - OAuth Models

/// OAuth token response from UPS
public struct UPSOAuthResponse: Codable {
    public let accessToken: String
    public let tokenType: String
    public let expiresIn: String
    public let scope: String?
    public let issuedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
        case issuedAt = "issued_at"
    }
    
    /// Calculate the expiration date from the current time
    public var expiresAt: Date {
        let seconds = Int(expiresIn) ?? 3600 // Default to 1 hour if parsing fails
        return Date().addingTimeInterval(TimeInterval(seconds))
    }
}

/// Cached token information
public struct UPSToken {
    public let accessToken: String
    public let tokenType: String
    public let expiresAt: Date
    public let scope: String?
    
    /// Check if the token is expired or will expire within the given threshold
    public func isExpired(threshold: TimeInterval = 60) -> Bool {
        return expiresAt.timeIntervalSinceNow <= threshold
    }
    
    /// Authorization header value
    public var authorizationHeader: String {
        return "\(tokenType) \(accessToken)"
    }
    
    /// Time remaining until expiration
    public var timeUntilExpiration: TimeInterval {
        return expiresAt.timeIntervalSinceNow
    }
}
