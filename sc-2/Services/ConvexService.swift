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
import Combine

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
    
    // MARK: - Address Book Operations
    
    /// Save a validated address to the user's address book (real-time)
    func saveAddress(request: CreateAddressRequest) async throws -> String {
        guard let userId = UserDefaults.standard.string(forKey: "convex_user_id") else {
            throw ConvexServiceError.invalidResponse
        }
        
        var args: [String: ConvexEncodable?] = [
            "userId": userId,
            "label": request.label,
            "name": request.name,
            "line1": request.line1,
            "city": request.city,
            "state": request.state,
            "postalCode": request.postalCode,
            "country": request.country
        ]
        
        // Only add optional fields if they have values
        if let phone = request.phone, !phone.isEmpty {
            args["phone"] = phone
        }
        if let email = request.email, !email.isEmpty {
            args["email"] = email
        }
        if let line2 = request.line2, !line2.isEmpty {
            args["line2"] = line2
        }
        
        let addressId: String = try await client.mutation("addresses:createAddressByUserId", with: args)
        return addressId
    }
    
    /// Get real-time subscription to saved addresses (reactive)
    func subscribeToAddresses(validatedOnly: Bool = true) -> AnyPublisher<[SavedAddress], any Error> {
        guard let userId = UserDefaults.standard.string(forKey: "convex_user_id") else {
            return Fail(error: ConvexServiceError.invalidResponse)
                .eraseToAnyPublisher()
        }
        
        let args: [String: ConvexEncodable?] = [
            "userId": userId,
            "validatedOnly": validatedOnly
        ]
        
        return client.subscribe(to: "addresses:listAddressesByUserId", with: args, yielding: [SavedAddress].self)
            .map { $0 as [SavedAddress] }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
    /// Get a specific address by ID
    func getAddress(id: String) async throws -> SavedAddress {
        let args: [String: ConvexEncodable?] = ["addressId": id]
        
        // Use subscribe for queries - get first result from publisher
        let publisher = client.subscribe(to: "addresses:getAddress", with: args, yielding: SavedAddress.self)
        
        return try await withCheckedThrowingContinuation { continuation in
            let cancellable = publisher.sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        continuation.resume(throwing: error)
                    }
                },
                receiveValue: { address in
                    continuation.resume(returning: address)
                }
            )
            // Keep cancellable alive until continuation resolves
            _ = cancellable
        }
    }
    
    /// Update an existing address
    func updateAddress(id: String, label: String? = nil, name: String? = nil, phone: String? = nil, email: String? = nil) async throws -> String {
        var args: [String: ConvexEncodable?] = ["addressId": id]
        if let label = label { args["label"] = label }
        if let name = name { args["name"] = name }
        if let phone = phone { args["phone"] = phone }
        if let email = email { args["email"] = email }
        
        let addressId: String = try await client.mutation("addresses:updateAddress", with: args)
        return addressId
    }
    
    /// Delete an address from the address book
    func deleteAddress(id: String) async throws -> Bool {
        let args: [String: ConvexEncodable?] = ["addressId": id]
        let success: Bool = try await client.mutation("addresses:deleteAddress", with: args)
        return success
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
