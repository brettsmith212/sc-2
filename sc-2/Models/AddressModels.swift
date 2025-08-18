//
//  AddressModels.swift
//  sc-2
//
//  Created by Assistant on 8/17/25.
//

import Foundation

/// Saved address from the address book (mirrors Convex addresses table)
struct SavedAddress: Identifiable, Codable {
    let id: String
    let label: String
    let name: String
    let phone: String?
    let email: String?
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let validated: Bool
    let creationTime: Double
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case label
        case name
        case phone
        case email
        case line1
        case line2
        case city
        case state
        case postalCode = "postal_code"
        case country
        case validated
        case creationTime = "_creationTime"
    }
    
    /// Formatted address for display
    var formattedAddress: String {
        var components = [line1]
        if let line2 = line2, !line2.isEmpty {
            components.append(line2)
        }
        components.append("\(city), \(state) \(postalCode)")
        if country != "US" {
            components.append(country)
        }
        return components.joined(separator: "\n")
    }
    
    /// Short format for list display
    var shortAddress: String {
        return "\(city), \(state) \(postalCode)"
    }
}

/// Data for creating a new address in Convex
struct CreateAddressRequest {
    let label: String
    let name: String
    let phone: String?
    let email: String?
    let line1: String
    let line2: String?
    let city: String
    let state: String
    let postalCode: String
    let country: String
    let validationMeta: [String: Any]?
}

/// Extension to convert UPS validation candidates to SavedAddress format
extension AddressCandidate {
    /// Converts UPS candidate to SavedAddress format for saving
    func toCreateAddressRequest(label: String, name: String, phone: String? = nil, email: String? = nil) -> CreateAddressRequest? {
        guard let address = self.addressKeyFormat else { return nil }
        
        return CreateAddressRequest(
            label: label,
            name: name,
            phone: phone,
            email: email,
            line1: address.addressLine?.first ?? "",
            line2: address.addressLine?.count ?? 0 > 1 ? address.addressLine?[1] : nil,
            city: address.politicalDivision2 ?? "",
            state: address.politicalDivision1 ?? "", 
            postalCode: address.postcodePrimaryLow ?? "",
            country: address.countryCode ?? "US",
            validationMeta: nil // We could store the full candidate JSON here if needed
        )
    }
}
