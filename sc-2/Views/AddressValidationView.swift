import SwiftUI

struct AddressValidationView: View {
    
    // MARK: - State Properties
    
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var countryCode: String = "US"
    @State private var requestOption: UPSRequestOption = .validation
    
    @State private var isValidating: Bool = false
    @State private var validationResult: String = ""
    @State private var showingResult: Bool = false
    
    // MARK: - Service
    
    @StateObject private var validationService = UPSAddressValidationService()
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Input Form
                ScrollView {
                    VStack(spacing: 16) {
                        formSection
                        optionsSection
                        validateButton
                    }
                    .padding()
                }
                
                // Results Section
                if showingResult {
                    Divider()
                    resultSection
                }
            }
            .navigationTitle("UPS Address Validation")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    sampleAddressButton
                }
            }
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Address Details")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                inputField("Street Address", text: $street, placeholder: "1600 Amphitheatre Parkway")
                
                HStack(spacing: 12) {
                    inputField("City", text: $city, placeholder: "Mountain View")
                    inputField("State", text: $state, placeholder: "CA")
                        .frame(maxWidth: 80)
                }
                
                HStack(spacing: 12) {
                    inputField("ZIP Code", text: $postalCode, placeholder: "94043")
                        .keyboardType(.numberPad)
                    inputField("Country", text: $countryCode, placeholder: "US")
                        .frame(maxWidth: 80)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Options Section
    
    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Validation Options")
                .font(.headline)
                .foregroundColor(.primary)
            
            Picker("Request Type", selection: $requestOption) {
                Text("Address Validation").tag(UPSRequestOption.validation)
                Text("Address Classification").tag(UPSRequestOption.classification)
                Text("Both").tag(UPSRequestOption.both)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Validate Button
    
    private var validateButton: some View {
        Button(action: validateAddress) {
            HStack {
                if isValidating {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "checkmark.seal")
                }
                Text(isValidating ? "Validating..." : "Validate Address")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isValidating ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(isValidating || !isFormValid)
    }
    
    // MARK: - Result Section
    
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Validation Result")
                    .font(.headline)
                Spacer()
                Button("Dismiss") {
                    withAnimation {
                        showingResult = false
                        validationResult = ""
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            ScrollView {
                Text(validationResult)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: 300)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Sample Address Button
    
    private var sampleAddressButton: some View {
        Button("Sample") {
            fillSampleAddress()
        }
        .font(.caption)
    }
    
    // MARK: - Helper Methods
    
    private func inputField(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField(placeholder, text: text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
    
    private var isFormValid: Bool {
        !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !countryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func fillSampleAddress() {
        street = "1600 Amphitheatre Parkway"
        city = "Mountain View"
        state = "CA"
        postalCode = "94043"
        countryCode = "US"
        requestOption = .both
    }
    
    private func validateAddress() {
        guard isFormValid else { return }
        
        isValidating = true
        validationResult = ""
        
        Task {
            let result = await validationService.validateAddress(
                street: street.trimmingCharacters(in: .whitespacesAndNewlines),
                city: city.trimmingCharacters(in: .whitespacesAndNewlines),
                state: state.trimmingCharacters(in: .whitespacesAndNewlines),
                postalCode: postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
                countryCode: countryCode.trimmingCharacters(in: .whitespacesAndNewlines),
                requestOption: requestOption
            )
            
            await MainActor.run {
                isValidating = false
                
                switch result {
                case .success(let response):
                    validationResult = formatSuccessResponse(response)
                case .failure(let error):
                    validationResult = formatErrorResponse(error)
                }
                
                withAnimation {
                    showingResult = true
                }
            }
        }
    }
    
    private func formatSuccessResponse(_ response: XAVResponse) -> String {
        var result = "✅ VALIDATION SUCCESS\n\n"
        
        // Status indicators
        if response.isValid {
            result += "🟢 Address is VALID\n"
        } else if response.isAmbiguous {
            result += "🟡 Address is AMBIGUOUS\n"
        } else if response.hasNoCandidates {
            result += "🔴 No candidates found\n"
        } else {
            result += "❓ Unknown validation status\n"
        }
        
        result += "\n"
        
        // Candidates
        if let candidates = response.candidate, !candidates.isEmpty {
            result += "📋 CANDIDATES (\(candidates.count)):\n\n"
            
            for (index, candidate) in candidates.enumerated() {
                result += "--- Candidate \(index + 1) ---\n"
                
                if let address = candidate.addressKeyFormat {
                    result += "📍 Address:\n\(address.formattedAddress)\n\n"
                }
                
                if let classification = candidate.addressClassification {
                    result += "🏷️ Classification: \(classification.description ?? "Unknown")\n"
                    result += "   Code: \(classification.code ?? "N/A")\n\n"
                }
            }
        }
        
        // Raw JSON for debugging
        result += "\n📄 RAW JSON RESPONSE:\n"
        if let jsonData = try? JSONEncoder().encode(response),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            result += formatJSON(jsonString)
        } else {
            result += "Failed to serialize response to JSON"
        }
        
        return result
    }
    
    private func formatErrorResponse(_ error: UPSError) -> String {
        var result = "❌ VALIDATION ERROR\n\n"
        
        result += "🔍 Error Details:\n"
        result += UPSAddressValidationService.userFriendlyMessage(for: error)
        result += "\n\n"
        
        result += "🛠️ Technical Details:\n"
        result += error.localizedDescription
        
        return result
    }
    
    private func formatJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8),
              let jsonObject = try? JSONSerialization.jsonObject(with: data),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted]),
              let prettyString = String(data: prettyData, encoding: .utf8) else {
            return jsonString
        }
        return prettyString
    }
}

// MARK: - Preview

#Preview {
    AddressValidationView()
}
