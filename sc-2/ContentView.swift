import SwiftUI

struct ContentView: View {
    @State private var secretsStatus = "Loading..."
    @State private var showingAddressValidation = false
    @State private var showingRateCalculation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header + status
                    Card {
                        VStack(alignment: .leading, spacing: 16) {
                            IconTitle(systemName: "shippingbox.circle.fill",
                                      title: "UPS Integration Demo",
                                      subtitle: "Address validation and rate shopping")
                            ResultCard(title: "Configuration Status", subtitle: nil) {
                                Text(secretsStatus)
                                    .font(Theme.Typography.body)
                                    .foregroundColor(secretsStatus.contains("Error") ? Theme.Colors.error : Theme.Colors.success)
                            }
                        }
                    }

                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            Haptics.tap(); showingAddressValidation = true
                        } label: { Label("Address Validation", systemImage: "location.circle") }
                        .buttonStyle(TonalButtonStyle())
                        .disabled(secretsStatus.contains("Error"))

                        Button {
                            Haptics.tap(); showingRateCalculation = true
                        } label: { Label("Rate Calculator", systemImage: "dollarsign.circle") }
                        .buttonStyle(FilledButtonStyle())
                        .disabled(secretsStatus.contains("Error"))
                    }
                }
                .padding(16)
            }
            .background(Theme.Colors.bg.ignoresSafeArea())
            .navigationTitle("sc-2")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingAddressValidation) { AddressValidationView() }
        .sheet(isPresented: $showingRateCalculation) { RateCalculationView() }
        .onAppear(perform: loadSecrets)
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

#Preview { ContentView() }
