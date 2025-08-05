import Foundation

// MARK: - Request Models

public enum UPSRequestOption: Int, CaseIterable {
    case validation = 1
    case classification = 2
    case both = 3
    
    var path: String {
        return "\(rawValue)"
    }
}

public struct UPSAddress {
    public let street: String
    public let city: String
    public let state: String
    public let postalCode: String
    public let countryCode: String
    
    public init(street: String, city: String, state: String, postalCode: String, countryCode: String) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.countryCode = countryCode
    }
}

public struct UPSAddressValidationRequest {
    public let address: UPSAddress
    public let requestOption: UPSRequestOption
    public let regionalRequestIndicator: String?
    public let maximumCandidateListSize: Int?
    
    public init(address: UPSAddress, requestOption: UPSRequestOption, regionalRequestIndicator: String? = nil, maximumCandidateListSize: Int? = nil) {
        self.address = address
        self.requestOption = requestOption
        self.regionalRequestIndicator = regionalRequestIndicator
        self.maximumCandidateListSize = maximumCandidateListSize
    }
}

// MARK: - UPS API Request Format

struct XAVRequest: Codable {
    let addressKeyFormat: AddressKeyFormat
    
    enum CodingKeys: String, CodingKey {
        case addressKeyFormat = "AddressKeyFormat"
    }
}

struct AddressKeyFormat: Codable {
    let consigneeName: String?
    let addressLine: [String]
    let region: String
    let politicalDivision2: String
    let politicalDivision1: String
    let postcodePrimary: String
    let countryCode: String
    
    enum CodingKeys: String, CodingKey {
        case consigneeName = "ConsigneeName"
        case addressLine = "AddressLine"
        case region = "Region"
        case politicalDivision2 = "PoliticalDivision2"
        case politicalDivision1 = "PoliticalDivision1"
        case postcodePrimary = "PostcodePrimary"
        case countryCode = "CountryCode"
    }
    
    init(from address: UPSAddress) {
        self.consigneeName = nil
        self.addressLine = [address.street]
        self.region = ""
        self.politicalDivision2 = address.city
        self.politicalDivision1 = address.state
        self.postcodePrimary = address.postalCode
        self.countryCode = address.countryCode
    }
}

// MARK: - Response Models

public struct XAVResponse: Codable {
    public let validAddressIndicator: String?
    public let ambiguousAddressIndicator: String?
    public let noCandidatesIndicator: String?
    public let candidate: [AddressCandidate]?
    
    enum CodingKeys: String, CodingKey {
        case validAddressIndicator = "ValidAddressIndicator"
        case ambiguousAddressIndicator = "AmbiguousAddressIndicator"
        case noCandidatesIndicator = "NoCandidatesIndicator"
        case candidate = "Candidate"
    }
}

public struct AddressCandidate: Codable {
    public let addressKeyFormat: ResponseAddressKeyFormat?
    public let addressClassification: AddressClassification?
    
    enum CodingKeys: String, CodingKey {
        case addressKeyFormat = "AddressKeyFormat"
        case addressClassification = "AddressClassification"
    }
}

public struct ResponseAddressKeyFormat: Codable {
    public let consigneeName: String?
    public let addressLine: [String]?
    public let region: String?
    public let politicalDivision2: String?
    public let politicalDivision1: String?
    public let postcodePrimary: String?
    public let postcodeExtended: String?
    public let countryCode: String?
    
    enum CodingKeys: String, CodingKey {
        case consigneeName = "ConsigneeName"
        case addressLine = "AddressLine"
        case region = "Region"
        case politicalDivision2 = "PoliticalDivision2"
        case politicalDivision1 = "PoliticalDivision1"
        case postcodePrimary = "PostcodePrimary"
        case postcodeExtended = "PostcodeExtended"
        case countryCode = "CountryCode"
    }
}

public struct AddressClassification: Codable {
    public let code: String?
    public let description: String?
    
    enum CodingKeys: String, CodingKey {
        case code = "Code"
        case description = "Description"
    }
}



// MARK: - Extensions

extension XAVResponse {
    public var isValid: Bool {
        return validAddressIndicator != nil
    }
    
    public var isAmbiguous: Bool {
        return ambiguousAddressIndicator != nil
    }
    
    public var hasNoCandidates: Bool {
        return noCandidatesIndicator != nil
    }
    
    public var hasResults: Bool {
        return candidate?.isEmpty == false
    }
    
    public var bestCandidate: AddressCandidate? {
        return candidate?.first
    }
}

extension ResponseAddressKeyFormat {
    public var formattedAddress: String {
        var components: [String] = []
        
        if let addressLines = addressLine, !addressLines.isEmpty {
            components.append(contentsOf: addressLines)
        }
        
        var cityStateZip = ""
        if let city = politicalDivision2 {
            cityStateZip += city
        }
        if let state = politicalDivision1 {
            if !cityStateZip.isEmpty { cityStateZip += ", " }
            cityStateZip += state
        }
        if let zip = postcodePrimary {
            if !cityStateZip.isEmpty { cityStateZip += " " }
            cityStateZip += zip
        }
        if let zipExt = postcodeExtended {
            cityStateZip += "-\(zipExt)"
        }
        
        if !cityStateZip.isEmpty {
            components.append(cityStateZip)
        }
        
        if let country = countryCode {
            components.append(country)
        }
        
        return components.joined(separator: "\n")
    }
}
