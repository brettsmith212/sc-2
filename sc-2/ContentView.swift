//
//  ContentView.swift
//  sc-2
//
//  Created by Brett Smith on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var secretsStatus = "Loading..."
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, sc-2!")
            Text(secretsStatus)
                .foregroundColor(secretsStatus.contains("Error") ? .red : .green)
                .multilineTextAlignment(.center)
        }
        .padding()
        .onAppear {
            loadSecrets()
        }
    }
    
    private func loadSecrets() {
        do {
            let config = try Config()
            secretsStatus = "✅ Config loaded successfully!\nOAuth URL: \(config.oauthBaseURL)\nAPI URL: \(config.apiBaseURL)"
        } catch {
            secretsStatus = "❌ Error loading config:\n\(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}
