import Foundation

@MainActor
public final class UPSAddressValidationService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let httpClient: HTTPClient
    private let oauthService: UPSOAuthService
    private let config: Config
    
    // MARK: - Initialization
    
    public init(httpClient: HTTPClient = HTTPClient(), oauthService: UPSOAuthService? = nil, config: Config? = nil) {
        self.httpClient = httpClient
        do {
            self.config = try config ?? Config()
        } catch {
            fatalError("Failed to load UPS configuration: \(error)")
        }
        self.oauthService = oauthService ?? UPSOAuthService(config: self.config, httpClient: httpClient)
    }
    
    // MARK: - Public API
    
    /// Validates an address using UPS Address Validation API
    /// - Parameter request: The address validation request containing address and options
    /// - Returns: Result containing XAVResponse on success or UPSError on failure
    public func validate(_ request: UPSAddressValidationRequest) async -> Result<XAVResponse, UPSError> {
        do {
            // Build the request URL
            let url = try buildRequestURL(for: request)
            
            // Create the request body
            let requestBody = createRequestBody(from: request.address)
            
            // Get authorization header
            let authHeader = try await oauthService.getAuthorizationHeader()
            
            // Build headers
            let headers = buildHeaders(authHeader: authHeader)
            
            // Make the request
            let (data, _) = try await oauthService.authenticatedRequest(
                url: url,
                method: .POST,
                headers: headers,
                body: try JSONEncoder().encode(requestBody)
            )
            
            // Decode the response
            let responseWrapper = try JSONDecoder().decode(XAVResponseWrapper.self, from: data)
            
            return .success(responseWrapper.xavResponse)
            
        } catch let error as UPSError {
            return .failure(error)
        } catch {
            return .failure(.networkError(error))
        }
    }
    
    // MARK: - Private Methods
    
    private func buildRequestURL(for request: UPSAddressValidationRequest) throws -> URL {
        var components = URLComponents(string: "\(config.apiBaseURL)/api/addressvalidation/v2/\(request.requestOption.path)")
        
        var queryItems: [URLQueryItem] = []
        
        if let regional = request.regionalRequestIndicator {
            queryItems.append(URLQueryItem(name: "regionalrequestindicator", value: regional))
        }
        
        if let maxCandidates = request.maximumCandidateListSize {
            queryItems.append(URLQueryItem(name: "maximumcandidatelistsize", value: "\(maxCandidates)"))
        }
        
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        
        guard let url = components?.url else {
            throw UPSError.invalidURL("Failed to build address validation URL")
        }
        
        return url
    }
    
    private func createRequestBody(from address: UPSAddress) -> XAVRequestWrapper {
        let addressKeyFormat = AddressKeyFormat(from: address)
        let xavRequest = XAVRequest(addressKeyFormat: addressKeyFormat)
        return XAVRequestWrapper(xavRequest: xavRequest)
    }
    
    private func buildHeaders(authHeader: String) -> [String: String] {
        let transactionId = String(UUID().uuidString.prefix(32)) // Max 32 chars
        
        return [
            "Authorization": authHeader,
            "transId": transactionId,
            "transactionSrc": "iOSDemo",
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}

// MARK: - Convenience Methods

extension UPSAddressValidationService {
    
    /// Convenience method to validate an address with minimal parameters
    /// - Parameters:
    ///   - street: Street address
    ///   - city: City name
    ///   - state: State/province code
    ///   - postalCode: Postal/ZIP code
    ///   - countryCode: Country code (default: "US")
    ///   - requestOption: Type of validation (default: .validation)
    /// - Returns: Result containing XAVResponse on success or UPSError on failure
    public func validateAddress(
        street: String,
        city: String,
        state: String,
        postalCode: String,
        countryCode: String = "US",
        requestOption: UPSRequestOption = .validation
    ) async -> Result<XAVResponse, UPSError> {
        let address = UPSAddress(
            street: street,
            city: city,
            state: state,
            postalCode: postalCode,
            countryCode: countryCode
        )
        
        let request = UPSAddressValidationRequest(
            address: address,
            requestOption: requestOption
        )
        
        return await validate(request)
    }
    
    /// Validates a US address with classification
    /// - Parameters:
    ///   - street: Street address
    ///   - city: City name
    ///   - state: State code (e.g., "CA", "NY")
    ///   - zipCode: ZIP code
    /// - Returns: Result containing XAVResponse on success or UPSError on failure
    public func validateUSAddressWithClassification(
        street: String,
        city: String,
        state: String,
        zipCode: String
    ) async -> Result<XAVResponse, UPSError> {
        return await validateAddress(
            street: street,
            city: city,
            state: state,
            postalCode: zipCode,
            countryCode: "US",
            requestOption: .both
        )
    }
}

// MARK: - Error Handling Extensions

extension UPSAddressValidationService {
    
    /// Checks if an error is specific to address validation and provides user-friendly messages
    /// - Parameter error: The UPSError to analyze
    /// - Returns: A user-friendly error message
    public static func userFriendlyMessage(for error: UPSError) -> String {
        switch error {
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .authenticationFailed(let code, let message):
            return "Authentication failed (HTTP \(code)): \(message ?? "Please check your UPS API credentials.")"
        case .invalidCredentials:
            return "Authentication failed. Please check your UPS API credentials."
        case .invalidURL(let details):
            return "Invalid request: \(details)"
        case .tokenExpired:
            return "Access token expired. Please try again."
        case .tokenRefreshFailed(let error):
            return "Failed to refresh token: \(error.localizedDescription)"
        case .networkError(let underlyingError):
            if let urlError = underlyingError as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    return "No internet connection. Please check your network and try again."
                case .timedOut:
                    return "Request timed out. Please try again."
                default:
                    return "Network error: \(urlError.localizedDescription)"
                }
            }
            return "Network error: \(underlyingError.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error occurred (code: \(code))"
        case .invalidResponse(let details):
            return "Invalid response from server: \(details)"
        case .decodingError(let error):
            return "Failed to process server response: \(error.localizedDescription)"
        case .rateLimited(let retryAfter):
            if let retrySeconds = retryAfter {
                return "Too many requests. Please try again in \(Int(retrySeconds)) seconds."
            } else {
                return "Too many requests. Please try again later."
            }
        case .serverError(let code, let message):
            switch code {
            case 100910:
                return "The address you entered could not be validated. Please check the address and try again."
            case 120002:
                return "Invalid address format. Please check all required fields are filled correctly."
            case 160002:
                return "The postal code is invalid for the specified city and state."
            default:
                return message ?? "Server error occurred (code: \(code))"
            }
        case .serviceUnavailable:
            return "UPS service is currently unavailable. Please try again later."
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension UPSAddressValidationService {
    
    /// Debug method to test the service with a sample address
    /// - Returns: Result containing XAVResponse on success or UPSError on failure
    public func testWithSampleAddress() async -> Result<XAVResponse, UPSError> {
        return await validateAddress(
            street: "1600 Amphitheatre Parkway",
            city: "Mountain View",
            state: "CA",
            postalCode: "94043",
            countryCode: "US",
            requestOption: .both
        )
    }
    
    /// Debug method to print validation results in a readable format
    /// - Parameter response: The XAVResponse to format
    /// - Returns: Formatted string representation
    public static func formatValidationResult(_ response: XAVResponse) -> String {
        var result = "=== UPS Address Validation Result ===\n"
        
        if response.isValid {
            result += "✅ Address is VALID\n"
        } else if response.isAmbiguous {
            result += "⚠️ Address is AMBIGUOUS\n"
        } else if response.hasNoCandidates {
            result += "❌ No candidates found\n"
        } else {
            result += "❓ Unknown validation status\n"
        }
        
        if let candidates = response.candidate {
            result += "\nCandidates (\(candidates.count)):\n"
            for (index, candidate) in candidates.enumerated() {
                result += "\n--- Candidate \(index + 1) ---\n"
                
                if let address = candidate.addressKeyFormat {
                    result += "Address: \(address.formattedAddress)\n"
                }
                
                if let classification = candidate.addressClassification {
                    result += "Classification: \(classification.description ?? "Unknown") (Code: \(classification.code ?? "N/A"))\n"
                }
            }
        }
        
        return result
    }
}
#endif
