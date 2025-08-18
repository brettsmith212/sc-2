//
//  AddressBookView.swift
//  sc-2
//
//  Created by Assistant on 8/17/25.
//

import SwiftUI
import Combine

enum BannerType {
    case success
    case error
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

struct AddressBookView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var convexService = ConvexService.shared
    
    @State private var addresses: [SavedAddress] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddressValidation = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var bannerMessage: String?
    @State private var bannerType: BannerType = .success
    @State private var showingBanner = false
    
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
                    
                    // Banner notification
                    if showingBanner, let message = bannerMessage {
                        HStack {
                            Image(systemName: bannerType.icon)
                                .foregroundColor(bannerType.color)
                            Text(message)
                                .font(Theme.Typography.body)
                                .foregroundColor(bannerType.color)
                            Spacer()
                        }
                        .padding()
                        .background(bannerType.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                        .transition(.slide.combined(with: .opacity))
                    }
                    
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
            await setupRealtimeSubscription()
        }
        .sheet(isPresented: $showingAddressValidation) {
            AddressValidationView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .addressSaved)) { _ in
            // Close the address validation sheet when address is saved
            showingAddressValidation = false
        }
    }
    
    private func setupRealtimeSubscription() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Subscribe to real-time address updates
        convexService.subscribeToAddresses(validatedOnly: true)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        errorMessage = "Failed to load addresses: \(error.localizedDescription)"
                    }
                    isLoading = false
                },
                receiveValue: { loadedAddresses in
                    let previousCount = addresses.count
                    addresses = loadedAddresses
                    isLoading = false
                    errorMessage = nil
                    
                    // Show success banner if new address was added
                    if loadedAddresses.count > previousCount {
                        showBanner(message: "Address saved successfully!", type: .success)
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    private func loadAddresses() async {
        await setupRealtimeSubscription()
    }
    
    private func showBanner(message: String, type: BannerType) {
        withAnimation {
            bannerMessage = message
            bannerType = type
            showingBanner = true
        }
        
        // Auto-hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showingBanner = false
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
