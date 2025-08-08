//
//  RateCalculationView.swift
//  sc-2
//
//  Created by Assistant on 8/7/25.
//

import SwiftUI

struct RateCalculationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ratingService: UPSRatingService?
    
    // Form fields - From address
    @State private var fromStreet = ""
    @State private var fromCity = ""
    @State private var fromState = ""
    @State private var fromZip = ""
    @State private var fromCountry = "US"
    
    // Form fields - To address
    @State private var toStreet = ""
    @State private var toCity = ""
    @State private var toState = ""
    @State private var toZip = ""
    @State private var toCountry = "US"
    @State private var isResidential = false
    
    // Package details
    @State private var weight = ""
    @State private var length = ""
    @State private var width = ""
    @State private var height = ""
    
    // State management
    @State private var isLoading = false
    @State private var rateResponse: RateResponse?
    @State private var errorMessage: String?
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("From Address") {
                    TextField("Street Address", text: $fromStreet)
                    TextField("City", text: $fromCity)
                    HStack {
                        TextField("State", text: $fromState)
                            .textInputAutocapitalization(.characters)
                        TextField("ZIP", text: $fromZip)
                    }
                    Picker("Country", selection: $fromCountry) {
                        Text("United States").tag("US")
                        Text("Canada").tag("CA")
                    }
                }
                
                Section("To Address") {
                    TextField("Street Address", text: $toStreet)
                    TextField("City", text: $toCity)
                    HStack {
                        TextField("State", text: $toState)
                            .textInputAutocapitalization(.characters)
                        TextField("ZIP", text: $toZip)
                    }
                    Picker("Country", selection: $toCountry) {
                        Text("United States").tag("US")
                        Text("Canada").tag("CA")
                    }
                    Toggle("Residential Address", isOn: $isResidential)
                }
                
                Section("Package Details") {
                    HStack {
                        Text("Weight (lbs)")
                        Spacer()
                        TextField("0.0", text: $weight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Length (in)")
                        Spacer()
                        TextField("0.0", text: $length)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Width (in)")
                        Spacer()
                        TextField("0.0", text: $width)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Height (in)")
                        Spacer()
                        TextField("0.0", text: $height)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button("Use Sample Data") {
                        fillSampleData()
                    }
                    .foregroundColor(.blue)
                    
                    Button(action: calculateRates) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "dollarsign.circle")
                            }
                            Text("Calculate Rates")
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                    .foregroundColor(isFormValid ? .primary : .secondary)
                }
                
                // Results section
                if showingResults {
                    Section("Rate Results") {
                        if let response = rateResponse {
                            rateResultsView(response: response)
                        } else if let error = errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Rate Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                initializeService()
            }
        }
    }
    
    @ViewBuilder
    private func rateResultsView(response: RateResponse) -> some View {
        if response.RatedShipment.isEmpty {
            Label("No rates available for this route", systemImage: "info.circle")
                .foregroundColor(.orange)
        } else {
            ForEach(response.RatedShipment.indices, id: \.self) { index in
                let ratedShipment = response.RatedShipment[index]
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(ratedShipment.serviceName)
                            .font(.headline)
                        Spacer()
                        Text(ratedShipment.formattedPrice)
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                    
                    if let estimate = ratedShipment.deliveryEstimate {
                        Text(estimate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let negotiated = ratedShipment.NegotiatedRateCharges {
                        Text("Negotiated: \(negotiated.TotalCharge.CurrencyCode) \(negotiated.TotalCharge.MonetaryValue)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    private var isFormValid: Bool {
        !fromZip.isEmpty && !fromState.isEmpty &&
        !toZip.isEmpty && !toState.isEmpty &&
        !weight.isEmpty && !length.isEmpty && !width.isEmpty && !height.isEmpty &&
        Double(weight) != nil && Double(length) != nil && 
        Double(width) != nil && Double(height) != nil
    }
    
    private func initializeService() {
        do {
            ratingService = try UPSRatingService()
        } catch {
            errorMessage = "Failed to initialize rating service: \(error.localizedDescription)"
            showingResults = true
        }
    }
    
    private func fillSampleData() {
        // From address (Timonium, MD)
        fromStreet = "123 Main Street"
        fromCity = "TIMONIUM"
        fromState = "MD"
        fromZip = "21093"
        fromCountry = "US"
        
        // To address (Alpharetta, GA)
        toStreet = "456 Oak Avenue"
        toCity = "Alpharetta"
        toState = "GA"
        toZip = "30005"
        toCountry = "US"
        isResidential = true
        
        // Package details
        weight = "2.5"
        length = "10"
        width = "8"
        height = "6"
    }
    
    private func calculateRates() {
        guard let service = ratingService,
              let weightVal = Double(weight),
              let lengthVal = Double(length),
              let widthVal = Double(width),
              let heightVal = Double(height) else {
            errorMessage = "Invalid input values"
            showingResults = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        rateResponse = nil
        showingResults = true
        
        Task {
            let result = await service.quickShop(
                fromZip: fromZip,
                fromState: fromState,
                fromCountry: fromCountry,
                toZip: toZip,
                toState: toState,
                toCountry: toCountry,
                weightLbs: weightVal,
                length: lengthVal,
                width: widthVal,
                height: heightVal,
                isResidential: isResidential
            )
            
            await MainActor.run {
                isLoading = false
                
                switch result {
                case .success(let response):
                    rateResponse = response
                    errorMessage = nil
                    
                    #if DEBUG
                    service.debugPrintResponse(response)
                    #endif
                    
                case .failure(let error):
                    rateResponse = nil
                    errorMessage = formatErrorMessage(error)
                }
            }
        }
    }
    
    private func formatErrorMessage(_ error: UPSError) -> String {
        switch error {
        case .invalidResponse(let message):
            return "API Error: \(message)"
        case .serviceUnavailable:
            return "Service unavailable for this route"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .decodingError(let error):
            return "Response parsing error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        default:
            return "Rate calculation failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    RateCalculationView()
}
