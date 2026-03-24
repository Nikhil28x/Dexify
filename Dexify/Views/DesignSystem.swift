import SwiftUI

// MARK: - Design Tokens
struct DS {
    // MARK: Colors
    struct Colors {
        static let background = Color(hex: "#0F0F14")
        static let surface = Color(hex: "#1A1A24")
        static let surfaceElevated = Color(hex: "#22223A")
        static let border = Color(hex: "#2C2C44")

        static let accent = Color(hex: "#7C3AED")        // Purple
        static let accentSoft = Color(hex: "#7C3AED").opacity(0.18)
        static let accentGradient = LinearGradient(
            colors: [Color(hex: "#7C3AED"), Color(hex: "#A855F7")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )

        static let success = Color(hex: "#22C55E")
        static let successSoft = Color(hex: "#22C55E").opacity(0.18)
        static let warning = Color(hex: "#F59E0B")
        static let warningSoft = Color(hex: "#F59E0B").opacity(0.18)
        static let danger = Color(hex: "#EF4444")
        static let dangerSoft = Color(hex: "#EF4444").opacity(0.18)
        static let info = Color(hex: "#3B82F6")
        static let infoSoft = Color(hex: "#3B82F6").opacity(0.18)

        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A1A1C7")
        static let textMuted = Color(hex: "#5C5C8A")
    }

    // MARK: Gradients
    struct Gradients {
        static let pageBackground = LinearGradient(
            colors: [Color(hex: "#0F0F14"), Color(hex: "#13131F")],
            startPoint: .top, endPoint: .bottom
        )
        static let cardPurple = LinearGradient(
            colors: [Color(hex: "#7C3AED").opacity(0.3), Color(hex: "#A855F7").opacity(0.1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let cardGreen = LinearGradient(
            colors: [Color(hex: "#22C55E").opacity(0.3), Color(hex: "#16A34A").opacity(0.1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let cardAmber = LinearGradient(
            colors: [Color(hex: "#F59E0B").opacity(0.3), Color(hex: "#D97706").opacity(0.1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let cardBlue = LinearGradient(
            colors: [Color(hex: "#3B82F6").opacity(0.3), Color(hex: "#2563EB").opacity(0.1)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    // MARK: Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: Radius
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
}

// MARK: - Color from hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Reusable Components

struct DexCard<Content: View>: View {
    let content: Content
    var padding: CGFloat = DS.Spacing.md

    init(padding: CGFloat = DS.Spacing.md, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.padding = padding
    }

    var body: some View {
        content
            .padding(padding)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.lg)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

struct DexPrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false

    init(_ title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isDisabled ? DS.Colors.textMuted : DS.Colors.accent)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .disabled(isDisabled)
    }
}

struct DexSecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .medium))
                }
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(DS.Colors.surfaceElevated)
            .foregroundColor(DS.Colors.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
        }
    }
}

struct DexTextField: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        TextField("", text: $text)
            .placeholder(when: text.isEmpty) {
                Text(placeholder)
                    .foregroundColor(DS.Colors.textMuted)
            }
            .keyboardType(keyboardType)
            .foregroundColor(DS.Colors.textPrimary)
            .padding(DS.Spacing.md)
            .background(DS.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.md)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func placeholder<T: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> T
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String?

    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
            }
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(DS.Colors.textMuted)
                .kerning(1.2)
            Spacer()
        }
    }
}

struct DexNavBar: View {
    let title: String
    var subtitle: String? = nil
    var leadingAction: (() -> Void)? = nil
    var trailingAction: (() -> Void)? = nil
    var trailingIcon: String? = nil

    var body: some View {
        HStack(alignment: .center) {
            if let action = leadingAction {
                Button(action: action) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DS.Colors.surfaceElevated)
                        .clipShape(Circle())
                }
            }

            VStack(alignment: leadingAction == nil ? .center : .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DS.Colors.textPrimary)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: leadingAction == nil ? .center : .leading)

            if let action = trailingAction, let icon = trailingIcon {
                Button(action: action) {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(DS.Colors.textPrimary)
                        .frame(width: 36, height: 36)
                        .background(DS.Colors.surfaceElevated)
                        .clipShape(Circle())
                }
            } else if trailingAction != nil || trailingIcon != nil {
                Spacer().frame(width: 36)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.sm)
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.md)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}
