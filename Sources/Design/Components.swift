import SwiftUI

// MARK: - Gradient Header

struct GradientHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(DS.Colors.accentGradient)
                    .frame(width: 28, height: 28)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(DS.Font.title)
                .foregroundStyle(DS.Colors.text)
            
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.vertical, DS.Spacing.md)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    var count: Int? = nil
    
    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Text(title)
                .font(DS.Font.caption)
                .foregroundStyle(DS.Colors.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
            
            if let count = count {
                Text("\(count)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(DS.Colors.card)
                    .clipShape(Capsule())
            }
            
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.lg)
        .padding(.top, DS.Spacing.sm)
        .padding(.bottom, DS.Spacing.xs)
    }
}

// MARK: - Status Pill

struct StatusPill: View {
    let text: String
    let color: Color
    var icon: String? = nil
    
    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .fill(color.opacity(0.4))
                        .frame(width: 10, height: 10)
                )
            
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9))
            }
            
            Text(text)
                .font(DS.Font.caption)
        }
        .foregroundStyle(DS.Colors.textSecondary)
    }
}

// MARK: - Active Badge

struct ActiveBadge: View {
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 9))
            Text("Active")
                .font(.system(size: 8, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(DS.Colors.successGradient)
        )
    }
}

// MARK: - Pill Button

struct PillButton: View {
    let title: String
    let icon: String
    var color: Color = DS.Colors.accent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(title)
                    .font(DS.Font.caption)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.sm + 2)
            .padding(.vertical, DS.Spacing.xs + 1)
            .background(
                Capsule()
                    .fill(color.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Button

struct IconButton: View {
    let icon: String
    var color: Color = DS.Colors.textSecondary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 24, height: 24)
                .background(Circle().fill(DS.Colors.card))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gradient Divider

struct GradientDivider: View {
    var body: some View {
        LinearGradient(
            colors: [DS.Colors.borderSubtle, DS.Colors.border, DS.Colors.borderSubtle],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 0.5)
        .padding(.horizontal, DS.Spacing.md)
    }
}

// MARK: - Empty State

struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: DS.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(DS.Colors.textTertiary)
            Text(title)
                .font(DS.Font.headline)
                .foregroundStyle(DS.Colors.textSecondary)
            Text(subtitle)
                .font(DS.Font.caption)
                .foregroundStyle(DS.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.xl)
    }
}

// MARK: - Toast Message

struct ToastMessage: View {
    let text: String
    let isError: Bool
    
    var body: some View {
        HStack(spacing: DS.Spacing.xs) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .font(.system(size: 10))
            Text(text)
                .font(DS.Font.caption)
        }
        .foregroundStyle(isError ? DS.Colors.danger : DS.Colors.success)
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.xs)
        .background(
            (isError ? DS.Colors.danger : DS.Colors.success).opacity(0.1)
                .clipShape(Capsule())
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
