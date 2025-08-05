import SwiftUI
import Foundation

struct AddressValidationView: View {
    
    // MARK: - State Properties
    
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""
    @State private var countryCode: String = "US"
    @State private var requestOption: UPSRequestOption = .both
    
    @State private var isValidating: Bool = false
    @State private var validationResponse: XAVResponse?
    @State private var validationError: UPSError?
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
                    inputField("Country", text: $countryCode, placeholder: "US")
                        .frame(maxWidth: 80)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Validation Results")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button("Dismiss") {
                    withAnimation {
                        showingResult = false
                        validationResponse = nil
                        validationError = nil
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            
            // Content with proper scrolling
            if let error = validationError {
                errorResultView(error)
            } else if let response = validationResponse {
                successResultView(response)
            }
        }
        .background(Color(UIColor.systemBackground))
        .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
        .clipped()
    }
    
    private func errorResultView(_ error: UPSError) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text("Validation Failed")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Error Details")
                        .font(.headline)
                    Text(UPSAddressValidationService.userFriendlyMessage(for: error))
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Add some bottom padding for better scrolling
                Color.clear.frame(height: 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func successResultView(_ response: XAVResponse) -> some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // Status Header
                HStack {
                    statusIcon(for: response)
                    Text(statusText(for: response))
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .padding(.top)
                
                // Address Candidates
                if let candidates = response.candidate, !candidates.isEmpty {
                    addressCandidatesSection(candidates)
                } else {
                    noAddressFoundSection()
                }
                
                // Add some bottom padding for better scrolling
                Color.clear.frame(height: 20)
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statusIcon(for response: XAVResponse) -> some View {
        Group {
            if response.isValid {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if response.isAmbiguous {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .font(.title)
    }
    
    private func statusText(for response: XAVResponse) -> String {
        if response.isValid {
            return "Address Validated"
        } else if response.isAmbiguous {
            return "Similar Addresses Found"
        } else {
            return "Address Not Found"
        }
    }
    
    private func addressCandidatesSection(_ candidates: [AddressCandidate]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(candidates.count == 1 ? "Validated Address" : "Address Suggestions (\(candidates.count))")
                .font(.headline)
            
            ForEach(Array(candidates.enumerated()), id: \.offset) { index, candidate in
                addressCandidateCard(candidate, index: index)
            }
        }
    }
    
    private func addressCandidateCard(_ candidate: AddressCandidate, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let address = candidate.addressKeyFormat {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text(address.formattedAddress)
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                if let classification = candidate.addressClassification {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.secondary)
                            .font(.caption2)
                        Text(classification.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private func noAddressFoundSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No Address Found")
                .font(.headline)
            
            Text("The address you entered could not be validated. Please check the spelling and try again.")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
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
        validationResponse = nil
        validationError = nil
        
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
                    validationResponse = response
                case .failure(let error):
                    validationError = error
                }
                
                withAnimation {
                    showingResult = true
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddressValidationView()
}
