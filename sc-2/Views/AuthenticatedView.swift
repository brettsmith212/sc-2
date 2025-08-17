//
//  AuthenticatedView.swift
//  sc-2
//
//  Created by Assistant on 8/15/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @StateObject private var convexService = ConvexService.shared
    @State private var isAuthenticated: Bool? = nil
    @State private var currentUser: User?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                // Loading Screen
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.bg.ignoresSafeArea())
            } else if isAuthenticated == true {
                // Main App Content
                MainAppView(currentUser: currentUser)
            } else {
                // Login Screen
                LoginView { user in
                    // Handle successful authentication
                    currentUser = user
                    isAuthenticated = true
                }
            }
        }
        .task {
            await checkAuthenticationStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check auth status when app becomes active (useful after OAuth redirect)
            Task {
                await checkAuthenticationStatus()
            }
        }
    }
    
    private func checkAuthenticationStatus() async {
        // Check if user is stored locally
        if let email = UserDefaults.standard.string(forKey: "user_email"),
           let displayName = UserDefaults.standard.string(forKey: "user_display_name"),
           let authProvider = UserDefaults.standard.string(forKey: "auth_provider"),
           let userId = UserDefaults.standard.string(forKey: "convex_user_id") {
            
            // User is authenticated locally
            let user = User(
                id: userId,
                authUserId: "\(authProvider):\(email)",
                displayName: displayName,
                email: email,
                tosAcceptedAt: Date().timeIntervalSince1970
            )
            
            await MainActor.run {
                isAuthenticated = true
                currentUser = user
                isLoading = false
            }
        } else {
            // No local authentication
            await MainActor.run {
                isAuthenticated = false
                currentUser = nil
                isLoading = false
            }
        }
    }
}

struct MainAppView: View {
    let currentUser: User?
    @StateObject private var convexService = ConvexService.shared
    @State private var showingAddressValidation = false
    @State private var showingRateCalculation = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // App header with user info
                    VStack(spacing: 8) {
                        IconTitle(systemName: "shippingbox.circle.fill",
                                  title: "Ship Complete",
                                  subtitle: "UPS address check and rate shopping")
                        
                        // User info
                        if let user = currentUser {
                            HStack {
                                Text("Welcome, \(user.displayName ?? user.email ?? "User")!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Sign Out") {
                                    Task { await signOut() }
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)

                    // Backend Status
                    VStack(alignment: .leading, spacing: 4) {
                        ConvexStatusView()
                    }
                    
                    // Primary actions
                    VStack(spacing: 12) {
                        Button {
                            Haptics.tap(); showingAddressValidation = true
                        } label: { Label("Address Validation", systemImage: "location.circle") }
                        .buttonStyle(TonalButtonStyle())

                        Button {
                            Haptics.tap(); showingRateCalculation = true
                        } label: { Label("Rate Calculator", systemImage: "dollarsign.circle") }
                        .buttonStyle(FilledButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(Theme.Colors.bg.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ship Complete")
                        .font(Theme.Typography.title1)
                        .foregroundColor(Theme.Colors.text)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.Colors.bg, for: .navigationBar)
        }
        .sheet(isPresented: $showingAddressValidation) { AddressValidationView() }
        .sheet(isPresented: $showingRateCalculation) { RateCalculationView() }
    }
    
    private func signOut() async {
        // Clear local authentication data
        UserDefaults.standard.removeObject(forKey: "user_email")
        UserDefaults.standard.removeObject(forKey: "user_display_name")
        UserDefaults.standard.removeObject(forKey: "auth_provider")
        UserDefaults.standard.removeObject(forKey: "convex_user_id")
        
        // Update UI to show login screen
        await MainActor.run {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = UIHostingController(rootView: AuthenticatedView())
            }
        }
    }
}

#Preview {
    AuthenticatedView()
}
