import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Space.lg)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                LinearGradient(colors: [Theme.brand, Theme.brandAlt], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
            .themedShadow(Theme.Shadow.pop)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.brand)
            .padding(.horizontal, Theme.Space.lg)
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(Theme.brand, lineWidth: 1)
            )
            .background(Theme.cardBG, in: RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: icon).font(.headline).foregroundStyle(Theme.brand)
            Text(title).font(.headline)
            Spacer()
        }
        .padding(.bottom, 6)
    }
}

struct LabeledField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var textCase: TextInputAutocapitalization? = .words
    var isError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(textCase)
                .disableAutocorrection(true)
                .field(isError: isError)
        }
    }
}

struct IconTitle: View {
    let systemName: String
    let title: String
    var subtitle: String? = nil
    var body: some View {
        HStack(spacing: Theme.Space.md) {
            ZStack {
                Circle().fill(Theme.brand.gradient)
                    .frame(width: 56, height: 56)
                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.title2).fontWeight(.semibold)
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            }
            Spacer()
        }
    }
}

struct ResultCard<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                if let subtitle { Text(subtitle).font(.subheadline).foregroundStyle(.secondary) }
            }
            content()
        }
        .card()
    }
}
