import SwiftUI

struct ContentView: View {
    @State private var secretsStatus = "Loading..."
    @State private var showingAddressValidation = false
    @State private var showingRateCalculation = false
    @State private var tilt: CGSize = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                // Subtle gradient background
                LinearGradient(colors: [Theme.brand.opacity(0.18), Theme.brandAlt.opacity(0.18)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Space.xl) {
                        // Header card
                        VStack(alignment: .leading, spacing: Theme.Space.lg) {
                            IconTitle(systemName: "shippingbox.circle.fill",
                                      title: "UPS Integration Demo",
                                      subtitle: "Address validation and rate shopping")

                            ResultCard(title: "Configuration Status", subtitle: nil) {
                                Text(secretsStatus)
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .foregroundStyle(secretsStatus.contains("Error") ? Theme.danger : Theme.success)
                            }
                        }
                        .padding(.vertical, Theme.Space.lg)
                        .padding(.horizontal, Theme.Space.lg)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous)
                                .stroke(Theme.stroke)
                        )
                        .background(Theme.cardBG, in: RoundedRectangle(cornerRadius: Theme.Radius.xl, style: .continuous))
                        .themedShadow(Theme.Shadow.soft)
                        .padding(.top, Theme.Space.lg)

                        // Actions
                        VStack(spacing: Theme.Space.md) {
                            Button {
                                Haptics.tap()
                                showingAddressValidation = true
                            } label: {
                                Label("Address Validation", systemImage: "location.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(secretsStatus.contains("Error"))

                            Button {
                                Haptics.tap()
                                showingRateCalculation = true
                            } label: {
                                Label("Rate Calculator", systemImage: "dollarsign.circle")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(secretsStatus.contains("Error"))
                        }
                    }
                    .padding(Theme.Space.lg)
                }
            }
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
