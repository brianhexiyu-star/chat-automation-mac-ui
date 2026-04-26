import SwiftUI

/// CapCut-inspired dark design system for the Chat Automation Tool.
enum DesignSystem {

    // MARK: - Colors
    enum Colors {
        /// Deep black main background — like CapCut's canvas bg
        static let backgroundPrimary   = Color(hex: "#111111")
        /// Sidebar / panel background
        static let backgroundSecondary = Color(hex: "#1C1C1C")
        /// Card / list item hover background
        static let backgroundTertiary  = Color(hex: "#272727")
        /// Interactive element hover
        static let backgroundHover     = Color(hex: "#303030")

        /// Primary accent — vivid indigo/violet (CapCut-style)
        static let accent              = Color(hex: "#6C63FF")
        /// Green for active/running state
        static let accentGreen         = Color(hex: "#3DDC84")
        /// Red for stop / error
        static let accentRed           = Color(hex: "#FF4C6A")
        /// Amber for warnings
        static let accentAmber         = Color(hex: "#F5A623")

        static let textPrimary         = Color.white
        static let textSecondary       = Color(hex: "#888888")
        static let textTertiary        = Color(hex: "#555555")

        static let separator           = Color(hex: "#2A2A2A")
        static let border              = Color(hex: "#333333")
    }

    // MARK: - Typography
    enum Typography {
        static let titleLarge   = Font.system(size: 18, weight: .semibold, design: .rounded)
        static let title        = Font.system(size: 15, weight: .semibold, design: .rounded)
        static let body         = Font.system(size: 13, weight: .regular, design: .default)
        static let bodyMedium   = Font.system(size: 13, weight: .medium, design: .default)
        static let caption      = Font.system(size: 11, weight: .regular, design: .default)
        static let mono         = Font.system(size: 12, weight: .regular, design: .monospaced)
    }

    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 12
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Radius
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
    }

    // MARK: - Sidebar
    static let sidebarWidth: CGFloat = 220
}

// MARK: - Color Hex Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
