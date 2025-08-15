import Foundation
import SwiftUI

struct AddressValidationView: View {
    @Environment(\.dismiss) private var dismiss
    // State
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

    // Service
    @StateObject private var validationService = UPSAddressValidationService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    IconTitle(
                        systemName: "location.circle.fill",
                        title: "Address Validation",
                        subtitle: "Verify and normalize addresses"
                    )
                    .padding(.top, 8)

                    // Form
                    ResultCard(title: "Address Details", subtitle: nil) {
                        VStack(spacing: 12) {
                            LabeledField(
                                title: "Street", placeholder: "1600 Amphitheatre Parkway",
                                text: $street)
                            HStack(spacing: 12) {
                                LabeledField(
                                    title: "City", placeholder: "Mountain View", text: $city)
                                LabeledField(
                                    title: "State", placeholder: "CA", text: $state,
                                    textCase: .characters
                                )
                                .frame(width: 100)
                            }
                            HStack(spacing: 12) {
                                LabeledField(
                                    title: "ZIP Code", placeholder: "94043", text: $postalCode,
                                    keyboard: .numbersAndPunctuation)
                                LabeledField(
                                    title: "Country", placeholder: "US", text: $countryCode,
                                    textCase: .characters
                                )
                                .frame(width: 100)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button("Use Sample") { fillSampleAddress() }
                            .buttonStyle(GhostButtonStyle())

                        Button(action: validateAddress) {
                            HStack {
                                if isValidating { ProgressView().scaleEffect(0.9) }
                                Text(isValidating ? "Validating..." : "Validate Address")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledButtonStyle())
                        .disabled(isValidating || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                    }

                    // Results
                    if showingResult {
                        if let error = validationError {
                            ResultCard(title: "Validation Failed", subtitle: nil) {
                                Text(UPSAddressValidationService.userFriendlyMessage(for: error))
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.secondaryText)
                            }
                        } else if let response = validationResponse {
                            ResultCard(title: statusText(for: response), subtitle: nil) {
                                if let candidates = response.candidate, !candidates.isEmpty {
                                    VStack(spacing: 8) {
                                        ForEach(Array(candidates.enumerated()), id: \.offset) {
                                            _, candidate in
                                            if let address = candidate.addressKeyFormat {
                                                HStack(alignment: .firstTextBaseline) {
                                                    Image(systemName: "location.fill")
                                                        .foregroundColor(Theme.Colors.primary)
                                                    Text(address.formattedAddress)
                                                        .font(Theme.Typography.body)
                                                        .foregroundColor(Theme.Colors.text)
                                                    Spacer()
                                                }
                                                if let classification = candidate
                                                    .addressClassification
                                                {
                                                    HStack(spacing: 6) {
                                                        Image(systemName: "tag.fill").font(
                                                            .caption2
                                                        ).foregroundColor(
                                                            Theme.Colors.secondaryText)
                                                        Text(classification.description)
                                                            .font(Theme.Typography.caption)
                                                            .foregroundColor(
                                                                Theme.Colors.secondaryText)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    Text("No address found for the provided input.")
                                        .font(Theme.Typography.body)
                                        .foregroundColor(Theme.Colors.secondaryText)
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.Colors.bg.ignoresSafeArea())
            .navigationTitle("UPS Address Validation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
        }
    }

    private var isFormValid: Bool {
        !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !state.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !postalCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !countryCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                    validationError = nil
                case .failure(let error):
                    validationError = error
                    validationResponse = nil
                }
                withAnimation { showingResult = true }
            }
        }
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
}

#Preview { AddressValidationView() }
