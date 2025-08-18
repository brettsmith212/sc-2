//
//  SaveAddressSheet.swift
//  sc-2
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI

struct SaveAddressSheet: View {
    let candidate: AddressCandidate
    @Environment(\.dismiss) private var dismiss
    @StateObject private var convexService = ConvexService.shared
    
    @State private var label: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    IconTitle(
                        systemName: "plus.circle.fill",
                        title: "Save Address",
                        subtitle: "Add to your address book"
                    )
                    .padding(.top, 8)
                    
                    // Validated Address (Read-only)
                    if let address = candidate.addressKeyFormat {
                        ResultCard(title: "Validated Address", subtitle: "From UPS") {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.formattedAddress)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.text)
                                
                                if let classification = candidate.addressClassification {
                                    HStack(spacing: 6) {
                                        Image(systemName: "tag.fill")
                                            .font(.caption2)
                                            .foregroundColor(Theme.Colors.secondaryText)
                                        Text(classification.description)
                                            .font(Theme.Typography.caption)
                                            .foregroundColor(Theme.Colors.secondaryText)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Address Label and Contact Info
                    ResultCard(title: "Address Details", subtitle: "Required") {
                        VStack(spacing: 12) {
                            LabeledField(
                                title: "Label", 
                                placeholder: "Home, Work, etc.",
                                text: $label
                            )
                            
                            LabeledField(
                                title: "Name", 
                                placeholder: "John Doe",
                                text: $name
                            )
                        }
                    }
                    
                    // Optional Contact Info
                    ResultCard(title: "Contact Info", subtitle: "Optional") {
                        VStack(spacing: 12) {
                            LabeledField(
                                title: "Phone", 
                                placeholder: "(555) 123-4567",
                                text: $phone,
                                keyboard: .phonePad
                            )
                            
                            LabeledField(
                                title: "Email", 
                                placeholder: "john@example.com",
                                text: $email,
                                keyboard: .emailAddress
                            )
                        }
                    }
                    
                    // Error Display
                    if let saveError = saveError {
                        ResultCard(title: "Save Failed", subtitle: nil) {
                            Text(saveError)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.warning)
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button { fillSampleData() } label: {
                            Label("Use Sample Contact", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(TonalButtonStyle())
                        
                        Button(action: saveAddress) {
                            HStack {
                                if isSaving { ProgressView().scaleEffect(0.9) }
                                Text(isSaving ? "Saving..." : "Save to Address Book")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledButtonStyle())
                        .disabled(isSaving || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.6)
                    }
                }
                .padding(16)
            }
            .background(Theme.Colors.bg.ignoresSafeArea())
            .navigationTitle("Save Address")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Address Saved!", isPresented: $showingSuccess) {
            Button("OK") { dismiss() }
        } message: {
            Text("Address has been added to your address book.")
        }
        .onAppear {
            // Pre-fill with smart defaults
            if label.isEmpty {
                label = suggestLabel()
            }
        }
    }
    
    private var isFormValid: Bool {
        !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func suggestLabel() -> String {
        // Smart label suggestions based on address
        guard let address = candidate.addressKeyFormat else { return "" }
        
        let addressText = address.formattedAddress.lowercased()
        
        if addressText.contains("office") || addressText.contains("suite") || addressText.contains("floor") {
            return "Work"
        } else if addressText.contains("home") || addressText.contains("house") {
            return "Home"
        } else {
            return ""
        }
    }
    
    private func fillSampleData() {
        name = "John Doe"
        phone = "(555) 123-4567"
        email = "john@example.com"
        if label.isEmpty {
            label = "Home"
        }
        Haptics.tap()
    }
    
    private func saveAddress() {
        guard let createRequest = candidate.toCreateAddressRequest(
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            phone: phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : phone.trimmingCharacters(in: .whitespacesAndNewlines),
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
        ) else {
            saveError = "Failed to prepare address data"
            return
        }
        
        isSaving = true
        saveError = nil
        
        Task {
            do {
                let _ = try await convexService.saveAddress(request: createRequest)
                
                await MainActor.run {
                    isSaving = false
                    showingSuccess = true
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Failed to save address: \(error.localizedDescription)"
                    Haptics.error()
                }
            }
        }
    }
}

#Preview {
    // Create a mock candidate for preview
    let mockAddress = ResponseAddressKeyFormat(
        consigneeName: nil,
        addressLine: ["1600 Amphitheatre Parkway"],
        region: nil,
        politicalDivision2: "Mountain View",
        politicalDivision1: "CA", 
        postcodePrimaryLow: "94043",
        postcodeExtendedLow: nil,
        countryCode: "US"
    )
    
    let mockCandidate = AddressCandidate(
        addressKeyFormat: mockAddress,
        addressClassification: nil
    )
    
    SaveAddressSheet(candidate: mockCandidate)
}
