//
//  AddressBookView.swift
//  sc-2
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI

struct AddressBookView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var convexService = ConvexService.shared
    
    @State private var addresses: [SavedAddress] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddressValidation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    IconTitle(
                        systemName: "book.circle.fill",
                        title: "Address Book",
                        subtitle: "Your saved addresses"
                    )
                    .padding(.top, 8)
                    
                    if isLoading {
                        ProgressView("Loading addresses...")
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if let errorMessage = errorMessage {
                        ResultCard(title: "Error", subtitle: nil) {
                            Text(errorMessage)
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.warning)
                        }
                    } else if addresses.isEmpty {
                        ResultCard(title: "No Addresses", subtitle: nil) {
                            VStack(spacing: 12) {
                                Image(systemName: "location.slash")
                                    .font(.largeTitle)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                
                                Text("You haven't saved any addresses yet.")
                                    .font(Theme.Typography.body)
                                    .foregroundColor(Theme.Colors.secondaryText)
                                    .multilineTextAlignment(.center)
                                
                                Button {
                                    showingAddressValidation = true
                                } label: {
                                    Label("Add First Address", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(FilledButtonStyle())
                            }
                        }
                    } else {
                        // Address List
                        ResultCard(title: "Saved Addresses", subtitle: "\(addresses.count) address\(addresses.count == 1 ? "" : "es")") {
                            VStack(spacing: 0) {
                                ForEach(Array(addresses.enumerated()), id: \.element.id) { index, address in
                                    AddressRowView(address: address)
                                    
                                    if index < addresses.count - 1 {
                                        Divider()
                                            .padding(.horizontal, -16)
                                    }
                                }
                            }
                        }
                        
                        // Add New Address Button
                        Button {
                            showingAddressValidation = true
                        } label: {
                            Label("Add New Address", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(TonalButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(Theme.Colors.bg.ignoresSafeArea())
            .navigationTitle("Address Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                if !addresses.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showingAddressValidation = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .refreshable {
                await loadAddresses()
            }
        }
        .task {
            await loadAddresses()
        }
        .sheet(isPresented: $showingAddressValidation) {
            AddressValidationView()
        }
    }
    
    private func loadAddresses() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let loadedAddresses = try await convexService.listAddresses(validatedOnly: true)
            await MainActor.run {
                addresses = loadedAddresses
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load addresses: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
}

struct AddressRowView: View {
    let address: SavedAddress
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Address Icon
            Image(systemName: address.validated ? "checkmark.circle.fill" : "location.circle")
                .foregroundColor(address.validated ? .green : Theme.Colors.secondaryText)
                .font(.title2)
            
            // Address Content
            VStack(alignment: .leading, spacing: 4) {
                // Label and Name
                HStack {
                    Text(address.label)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    
                    Spacer()
                    
                    Text(address.name)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                // Address
                Text(address.formattedAddress)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.text)
                    .lineLimit(nil)
                
                // Contact Info
                if let phone = address.phone, !phone.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text(phone)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                
                if let email = address.email, !email.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "envelope.fill")
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        Text(email)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    AddressBookView()
}
