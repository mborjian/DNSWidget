import SwiftUI

struct DNSRowView: View {
    let server: DNSServer
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onTogglePinned: () -> Void
    
    @EnvironmentObject var latencyService: LatencyService
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            RoundedRectangle(cornerRadius: 2)
                .fill(server.color.gradient)
                .frame(width: 3, height: 36)
                .padding(.leading, DS.Spacing.xs)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: DS.Spacing.xs) {
                    Text(server.name)
                        .font(DS.Font.headline)
                        .foregroundStyle(DS.Colors.text)
                    
                    if isActive {
                        ActiveBadge()
                    }
                }
                
                HStack(spacing: 4) {
                    Text(server.primaryDNS)
                        .font(DS.Font.monoSmall)
                        .foregroundStyle(DS.Colors.textTertiary)
                    if !server.secondaryDNS.isEmpty {
                        Text("•")
                            .font(.system(size: 6))
                            .foregroundStyle(DS.Colors.textTertiary)
                        Text(server.secondaryDNS)
                            .font(DS.Font.monoSmall)
                            .foregroundStyle(DS.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            latencyPill
            
            HStack(spacing: DS.Spacing.xs) {
                ActionDot(
                    icon: server.isPinned ? "pin.fill" : "pin",
                    color: server.isPinned ? .yellow : DS.Colors.textTertiary,
                    isActive: server.isPinned
                ) {
                    onTogglePinned()
                }
                .help(server.isPinned ? "Unpin from top" : "Pin to top")
                
                ActionDot(icon: "pencil", color: DS.Colors.textTertiary) {
                    onEdit()
                }
                .help("Edit")
            }
            .opacity(isHovered ? 1 : 0)
            .offset(x: isHovered ? 0 : 8)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isHovered)
        }
        .padding(.horizontal, DS.Spacing.sm)
        .padding(.vertical, DS.Spacing.xs + 1)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                .fill(rowBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous))
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                    isPressed = false
                }
            }
            onSelect()
        }
    }
    
    // MARK: - Latency Pill
    
    private var rowBackground: Color {
        if isActive { return Color.green.opacity(0.12) }
        if server.isPinned { return Color.white.opacity(0.07) }
        if isHovered { return DS.Colors.cardHover }
        return Color.clear
    }
    
    @ViewBuilder
    private var latencyPill: some View {
        if let ms = latencyService.bestLatency(for: server) {
            HStack(spacing: 3) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 7))
                Text(ms.latencyFormatted)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
            }
            .foregroundStyle(ms.latencyColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(ms.latencyColor.opacity(0.1))
            .clipShape(Capsule())
        } else if latencyService.isTesting && latencyService.latencies[server.primaryDNS] == nil {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 30, height: 14)
        }
    }
    
}

// MARK: - Action Dot

struct ActionDot: View {
    let icon: String
    var color: Color = DS.Colors.textSecondary
    var isActive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(isHovered ? .white : color)
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(isHovered ? color.opacity(0.8) : DS.Colors.card)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
