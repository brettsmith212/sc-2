//
//  ConvexService.swift
//  sc-2
//
//  Created by Assistant on 8/15/25.
//

import Foundation
import ConvexMobile
import UIKit
import GoogleSignIn

/// Singleton service for managing Convex client and operations
@MainActor
class ConvexService: ObservableObject {
    static let shared = ConvexService()
    
    private let client: ConvexClient
    
    private init() {
        self.client = ConvexClient(deploymentUrl: "https://hidden-labrador-91.convex.cloud")
    }
    
    // MARK: - Connection Testing
    
    /// Test the Convex connection
    func testConnection() async throws -> Bool {
        let result: PingResponse = try await client.mutation("test:ping", with: [:])
        print("✅ Convex connection test:", result)
        return result.status == "connected"
    }
    
    // MARK: - Authentication
    
    /// Check if user is authenticated
    func isAuthenticated() async throws -> Bool {
        // For now, return false - we'll implement proper auth checking later
        return false
    }
    
    /// Get current user
    func getCurrentUser() async throws -> User? {
        // For now, return nil - we'll implement this after OAuth flow works
        return nil
    }
    
    /// Create or update user profile
    func createOrUpdateUser(displayName: String?, email: String?) async throws -> String {
        // For now, return empty string - we'll implement this after OAuth flow works
        return ""
    }
    
    /// Register user with Convex backend (after iOS native auth)
    func registerUser(email: String, displayName: String?, authProvider: String) async throws -> String {
        var requestBody: [String: Any] = [
            "email": email,
            "authProvider": authProvider
        ]
        
        if let displayName = displayName {
            requestBody["displayName"] = displayName
        }
        
        guard let url = URL(string: "https://hidden-labrador-91.convex.site/mobile/register-user") else {
            throw ConvexServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        guard let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = response["success"] as? Bool,
              success,
              let userId = response["userId"] as? String else {
            throw ConvexServiceError.invalidResponse
        }
        
        return userId
    }
    
    /// Sign in with Google (native iOS SDK) 
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        guard let presentingViewController = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first?.rootViewController else {
            completion(.failure(ConvexServiceError.invalidResponse))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { result, error in
            Task {
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let result = result else {
                    completion(.failure(ConvexServiceError.invalidResponse))
                    return
                }
                
                let googleUser = result.user
                let email = googleUser.profile?.email ?? "google_user@unknown.com"
                let displayName = googleUser.profile?.name ?? "Google User"
                
                do {
                    // Register with Convex backend
                    let userId = try await self.registerUser(
                        email: email,
                        displayName: displayName,
                        authProvider: "google"
                    )
                    
                    // Store credentials locally
                    UserDefaults.standard.set(email, forKey: "user_email")
                    UserDefaults.standard.set(displayName, forKey: "user_display_name")
                    UserDefaults.standard.set("google", forKey: "auth_provider")
                    UserDefaults.standard.set(userId, forKey: "convex_user_id")
                    
                    let user = User(
                        id: userId,
                        authUserId: "google:\(email)",
                        displayName: displayName,
                        email: email,
                        tosAcceptedAt: Date().timeIntervalSince1970
                    )
                    
                    completion(.success(user))
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Models

struct User: Identifiable, Codable {
    let id: String
    let authUserId: String
    let displayName: String?
    let email: String?
    let tosAcceptedAt: Double?
}

struct PingResponse: Codable {
    let status: String
    let timestamp: Double
    let message: String
}

// MARK: - Errors

enum ConvexServiceError: LocalizedError {
    case invalidResponse
    case connectionFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Convex"
        case .connectionFailed:
            return "Failed to connect to Convex"
        }
    }
}
