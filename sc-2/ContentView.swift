//
//  ContentView.swift
//  sc-2
//
//  Created by Brett Smith on 8/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var secretsStatus = "Loading..."
    @State private var showingAddressValidation = false
    @State private var showingRateCalculation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "shippingbox.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                    Text("UPS Integration Demo")
                        .font(.title)
                        .fontWeight(.semibold)
                }
                
                // Config Status
                VStack(spacing: 12) {
                    Text("Configuration Status")
                        .font(.headline)
                    
                    Text(secretsStatus)
                        .foregroundColor(secretsStatus.contains("Error") ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Spacer()
                
                // Demo Buttons
                VStack(spacing: 16) {
                    Text("Choose a UPS service to test:")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    // Address Validation Button
                    Button(action: {
                        showingAddressValidation = true
                    }) {
                        HStack {
                            Image(systemName: "location.circle")
                            Text("Address Validation")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(secretsStatus.contains("Error") ? Color.gray : Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(secretsStatus.contains("Error"))
                    
                    // Rate Calculation Button
                    Button(action: {
                        showingRateCalculation = true
                    }) {
                        HStack {
                            Image(systemName: "dollarsign.circle")
                            Text("Rate Calculator")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(secretsStatus.contains("Error") ? Color.gray : Color.green)
                        .cornerRadius(12)
                    }
                    .disabled(secretsStatus.contains("Error"))
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("sc-2")
            .navigationBarBackButtonHidden(true)
        }
        .sheet(isPresented: $showingAddressValidation) {
            AddressValidationView()
        }
        .sheet(isPresented: $showingRateCalculation) {
            RateCalculationView()
        }
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
