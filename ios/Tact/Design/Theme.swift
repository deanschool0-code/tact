import SwiftUI

/// Design tokens — mirrors replica/design/tokens.json. Components use these, never raw values.
enum Theme {
    static let bg = Color(hex: 0x0D0F14)
    static let surface = Color(hex: 0x161A22)
    static let surface2 = Color(hex: 0x1F2430)
    static let border = Color(hex: 0x2A3040)
    static let borderInput = Color(hex: 0x6B7489)
    static let text = Color(hex: 0xF3F5F9)
    static let textMuted = Color(hex: 0x9AA3B5)
    static let accent = Color(hex: 0xC8F25A)
    static let onAccent = Color(hex: 0x0D0F14)
    static let bubbleMe = Color(hex: 0xC8F25A)
    static let onBubbleMe = Color(hex: 0x0D0F14)
    static let bubbleThem = Color(hex: 0x2A3040)
    static let danger = Color(hex: 0xFF6B6B)
    static let success = Color(hex: 0x4ADE9B)
    static let warning = Color(hex: 0xFFC24B)

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 14
        static let lg: CGFloat = 22
    }

    enum Space {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Font {
        static let display = SwiftUI.Font.system(size: 34, weight: .heavy, design: .rounded)
        static let title = SwiftUI.Font.system(size: 24, weight: .bold, design: .rounded)
        static let headline = SwiftUI.Font.system(size: 18, weight: .semibold)
        static let body = SwiftUI.Font.system(size: 16)
        static let footnote = SwiftUI.Font.system(size: 14)
        static let caption = SwiftUI.Font.system(size: 12, weight: .medium)
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
