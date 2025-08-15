import SwiftUI

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radii.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radii.l, style: .continuous)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(Theme.Shadows.level1.opacity),
                    radius: Theme.Shadows.level1.radius,
                    x: 0, y: Theme.Shadows.level1.y)
    }
}

struct FieldModifier: ViewModifier {
    let isError: Bool
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Theme.Colors.Neutral.n50, in: RoundedRectangle(cornerRadius: Theme.Radii.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radii.m, style: .continuous)
                    .stroke(isError ? Theme.Colors.error : Theme.Colors.separator, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
    func field(isError: Bool = false) -> some View { modifier(FieldModifier(isError: isError)) }
}
