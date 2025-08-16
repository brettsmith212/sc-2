//
//  ConvexStatusView.swift
//  sc-2
//
//  Created by Assistant on 8/15/25.
//

import SwiftUI

struct ConvexStatusView: View {
    @StateObject private var convexService = ConvexService.shared
    @State private var connectionStatus = "Unknown"
    
    var body: some View {
        HStack {
            Circle()
                .fill(connectionStatus == "Connected" ? .green : (connectionStatus == "Failed" ? .red : .orange))
                .frame(width: 8, height: 8)
            Text("Convex: \(connectionStatus)")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .task {
            await testConnection()
        }
    }
    
    private func testConnection() async {
        do {
            let success = try await convexService.testConnection()
            await MainActor.run {
                connectionStatus = success ? "Connected" : "Failed"
            }
        } catch {
            await MainActor.run {
                connectionStatus = "Failed"
            }
        }
    }
}

#Preview {
    ConvexStatusView()
        .padding()
}
