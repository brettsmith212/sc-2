//
//  UPSRatingModels.swift
//  sc-2
//
//  Created by Assistant on 8/7/25.
//

import Foundation

// MARK: - Request Models

struct RATERequestWrapper: Codable {
    let RateRequest: RateRequest
}

struct RateRequest: Codable {
    let Request: RateRequestInfo
    let Shipment: RateShipment
}

struct RateRequestInfo: Codable {
    let SubVersion: String?
    let TransactionReference: RateTransactionReference?
}

struct RateTransactionReference: Codable {
    let CustomerContext: String?
}

struct RateShipment: Codable {
    let Shipper: RateAddress
    let ShipTo: RateAddress
    let ShipFrom: RateAddress
    let PaymentDetails: PaymentDetails?
    let Service: ServiceInfo?
    let NumOfPieces: String?
    let Package: RatePackage
}

struct RateAddress: Codable {
    let Name: String?
    let ShipperNumber: String?
    let Address: AddressInfo
}

struct AddressInfo: Codable {
    let AddressLine: [String]?
    let City: String
    let StateProvinceCode: String
    let PostalCode: String
    let CountryCode: String
    let ResidentialAddressIndicator: String?
}

struct PaymentDetails: Codable {
    let ShipmentCharge: [ShipmentCharge]
}

struct ShipmentCharge: Codable {
    let `Type`: String
    let BillShipper: BillShipper?
}

struct BillShipper: Codable {
    let AccountNumber: String
}

struct ServiceInfo: Codable {
    let Code: String
    let Description: String?
    
    var serviceName: String {
        switch Code {
        case "01": return "UPS Next Day Air"
        case "02": return "UPS 2nd Day Air"
        case "03": return "UPS Ground"
        case "12": return "UPS 3 Day Select"
        case "13": return "UPS Next Day Air Saver"
        case "14": return "UPS Next Day Air Early"
        case "54": return "UPS Worldwide Express Plus"
        case "65": return "UPS Worldwide Saver"
        default: return "UPS Service \(Code)"
        }
    }
}

struct RatePackage: Codable {
    let PackagingType: PackagingType
    let Dimensions: Dimensions
    let PackageWeight: PackageWeight
}

struct PackagingType: Codable {
    let Code: String
    let Description: String?
}

struct Dimensions: Codable {
    let UnitOfMeasurement: UnitOfMeasurement
    let Length: String
    let Width: String
    let Height: String
}

struct UnitOfMeasurement: Codable {
    let Code: String
    let Description: String?
}

struct PackageWeight: Codable {
    let UnitOfMeasurement: UnitOfMeasurement
    let Weight: String
}

// MARK: - Response Models

struct RATEResponseWrapper: Codable {
    let RateResponse: RateResponse
}

struct RateResponse: Codable {
    let Response: RateResponseInfo
    let RatedShipment: [RatedShipment]
}

struct RateResponseInfo: Codable {
    let ResponseStatus: RateResponseStatus
    let Alert: [Alert]?
    let TransactionReference: RateTransactionReference?
}

struct RateResponseStatus: Codable {
    let Code: String
    let Description: String
}

struct Alert: Codable {
    let Code: String
    let Description: String
}

struct RatedShipment: Codable {
    let Disclaimer: [Disclaimer]?
    let Service: ServiceInfo
    let RateChart: String?
    let RatedShipmentAlert: [RatedShipmentAlert]?
    let BillableWeight: BillableWeight?
    let BillingWeight: BillableWeight?
    let Zone: String?
    let TransportationCharges: Charges?
    let BaseServiceCharge: Charges?
    let ItemizedCharges: [ItemizedCharge]?
    let ServiceOptionsCharges: Charges?
    let TaxCharges: [TaxCharge]?
    let TotalCharges: Charges
    let TotalChargesWithTaxes: Charges?
    let NegotiatedRateCharges: NegotiatedRateCharges?
    let RatedPackage: [RatedPackage]?
    let TimeInTransit: TimeInTransit?
    let GuaranteedDelivery: GuaranteedDelivery?
}

struct GuaranteedDelivery: Codable {
    let BusinessDaysInTransit: String?
    let DeliveryByTime: String?
}

struct Disclaimer: Codable {
    let Code: String
    let Description: String
}

struct RatedShipmentAlert: Codable {
    let Code: String
    let Description: String
}

struct BillableWeight: Codable {
    let UnitOfMeasurement: UnitOfMeasurement
    let Weight: String
}

struct Charges: Codable {
    let CurrencyCode: String
    let MonetaryValue: String
}

struct ItemizedCharge: Codable {
    let Code: String
    let Description: String?
    let CurrencyCode: String
    let MonetaryValue: String
}

struct TaxCharge: Codable {
    let `Type`: String
    let MonetaryValue: String
}

struct NegotiatedRateCharges: Codable {
    let ItemizedCharges: [ItemizedCharge]?
    let TaxCharges: [TaxCharge]?
    let TotalCharge: Charges
    let TotalChargesWithTaxes: Charges?
}

struct RatedPackage: Codable {
    let TransportationCharges: Charges?
    let BaseServiceCharge: Charges?
    let ServiceOptionsCharges: Charges?
    let ItemizedCharges: [ItemizedCharge]?
    let TotalCharges: Charges
    let Weight: String?
    let BillingWeight: BillableWeight?
}

struct TimeInTransit: Codable {
    let ServiceSummary: ServiceSummary?
    let PickupDate: String?
    let DocumentsOnlyIndicator: String?
}

struct ServiceSummary: Codable {
    let Service: ServiceInfo
    let EstimatedArrival: EstimatedArrival?
    let Disclaimer: String?
}

struct EstimatedArrival: Codable {
    let Arrival: ArrivalInfo?
    let BusinessDaysInTransit: String?
    let Pickup: PickupInfo?
    let DayOfWeek: String?
    let CustomerCenterCutoff: String?
    let RestDays: String?
    let TotalTransitDays: String?
}

struct ArrivalInfo: Codable {
    let Date: String?
    let Time: String?
}

struct PickupInfo: Codable {
    let Date: String?
    let Time: String?
}

// MARK: - Helper Extensions

extension RatedShipment {
    /// Get the display name for the service
    var serviceName: String {
        return Service.serviceName
    }
    
    /// Get the formatted price string
    var formattedPrice: String {
        let value = TotalCharges.MonetaryValue
        let currency = TotalCharges.CurrencyCode
        
        if let doubleValue = Double(value) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            return formatter.string(from: NSNumber(value: doubleValue)) ?? "\(currency) \(value)"
        }
        return "\(currency) \(value)"
    }
    
    /// Get delivery time estimate if available
    var deliveryEstimate: String? {
        if let guaranteed = GuaranteedDelivery {
            var estimate = ""
            
            if let businessDays = guaranteed.BusinessDaysInTransit {
                estimate += "\(businessDays) business day\(businessDays == "1" ? "" : "s")"
            }
            
            if let deliveryTime = guaranteed.DeliveryByTime {
                if !estimate.isEmpty {
                    estimate += " by \(deliveryTime)"
                } else {
                    estimate = "By \(deliveryTime)"
                }
            }
            
            return estimate.isEmpty ? nil : estimate
        }
        
        // Fallback to TimeInTransit if GuaranteedDelivery is not available
        guard let timeInTransit = TimeInTransit,
              let serviceSummary = timeInTransit.ServiceSummary,
              let estimatedArrival = serviceSummary.EstimatedArrival else {
            return nil
        }
        
        if let businessDays = estimatedArrival.BusinessDaysInTransit {
            return "\(businessDays) business day\(businessDays == "1" ? "" : "s")"
        }
        
        if let arrivalDate = estimatedArrival.Arrival?.Date {
            return "Arrives \(arrivalDate)"
        }
        
        return nil
    }
}

// MARK: - Sample Data

extension RateRequest {
    static func sampleRequest() -> RateRequest {
        return RateRequest(
            Request: RateRequestInfo(
                SubVersion: "2409",
                TransactionReference: RateTransactionReference(
                    CustomerContext: "Rate Request Sample"
                )
            ),
            Shipment: RateShipment(
                Shipper: RateAddress(
                    Name: "ACME Corporation",
                    ShipperNumber: nil,
                    Address: AddressInfo(
                        AddressLine: ["123 Main Street"],
                        City: "TIMONIUM",
                        StateProvinceCode: "MD",
                        PostalCode: "21093",
                        CountryCode: "US",
                        ResidentialAddressIndicator: nil
                    )
                ),
                ShipTo: RateAddress(
                    Name: "Customer Name",
                    ShipperNumber: nil,
                    Address: AddressInfo(
                        AddressLine: ["456 Oak Avenue"],
                        City: "Alpharetta",
                        StateProvinceCode: "GA",
                        PostalCode: "30005",
                        CountryCode: "US",
                        ResidentialAddressIndicator: "Y"
                    )
                ),
                ShipFrom: RateAddress(
                    Name: "ACME Warehouse",
                    ShipperNumber: nil,
                    Address: AddressInfo(
                        AddressLine: ["123 Main Street"],
                        City: "TIMONIUM",
                        StateProvinceCode: "MD",
                        PostalCode: "21093",
                        CountryCode: "US",
                        ResidentialAddressIndicator: nil
                    )
                ),
                PaymentDetails: PaymentDetails(
                    ShipmentCharge: [
                        ShipmentCharge(
                            Type: "01",
                            BillShipper: BillShipper(AccountNumber: "")
                        )
                    ]
                ),
                Service: nil, // For shop request, omit service to get all options
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
                        Length: "10",
                        Width: "8",
                        Height: "6"
                    ),
                    PackageWeight: PackageWeight(
                        UnitOfMeasurement: UnitOfMeasurement(
                            Code: "LBS",
                            Description: "Pounds"
                        ),
                        Weight: "2.5"
                    )
                )
            )
        )
    }
}
