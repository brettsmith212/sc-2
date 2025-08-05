import Foundation

public struct Config {
    public let clientID: String
    public let clientSecret: String
    public let merchantID: String?
    public let oauthBaseURL: String
    public let apiBaseURL: String
    
    public init() throws {
        guard let infoPlist = Bundle.main.infoDictionary else {
            throw ConfigError.infoPlistNotFound
        }
        
        guard let clientID = infoPlist["UPS_CLIENT_ID"] as? String,
              !clientID.isEmpty,
              clientID != "<FILL-ME>" else {
            throw ConfigError.missingClientID
        }
        
        guard let clientSecret = infoPlist["UPS_CLIENT_SECRET"] as? String,
              !clientSecret.isEmpty,
              clientSecret != "<FILL-ME>" else {
            throw ConfigError.missingClientSecret
        }
        
        guard let oauthBaseURL = infoPlist["UPS_OAUTH_BASE_URL"] as? String,
              !oauthBaseURL.isEmpty else {
            throw ConfigError.missingOAuthBaseURL
        }
        
        guard let apiBaseURL = infoPlist["UPS_API_BASE_URL"] as? String,
              !apiBaseURL.isEmpty else {
            throw ConfigError.missingAPIBaseURL
        }
        
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.oauthBaseURL = oauthBaseURL
        self.apiBaseURL = apiBaseURL
        
        // Merchant ID is optional
        let merchantID = infoPlist["UPS_MERCHANT_ID"] as? String
        self.merchantID = (merchantID?.isEmpty == false && merchantID != "<FILL-ME>") ? merchantID : nil
    }
}

public enum ConfigError: LocalizedError {
    case infoPlistNotFound
    case missingClientID
    case missingClientSecret
    case missingOAuthBaseURL
    case missingAPIBaseURL
    
    public var errorDescription: String? {
        switch self {
        case .infoPlistNotFound:
            return "Info.plist not found in app bundle."
        case .missingClientID:
            return "UPS_CLIENT_ID is missing in build settings. Please add it to Config.xcconfig and reference it in Info.plist."
        case .missingClientSecret:
            return "UPS_CLIENT_SECRET is missing in build settings. Please add it to Config.xcconfig and reference it in Info.plist."
        case .missingOAuthBaseURL:
            return "UPS_OAUTH_BASE_URL is missing in build settings. Please add it to Config.xcconfig and reference it in Info.plist."
        case .missingAPIBaseURL:
            return "UPS_API_BASE_URL is missing in build settings. Please add it to Config.xcconfig and reference it in Info.plist."
        }
    }
}
