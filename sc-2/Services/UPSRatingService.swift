//
//  UPSRatingService.swift
//  sc-2
//
//  Created by Assistant on 8/7/25.
//

import Foundation

/// Service for UPS Rating API operations
@MainActor
class UPSRatingService {
    private let oauthService: UPSOAuthService
    private let httpClient: HTTPClient
    private let config: Config

    init(oauthService: UPSOAuthService? = nil, httpClient: HTTPClient? = nil) throws {
        self.config = try Config()
        self.oauthService = oauthService ?? UPSOAuthService(config: self.config)
        self.httpClient = httpClient ?? HTTPClient()
    }

    /// Rate shop - get rates for all available UPS services
    /// - Parameters:
    ///   - rateRequest: The rate request with shipment details
    ///   - version: API version (default: "v2409")
    /// - Returns: Result containing rate response or UPS error
    func shopRates(
        rateRequest: RateRequest,
        version: String = "v2409"
    ) async -> Result<RateResponse, UPSError> {
        return await performRateRequest(
            rateRequest: rateRequest,
            requestOption: "Shop",
            version: version
        )
    }

    /// Get rate for a specific service
    /// - Parameters:
    ///   - rateRequest: The rate request with shipment details and service
    ///   - version: API version (default: "v2409")
    /// - Returns: Result containing rate response or UPS error
    func getRate(
        rateRequest: RateRequest,
        version: String = "v2409"
    ) async -> Result<RateResponse, UPSError> {
        return await performRateRequest(
            rateRequest: rateRequest,
            requestOption: "Rate",
            version: version
        )
    }

    /// Get rates with time in transit information
    /// - Parameters:
    ///   - rateRequest: The rate request with shipment details
    ///   - version: API version (default: "v2409")
    /// - Returns: Result containing rate response with transit times or UPS error
    func shopRatesWithTransit(
        rateRequest: RateRequest,
        version: String = "v2409"
    ) async -> Result<RateResponse, UPSError> {
        return await performRateRequest(
            rateRequest: rateRequest,
            requestOption: "Shoptimeintransit",
            version: version
        )
    }

    // MARK: - Private Methods

    private func performRateRequest(
        rateRequest: RateRequest,
        requestOption: String,
        version: String
    ) async -> Result<RateResponse, UPSError> {
        do {
            // Prepare request wrapper
            let requestWrapper = RATERequestWrapper(RateRequest: rateRequest)

            // Build URL - following the same pattern as AddressValidationService
            let baseURL =
                config.apiBaseURL.hasSuffix("/")
                ? String(config.apiBaseURL.dropLast()) : config.apiBaseURL
            let endpoint = "\(baseURL)/api/rating/\(version)/\(requestOption)"
            guard let url = URL(string: endpoint) else {
                return .failure(.invalidURL(endpoint))
            }

            // Prepare headers
            let transactionId = String(UUID().uuidString.prefix(32))
            let headers = [
                "Content-Type": "application/json",
                "Accept": "application/json",
                "transId": transactionId,
                "transactionSrc": "iOSDemo",
            ]

            // Make authenticated request
            let (data, _) = try await oauthService.authenticatedJSONRequest(
                url: url,
                method: .POST,
                headers: headers,
                json: requestWrapper
            )

            return parseRateResponse(data: data)

        } catch {
            return .failure(
                .configurationError("Failed to initialize request: \(error.localizedDescription)"))
        }
    }

    private func parseRateResponse(data: Data) -> Result<RateResponse, UPSError> {
        do {
            // Try to decode as successful response
            let wrapper = try JSONDecoder().decode(RATEResponseWrapper.self, from: data)
            return .success(wrapper.RateResponse)

        } catch {
            // Check if it's a UPS error response
            if let upsError = parseUPSError(data: data) {
                return .failure(upsError)
            }

            // Generic parsing error
            return .failure(.decodingError(error))
        }
    }

    private func parseUPSError(data: Data) -> UPSError? {
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                let response = json["response"] as? [String: Any],
                let errors = response["errors"] as? [[String: Any]]
            {

                for errorDict in errors {
                    if let code = errorDict["code"] as? String,
                        let message = errorDict["message"] as? String
                    {

                        // Map specific rating error codes
                        switch code {
                        case "120001":
                            return .invalidResponse("Invalid ship to address: \(message)")
                        case "120002":
                            return .invalidResponse("Invalid ship from address: \(message)")
                        case "111057":
                            return .invalidResponse("Invalid package dimensions: \(message)")
                        case "111058":
                            return .invalidResponse("Invalid package weight: \(message)")
                        case "111500":
                            return .serviceUnavailable
                        default:
                            return .invalidResponse("\(code): \(message)")
                        }
                    }
                }
            }
            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - Convenience Methods

extension UPSRatingService {
    /// Quick rate shop with basic shipment info
    func quickShop(
        fromZip: String,
        fromState: String,
        fromCountry: String = "US",
        toZip: String,
        toState: String,
        toCountry: String = "US",
        weightLbs: Double,
        length: Double,
        width: Double,
        height: Double,
        isResidential: Bool = false
    ) async -> Result<RateResponse, UPSError> {

        let request = RateRequest(
            Request: RateRequestInfo(
                SubVersion: "2409",
                TransactionReference: RateTransactionReference(
                    CustomerContext: "Quick Shop Request"
                )
            ),
            Shipment: RateShipment(
                Shipper: RateAddress(
                    Name: "Shipper",
                    ShipperNumber: config.accountNumber,
                    Address: AddressInfo(
                        AddressLine: ["123 Main St"],
                        City: "City",
                        StateProvinceCode: fromState,
                        PostalCode: fromZip,
                        CountryCode: fromCountry,
                        ResidentialAddressIndicator: nil
                    )
                ),
                ShipTo: RateAddress(
                    Name: "Customer",
                    ShipperNumber: nil,
                    Address: AddressInfo(
                        AddressLine: ["456 Oak Ave"],
                        City: "City",
                        StateProvinceCode: toState,
                        PostalCode: toZip,
                        CountryCode: toCountry,
                        ResidentialAddressIndicator: isResidential ? "Y" : nil
                    )
                ),
                ShipFrom: RateAddress(
                    Name: "Shipper",
                    ShipperNumber: config.accountNumber,
                    Address: AddressInfo(
                        AddressLine: ["123 Main St"],
                        City: "City",
                        StateProvinceCode: fromState,
                        PostalCode: fromZip,
                        CountryCode: fromCountry,
                        ResidentialAddressIndicator: nil
                    )
                ),
                PaymentDetails: PaymentDetails(
                    ShipmentCharge: [
                        ShipmentCharge(
                            Type: "01",
                            BillShipper: BillShipper(AccountNumber: config.accountNumber ?? "")
                        )
                    ]
                ),
                Service: nil,  // Omit for shop request
                NumOfPieces: "1",
                Package: RatePackage(
                    PackagingType: PackagingType(
                        Code: "02",
                        Description: "Customer Supplied Package"
                    ),
                    Dimensions: Dimensions(
                        UnitOfMeasurement: UnitOfMeasurement(
                            Code: "IN",
                            Description: "Inches"
                        ),
                        Length: String(format: "%.1f", length),
                        Width: String(format: "%.1f", width),
                        Height: String(format: "%.1f", height)
                    ),
                    PackageWeight: PackageWeight(
                        UnitOfMeasurement: UnitOfMeasurement(
                            Code: "LBS",
                            Description: "Pounds"
                        ),
                        Weight: String(format: "%.1f", weightLbs)
                    )
                )
            )
        )

        return await shopRates(rateRequest: request)
    }
}

// MARK: - Debug Helpers

#if DEBUG
    extension UPSRatingService {
        /// Print rate response for debugging
        func debugPrintResponse(_ response: RateResponse) {
            print("UPS Rate Response: \(response.RatedShipment.count) service(s) available")
            for (index, ratedShipment) in response.RatedShipment.enumerated() {
                let deliveryInfo = ratedShipment.deliveryEstimate.map { " (\($0))" } ?? ""
                print(
                    "  \(index + 1). \(ratedShipment.serviceName): \(ratedShipment.formattedPrice)\(deliveryInfo)"
                )
            }
        }
    }
#endif
