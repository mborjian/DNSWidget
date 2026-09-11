import SwiftUI

// MARK: - Design Tokens

enum DS {
    // MARK: Colors
    enum Colors {
        static let bg         = Color(nsColor: NSColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0))
        static let bgElevated = Color(nsColor: NSColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0))
        static let card       = Color.white.opacity(0.05)
        static let cardHover  = Color.white.opacity(0.08)
        static let cardActive = Color.blue.opacity(0.12)
        static let border     = Color.white.opacity(0.08)
        static let borderSubtle = Color.white.opacity(0.04)
        static let text       = Color.white
        static let textSecondary = Color.white.opacity(0.6)
        static let textTertiary  = Color.white.opacity(0.35)
        static let accent     = Color.blue
        static let success    = Color.green
        static let warning    = Color.orange
        static let danger     = Color.red
        
        static let accentGradient = LinearGradient(
            colors: [Color.blue, Color.purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let headerGradient = LinearGradient(
            colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        static let successGradient = LinearGradient(
            colors: [Color.green, Color.teal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: Typography
    enum Font {
        static let title    = system(15, weight: .semibold, design: .rounded)
        static let headline = system(13, weight: .semibold, design: .rounded)
        static let body     = system(12, weight: .regular, design: .rounded)
        static let caption  = system(10, weight: .medium, design: .rounded)
        static let mono     = system(11, weight: .regular, design: .monospaced)
        static let monoSmall = system(9.5, weight: .regular, design: .monospaced)
        
        private static func system(_ size: CGFloat, weight: SwiftUI.Font.Weight, design: SwiftUI.Font.Design) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: design)
        }
    }
    
    // MARK: Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }
    
    enum Layout {
        static let pageWidth: CGFloat = 360
        static let pageHeight: CGFloat = 408
    }
    
    // MARK: Corner Radii
    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
        static let xl: CGFloat = 18
        static let pill: CGFloat = 100
    }
    
    // MARK: Shadows
    enum Shadow {
        static func soft(color: Color = .black.opacity(0.2), radius: CGFloat = 8, y: CGFloat = 2) -> some View {
            EmptyView()
        }
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = DS.Radius.md) -> some View {
        self
            .background(DS.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(DS.Colors.border, lineWidth: 0.5)
            )
    }
    
    func subtleGlow(color: Color = .blue, radius: CGFloat = 6) -> some View {
        self
            .shadow(color: color.opacity(0.3), radius: radius, y: 0)
    }
    
    func fadeIn(_ show: Bool, duration: Double = 0.2) -> some View {
        self.opacity(show ? 1 : 0)
            .animation(.easeInOut(duration: duration), value: show)
    }
    
    func slideIn(_ show: Bool, edge: Edge = .trailing, distance: CGFloat = 8) -> some View {
        self.offset(x: show ? 0 : (edge == .trailing ? distance : -distance))
            .opacity(show ? 1 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: show)
    }
}
