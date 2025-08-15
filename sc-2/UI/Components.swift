import SwiftUI

// Reusable bits that align to the style guide Theme

struct SectionHeader: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primary)
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.text)
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
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
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
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.Colors.primary)
                    .frame(width: 56, height: 56)
                Image(systemName: systemName)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.text)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
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
        Card {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.text)
                    Spacer()
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
                content()
            }
        }
    }
}
