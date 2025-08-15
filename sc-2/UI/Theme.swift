import SwiftUI

enum Theme {
    // Brand-ish palette (tune to taste)
    static let brand = Color(hue: 0.60, saturation: 0.60, brightness: 0.60) // Indigo
    static let brandAlt = Color(hue: 0.40, saturation: 0.65, brightness: 0.55) // Teal
    static let accent = Color(hue: 0.12, saturation: 0.85, brightness: 0.60) // Orange
    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red

    // Neutrals
    static let cardBG = Color(.secondarySystemBackground)
    static let fieldBG = Color(.systemGray6)
    static let stroke = Color.black.opacity(0.08)

    // Sizing
    enum Space {
        static let xs: CGFloat = 6
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 22
        static let xl: CGFloat = 28
    }

    // Shadows that feel “iOS-native”
    enum Shadow {
        static let soft = ShadowStyle(color: .black.opacity(0.10), radius: 10, y: 6)
        static let pop  = ShadowStyle(color: .black.opacity(0.20), radius: 20, y: 12)
    }

    struct ShadowStyle {
        let color: Color; let radius: CGFloat; let y: CGFloat
    }
}

// Helper to apply a specific shadow style
extension View {
    func themedShadow(_ s: Theme.ShadowStyle = Theme.Shadow.soft) -> some View {
        shadow(color: s.color, radius: s.radius, x: 0, y: s.y)
    }
}
