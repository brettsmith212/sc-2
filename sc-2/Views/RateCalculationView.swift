import SwiftUI

struct RateCalculationView: View {
@Environment(\.dismiss) private var dismiss
@State private var ratingService: UPSRatingService?

// From
@State private var fromStreet = ""
@State private var fromCity = ""
@State private var fromState = ""
@State private var fromZip = ""
@State private var fromCountry = "US"

// To
@State private var toStreet = ""
@State private var toCity = ""
@State private var toState = ""
@State private var toZip = ""
@State private var toCountry = "US"
@State private var isResidential = false

// Package
@State private var weight = ""
@State private var length = ""
@State private var width = ""
@State private var height = ""

// State
@State private var isLoading = false
@State private var rateResponse: RateResponse?
@State private var errorMessage: String?
@State private var showSheet = false

var body: some View {
NavigationStack {
ScrollView {
VStack(spacing: 16) {
IconTitle(systemName: "dollarsign.circle.fill",
title: "Rate Calculator",
subtitle: "Shop rates and ETAs")
.padding(.top, 8)

// From
ResultCard(title: "From Address", subtitle: nil) {
VStack(spacing: 12) {
LabeledField(title: "Street", placeholder: "123 Main Street", text: $fromStreet)
HStack(spacing: 12) {
LabeledField(title: "City", placeholder: "Timonium", text: $fromCity)
LabeledField(title: "State", placeholder: "MD", text: $fromState, textCase: .characters)
.frame(width: 100)
}
HStack(spacing: 12) {
LabeledField(title: "ZIP", placeholder: "21093", text: $fromZip, keyboard: .numbersAndPunctuation)
LabeledField(title: "Country", placeholder: "US", text: $fromCountry, textCase: .characters)
.frame(width: 100)
}
}
}

// To
ResultCard(title: "To Address", subtitle: nil) {
VStack(spacing: 12) {
LabeledField(title: "Street", placeholder: "456 Oak Avenue", text: $toStreet)
HStack(spacing: 12) {
LabeledField(title: "City", placeholder: "Alpharetta", text: $toCity)
LabeledField(title: "State", placeholder: "GA", text: $toState, textCase: .characters)
.frame(width: 100)
}
HStack(spacing: 12) {
LabeledField(title: "ZIP", placeholder: "30005", text: $toZip, keyboard: .numbersAndPunctuation)
LabeledField(title: "Country", placeholder: "US", text: $toCountry, textCase: .characters)
.frame(width: 100)
}
Toggle("Residential Address", isOn: $isResidential)
.padding(.top, 4)
}
}

// Package
ResultCard(title: "Package", subtitle: "inches • lbs") {
VStack(spacing: 12) {
HStack(spacing: 12) {
LabeledField(title: "Weight (lbs)", placeholder: "2.5", text: $weight, keyboard: .decimalPad)
LabeledField(title: "Length", placeholder: "10", text: $length, keyboard: .decimalPad)
LabeledField(title: "Width", placeholder: "8", text: $width, keyboard: .decimalPad)
LabeledField(title: "Height", placeholder: "6", text: $height, keyboard: .decimalPad)
}
}
}

// Actions
VStack(spacing: 12) {
Button { fillSample() } label: {
Label("Use Sample Data", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
}
                .buttonStyle(TonalButtonStyle())

Button(action: calculateRates) {
                            if isLoading { ProgressView().frame(maxWidth: .infinity, minHeight: 50) }
    else { Label("Calculate Rates", systemImage: "dollarsign.circle").frame(maxWidth: .infinity) }
}
.buttonStyle(FilledButtonStyle())
.disabled(!isFormValid || isLoading)
.opacity(isFormValid ? 1 : 0.6)
}
}
.padding(16)
}
.background(Theme.Colors.bg.ignoresSafeArea())
.toolbar { ToolbarItem(placement: .topBarLeading) { Button("Close") { dismiss() } } }
.sheet(isPresented: $showSheet) {
RateResultsSheet(rateResponse: rateResponse, errorMessage: errorMessage)
.presentationDetents([.large])
.presentationDragIndicator(.visible)
}
.onAppear(perform: initializeService)
.navigationTitle("Rate Calculator")
.navigationBarTitleDisplayMode(.inline)
}
}

private var isFormValid: Bool {
    !fromZip.isEmpty && !fromState.isEmpty &&
        !toZip.isEmpty && !toState.isEmpty &&
    !weight.isEmpty && !length.isEmpty && !width.isEmpty && !height.isEmpty &&
Double(weight) != nil && Double(length) != nil &&
Double(width) != nil && Double(height) != nil
}

private func initializeService() {
    do { ratingService = try UPSRatingService() }
        catch {
        errorMessage = "Failed to initialize rating service: \(error.localizedDescription)"
    showSheet = true
}
}

private func fillSample() {
    fromStreet = "123 Main Street"; fromCity = "TIMONIUM"; fromState = "MD"; fromZip = "21093"; fromCountry = "US"
        toStreet = "456 Oak Avenue"; toCity = "Alpharetta"; toState = "GA"; toZip = "30005"; toCountry = "US"; isResidential = true
    weight = "2.5"; length = "10"; width = "8"; height = "6"
Haptics.tap()
}

private func calculateRates() {
    guard let service = ratingService,
              let weightVal = Double(weight),
          let lengthVal = Double(length),
      let widthVal = Double(width),
let heightVal = Double(height) else {
errorMessage = "Invalid input values"
showSheet = true
return
}

isLoading = true
errorMessage = nil
        rateResponse = nil

Task {
    let result = await service.quickShop(
                fromZip: fromZip, fromState: fromState, fromCountry: fromCountry,
        toZip: toZip, toState: toState, toCountry: toCountry,
    weightLbs: weightVal, length: lengthVal, width: widthVal, height: heightVal,
isResidential: isResidential
)

await MainActor.run {
    isLoading = false
                switch result {
    case .success(let r):
    rateResponse = r
    Haptics.success()
case .failure(let e):
rateResponse = nil
errorMessage = formatErrorMessage(e)
    Haptics.error()
}
showSheet = true
}
}
}

private func formatErrorMessage(_ error: UPSError) -> String {
    switch error {
        case .invalidResponse(let message): return "API Error: \(message)"
    case .serviceUnavailable: return "Service unavailable for this route"
case .configurationError(let message): return "Configuration error: \(message)"
case .decodingError(let e): return "Response parsing error: \(e.localizedDescription)"
case .networkError(let e): return "Network error: \(e.localizedDescription)"
default: return "Rate calculation failed: \(error.localizedDescription)"
}
}
}

// MARK: - Results Sheet

private struct RateResultsSheet: View {
    let rateResponse: RateResponse?
    let errorMessage: String?

var body: some View {
    VStack(spacing: 16) {
            if let errorMessage {
            ResultCard(title: "Rate Lookup Failed", subtitle: nil) {
            Text(errorMessage)
            .foregroundColor(Theme.Colors.secondaryText)
        .font(Theme.Typography.body)
}
} else if let response = rateResponse {
    ResultCard(title: "Available Services", subtitle: "\(response.RatedShipment.count) option(s)") {
    if response.RatedShipment.isEmpty {
    Label("No rates available for this route", systemImage: "info.circle")
    .foregroundColor(Theme.Colors.warning)
} else {
    VStack(spacing: 12) {
    let sortedRates = response.RatedShipment.sorted { 
    Double($0.TotalCharges.MonetaryValue) ?? 0 < Double($1.TotalCharges.MonetaryValue) ?? 0 
                        }
                        ForEach(sortedRates.indices, id: \.self) { idx in
                            let r = sortedRates[idx]
HStack(alignment: .firstTextBaseline) {
    VStack(alignment: .leading, spacing: 4) {
    Text(r.serviceName).font(Theme.Typography.headline)
if let estimate = r.deliveryEstimate {
    Text(estimate).font(Theme.Typography.caption).foregroundColor(Theme.Colors.secondaryText)
}
if let negotiated = r.NegotiatedRateCharges {
    Text("Negotiated: \(negotiated.TotalCharge.CurrencyCode) \(negotiated.TotalCharge.MonetaryValue)")
    .font(Theme.Typography.caption)
.foregroundColor(.green)
}
}
Spacer()
Text(r.formattedPrice).font(Theme.Typography.headline)
}
.padding(12)
.background(Theme.Colors.Neutral.n50, in: RoundedRectangle(cornerRadius: Theme.Radii.m))
}
}
}
}
} else {
ProgressView()
}
}
.padding(16)
}
}

#Preview { RateCalculationView() }
