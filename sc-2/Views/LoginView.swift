//
//  LoginView.swift
//  sc-2
//
//  Created by Assistant on 8/15/25.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct LoginView: View {
    @StateObject private var convexService = ConvexService.shared
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var onAuthenticationSuccess: (User) -> Void = { _ in }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()
                
                // App Logo/Title
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.Colors.primary)
                    
                    Text("ShipComplete")
                        .font(Theme.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.text)
                    
                    Text("Sign in to get started")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
                
                Spacer()
                
                // Sign In Buttons
                VStack(spacing: 16) {
                    // Apple Sign In (Native iOS)
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            Task { await handleAppleSignIn(result) }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .disabled(isLoading)
                    
                    // Google Sign In (Native iOS)
                    GoogleSignInButton(
                        viewModel: GoogleSignInButtonViewModel(
                            scheme: .dark,
                            style: .wide,
                            state: isLoading ? .pressed : .normal
                        ),
                        action: {
                            Task { await signInWithGoogle() }
                        }
                    )
                    .frame(height: 50)
                    .disabled(isLoading)
                }
                
                // Success Message
                if let successMessage {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Error Message
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Loading Indicator
                if isLoading {
                    ProgressView("Signing in...")
                        .scaleEffect(0.9)
                }
                
                Spacer()
                
                // Privacy Note
                Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(24)
            .background(Theme.Colors.bg.ignoresSafeArea())
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        
        do {
            switch result {
            case .success(let authorization):
                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                    // Extract user information
                    let email = appleIDCredential.email ?? "apple_user_\(appleIDCredential.user)@privaterelay.appleid.com"
                    let displayName = appleIDCredential.fullName?.formatted()
                    let finalDisplayName = (displayName?.isEmpty == false) ? displayName! : "Apple User"
                    
                    // Register with Convex backend
                    let userId = try await convexService.registerUser(
                        email: email,
                        displayName: finalDisplayName,
                        authProvider: "apple"
                    )
                    
                    // Store credentials locally for future sessions
                    UserDefaults.standard.set(email, forKey: "user_email")
                    UserDefaults.standard.set(finalDisplayName, forKey: "user_display_name")
                    UserDefaults.standard.set("apple", forKey: "auth_provider")
                    UserDefaults.standard.set(userId, forKey: "convex_user_id")
                    
                    await MainActor.run {
                        successMessage = "Successfully signed in!"
                    }
                    
                    // Create user object and notify parent
                    let user = User(
                        id: userId,
                        authUserId: "apple:\(email)",
                        displayName: finalDisplayName,
                        email: email,
                        tosAcceptedAt: Date().timeIntervalSince1970
                    )
                    
                    // Wait a moment to show success message, then complete
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    onAuthenticationSuccess(user)
                }
            case .failure(let error):
                await MainActor.run {
                    errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to register with backend: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func signInWithGoogle() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
        }
        
        convexService.signInWithGoogle { result in
            Task {
                switch result {
                case .success(let user):
                    await MainActor.run {
                        successMessage = "Successfully signed in with Google!"
                    }
                    
                    // Wait a moment to show success message, then complete
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                    onAuthenticationSuccess(user)
                    
                case .failure(let error):
                    await MainActor.run {
                        errorMessage = "Google Sign In failed: \(error.localizedDescription)"
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
