```
{
  "meta": { "name": "Ship Complete – Light", "summary": "Light-mode design tokens for Ship Complete: friendly, polished, trustworthy SwiftUI theme." },
  "colors": {
    "palette": {
      "primary": {
        "50":  "#F0F4F7",
        "100": "#E1EAEF",
        "200": "#C7D7E2",
        "300": "#A9C2D2",
        "400": "#8CADC2",
        "500": "#457B9D",
        "600": "#3E6F8D",
        "700": "#36607A",
        "800": "#2E5168",
        "900": "#223E4E"
      },
      "accent": {
        "50":  "#FDEFF0",
        "100": "#FBDFE1",
        "200": "#F8C4C8",
        "300": "#F4A4AA",
        "400": "#F0848C",
        "500": "#E63946",
        "600": "#CF333F",
        "700": "#B32C37",
        "800": "#98262E",
        "900": "#731C23"
      },
      "neutral": {
        "50":  "#F2F4F7",
        "100": "#E5EAEF",
        "200": "#CED7E2",
        "300": "#B4C2D2",
        "400": "#9AADC2",
        "500": "#5C7A9D",
        "600": "#536E8D",
        "700": "#485F7A",
        "800": "#3D5168",
        "900": "#2E3D4E"
      },
      "success": {
        "50":  "#ECF8F1",
        "100": "#DAF0E2",
        "200": "#B9E3C9",
        "300": "#94D5AC",
        "400": "#6FC68F",
        "500": "#16A34A",
        "600": "#149343",
        "700": "#117F3A",
        "800": "#0F6C31",
        "900": "#0B5225"
      },
      "warning": {
        "50":  "#FEF7EB",
        "100": "#FDEFD8",
        "200": "#FCE2B6",
        "300": "#FAD28F",
        "400": "#F9C368",
        "500": "#F59E0B",
        "600": "#DC8E0A",
        "700": "#BF7B09",
        "800": "#A26807",
        "900": "#7A4F06"
      },
      "error": {
        "50":  "#FCEEEE",
        "100": "#F9DCDC",
        "200": "#F4BEBE",
        "300": "#EF9B9B",
        "400": "#E97878",
        "500": "#DC2626",
        "600": "#C62222",
        "700": "#AC1E1E",
        "800": "#911919",
        "900": "#6E1313"
      }
    },
    "semantic": {
      "bg": "#F1FAEE",
      "surface": "#FFFFFF",
      "elevation1": "#FFFFFF",
      "primary": "#457B9D",
      "onPrimary": "#FFFFFF",
      "accent": "#E63946",
      "onAccent": "#FFFFFF",
      "success": "#16A34A",
      "warning": "#F59E0B",
      "error": "#DC2626",
      "separator": "#E3EDF2",
      "text": "#1D3557",
      "secondaryText": "#5C7A9D"
    }
  },
  "typography": {
    "scale": {
      "largeTitle": {"size": 34, "weight": "bold", "leading": 40},
      "title1": {"size": 28, "weight": "semibold", "leading": 34},
      "title2": {"size": 22, "weight": "semibold", "leading": 28},
      "headline": {"size": 17, "weight": "semibold", "leading": 22},
      "body": {"size": 17, "weight": "regular", "leading": 22},
      "caption": {"size": 13, "weight": "regular", "leading": 16}
    }
  },
  "radii": { "xs": 6, "s": 10, "m": 14, "l": 20, "xl": 28 },
  "shadows": {
    "level1": {"radius": 8, "y": 4, "opacity": 0.08},
    "level2": {"radius": 16, "y": 8, "opacity": 0.12}
  },
  "components": {
    "button": {
      "filled": {"bg": "{colors.semantic.primary}", "fg": "{colors.semantic.onPrimary}"},
      "tonal": {"bg": "#A8DADC", "fg": "#1D3557"},
      "ghost": {"bg": "transparent", "fg": "{colors.semantic.primary}", "border": "{colors.semantic.separator}"}
    },
    "card": {"bg": "{colors.semantic.surface}", "radius": "{radii.l}", "shadow": "level1"},
    "list": {"style": "insetGrouped", "separator": "{colors.semantic.separator}"}
  },
  "states": {
    "hover": {"opacity": 0.96},
    "pressed": {"scale": 0.98},
    "disabled": {"opacity": 0.5}
  },
  "haptics": {"buttonTap": "light", "success": "medium"}
}
---
import SwiftUI

// MARK: - Theme

public enum Theme {
    // MARK: Colors
    public enum Colors {
        // Semantic
        public static let bg = Color(hex: "#F1FAEE")
        public static let surface = Color(hex: "#FFFFFF")
        public static let elevation1 = Color(hex: "#FFFFFF")

        public static let primary = Color(hex: "#457B9D")
        public static let onPrimary = Color(hex: "#FFFFFF")

        public static let accent = Color(hex: "#E63946")
        public static let onAccent = Color(hex: "#FFFFFF")

        public static let success = Color(hex: "#16A34A")
        public static let warning = Color(hex: "#F59E0B")
        public static let error = Color(hex: "#DC2626")

        public static let separator = Color(hex: "#E3EDF2")

        public static let text = Color(hex: "#1D3557")
        public static let secondaryText = Color(hex: "#5C7A9D")

        // Palette – Primary
        public enum Primary {
            public static let p50  = Color(hex: "#F0F4F7")
            public static let p100 = Color(hex: "#E1EAEF")
            public static let p200 = Color(hex: "#C7D7E2")
            public static let p300 = Color(hex: "#A9C2D2")
            public static let p400 = Color(hex: "#8CADC2")
            public static let p500 = Color(hex: "#457B9D") // brand
            public static let p600 = Color(hex: "#3E6F8D")
            public static let p700 = Color(hex: "#36607A")
            public static let p800 = Color(hex: "#2E5168")
            public static let p900 = Color(hex: "#223E4E")
        }

        // Palette – Accent (Red)
        public enum Accent {
            public static let a50  = Color(hex: "#FDEFF0")
            public static let a100 = Color(hex: "#FBDFE1")
            public static let a200 = Color(hex: "#F8C4C8")
            public static let a300 = Color(hex: "#F4A4AA")
            public static let a400 = Color(hex: "#F0848C")
            public static let a500 = Color(hex: "#E63946") // accent
            public static let a600 = Color(hex: "#CF333F")
            public static let a700 = Color(hex: "#B32C37")
            public static let a800 = Color(hex: "#98262E")
            public static let a900 = Color(hex: "#731C23")
        }

        // Palette – Neutral
        public enum Neutral {
            public static let n50  = Color(hex: "#F2F4F7")
            public static let n100 = Color(hex: "#E5EAEF")
            public static let n200 = Color(hex: "#CED7E2")
            public static let n300 = Color(hex: "#B4C2D2")
            public static let n400 = Color(hex: "#9AADC2")
            public static let n500 = Color(hex: "#5C7A9D")
            public static let n600 = Color(hex: "#536E8D")
            public static let n700 = Color(hex: "#485F7A")
            public static let n800 = Color(hex: "#3D5168")
            public static let n900 = Color(hex: "#2E3D4E")
        }

        // Palette – States
        public enum State {
            public enum Success {
                public static let s500 = Color(hex: "#16A34A")
            }
            public enum Warning {
                public static let w500 = Color(hex: "#F59E0B")
            }
            public enum Error {
                public static let e500 = Color(hex: "#DC2626")
            }
        }

        // Extras
        public static let tonalBG = Color(hex: "#A8DADC") // Light Blue tint
        public static let tonalFG = Color(hex: "#1D3557") // Ink
    }

    // MARK: Typography
    public enum Typography {
        public static var largeTitle: Font { .system(size: 34, weight: .bold, design: .default) }
        public static var title1: Font { .system(size: 28, weight: .semibold, design: .default) }
        public static var title2: Font { .system(size: 22, weight: .semibold, design: .default) }
        public static var headline: Font { .system(size: 17, weight: .semibold, design: .default) }
        public static var body: Font { .system(size: 17, weight: .regular, design: .default) }
        public static var caption: Font { .system(size: 13, weight: .regular, design: .default) }
    }

    // MARK: Radii
    public enum Radii {
        public static let xs: CGFloat = 6
        public static let s: CGFloat = 10
        public static let m: CGFloat = 14
        public static let l: CGFloat = 20
        public static let xl: CGFloat = 28
    }

    // MARK: Shadows
    public enum Shadows {
        public static let level1 = Shadow(radius: 8, y: 4, opacity: 0.08)
        public static let level2 = Shadow(radius: 16, y: 8, opacity: 0.12)

        public struct Shadow {
            public let radius: CGFloat
            public let y: CGFloat
            public let opacity: Double
            public init(radius: CGFloat, y: CGFloat, opacity: Double) {
                self.radius = radius; self.y = y; self.opacity = opacity
            }
        }
    }
}

// MARK: - Example Styles

public struct FilledButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundColor(Theme.Colors.onPrimary)
            .background(Theme.Colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radii.m, style: .continuous))
            .opacity(configuration.isPressed ? 0.96 : 1.0) // hover -> 0.96; pressed -> scale
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .shadow(color: Color.black.opacity(Theme.Shadows.level1.opacity),
                    radius: Theme.Shadows.level1.radius,
                    x: 0, y: Theme.Shadows.level1.y)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct TonalButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .foregroundColor(Theme.Colors.tonalFG)
            .background(Theme.Colors.tonalBG)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radii.m, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radii.m, style: .continuous)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.96 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

public struct GhostButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.headline)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .foregroundColor(Theme.Colors.primary)
            .background(Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radii.s, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radii.s, style: .continuous)
                    .stroke(Theme.Colors.separator, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.96 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Card

public struct Card<Content: View>: View {
    private let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radii.l, style: .continuous))
        .shadow(color: Color.black.opacity(Theme.Shadows.level1.opacity),
                radius: Theme.Shadows.level1.radius,
                x: 0, y: Theme.Shadows.level1.y)
    }
}

// MARK: - Example Preview (Light only)

struct Theme_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Ship Complete")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.text)

                Card {
                    Text("Quick Ship")
                        .font(Theme.Typography.title2)
                        .foregroundColor(Theme.Colors.text)
                    Text("Find great UPS discounts, measure a package in-app, and generate a QR code for fast drop-off.")
                        .font(Theme.Typography.body)
                        .foregroundColor(Theme.Colors.secondaryText)
                }

                VStack(spacing: 12) {
                    Button("Get Rate") { }
                        .buttonStyle(FilledButtonStyle())
                    Button("Add to Cart") { }
                        .buttonStyle(TonalButtonStyle())
                    Button("More Options") { }
                        .buttonStyle(GhostButtonStyle())
                }
            }
            .padding()
            .background(Theme.Colors.bg.ignoresSafeArea())
        }
        .environment(\.colorScheme, .light)
    }
}

// MARK: - Utilities

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0; Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255,
                                (int >> 8) * 17,
                                (int >> 4 & 0xF) * 17,
                                (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255,
                                int >> 16,
                                int >> 8 & 0xFF,
                                int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24,
                                int >> 16 & 0xFF,
                                int >> 8 & 0xFF,
                                int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
```
