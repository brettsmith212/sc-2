import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Space.lg)
            .background(Theme.cardBG, in: RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
                    .stroke(Theme.stroke)
            )
            .themedShadow(Theme.Shadow.soft)
    }
}

struct FieldModifier: ViewModifier {
    let isError: Bool
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Theme.Space.md)
            .padding(.vertical, Theme.Space.sm)
            .background(Theme.fieldBG, in: RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .stroke(isError ? Theme.danger.opacity(0.6) : Theme.stroke, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
    func field(isError: Bool = false) -> some View { modifier(FieldModifier(isError: isError)) }
}
