//
//  ConvexService.swift
//  sc-2
//
//  Created by Assistant on 8/15/25.
//

import Foundation
import ConvexMobile

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
}

// MARK: - Models

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
