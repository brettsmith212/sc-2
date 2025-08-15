import SwiftUI

struct ContentView: View {
    @State private var showingAddressValidation = false
    @State private var showingRateCalculation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // App header
                    IconTitle(systemName: "shippingbox.circle.fill",
                              title: "Ship Complete",
                              subtitle: "UPS address check and rate shopping")
                        .padding(.top, 8)

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
}

#Preview { ContentView() }
