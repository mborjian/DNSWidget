import SwiftUI
import WidgetKit

// MARK: - Main Widget View

struct DNSWidgetEntryView: View {
    var entry: DNSWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(data: entry.data)
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

// MARK: - Small Widget (170x170)

struct SmallWidgetView: View {
    let data: SharedWidgetData
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    widgetColor.opacity(0.3),
                    widgetColor.opacity(0.1),
                    Color.black.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(widgetColor.opacity(0.3))
                            .frame(width: 28, height: 28)
                        Image(systemName: "network")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(widgetColor)
                    }
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: .green.opacity(0.5), radius: 3)
                }
                
                Spacer()
                
                Text(data.activeDNSName)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.primaryDNS)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                    if data.hasSecondary {
                        Text(data.secondaryDNS)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 7))
                    Text(data.formattedTime)
                        .font(.system(size: 8, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.4))
            }
            .padding(14)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private var widgetColor: Color {
        switch data.colorName {
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "red":    return .red
        case "purple": return .purple
        case "teal":   return .teal
        case "indigo": return .indigo
        case "pink":   return .pink
        default:       return .gray
        }
    }
}

// MARK: - Medium Widget (345x170)

struct MediumWidgetView: View {
    let data: SharedWidgetData
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    widgetColor.opacity(0.25),
                    widgetColor.opacity(0.08),
                    Color.black.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(widgetColor.opacity(0.3))
                                .frame(width: 36, height: 36)
                            Image(systemName: "network")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(widgetColor)
                        }
                        
                        Circle()
                            .fill(.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: .green.opacity(0.6), radius: 4)
                    }
                    
                    Text(data.activeDNSName)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(data.networkService)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.1))
                        .clipShape(Capsule())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    dnsDetailRow(label: "Primary", value: data.primaryDNS)
                    if data.hasSecondary {
                        dnsDetailRow(label: "Secondary", value: data.secondaryDNS)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 8))
                        Text(data.formattedTime)
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.35))
                }
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private func dnsDetailRow(label: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    
    private var widgetColor: Color {
        switch data.colorName {
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "red":    return .red
        case "purple": return .purple
        case "teal":   return .teal
        case "indigo": return .indigo
        case "pink":   return .pink
        default:       return .gray
        }
    }
}

// MARK: - Large Widget (345x370)

struct LargeWidgetView: View {
    let data: SharedWidgetData
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    widgetColor.opacity(0.3),
                    widgetColor.opacity(0.1),
                    Color.black.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(widgetColor.opacity(0.3))
                            .frame(width: 40, height: 40)
                        Image(systemName: "network")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(widgetColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(data.activeDNSName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Active DNS Resolver")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(.green)
                        .frame(width: 10, height: 10)
                        .shadow(color: .green.opacity(0.6), radius: 4)
                }
                
                LinearGradient(
                    colors: [.white.opacity(0.05), .white.opacity(0.15), .white.opacity(0.05)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 0.5)
                
                VStack(alignment: .leading, spacing: 8) {
                    dnsInfoRow(icon: "globe", label: "Primary", value: data.primaryDNS)
                    if data.hasSecondary {
                        dnsInfoRow(icon: "globe.badge.chevronleft", label: "Secondary", value: data.secondaryDNS)
                    }
                    dnsInfoRow(icon: "wifi", label: "Interface", value: data.networkService)
                }
                .padding(12)
                .background(.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                )
                
                Spacer()
                
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 8))
                    Text("Updated \(data.formattedTime)")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                    
                    Spacer()
                    
                    Image(systemName: "network")
                        .font(.system(size: 8))
                    Text("DNS Widget")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                }
                .foregroundStyle(.white.opacity(0.35))
            }
            .padding(16)
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private func dnsInfoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(widgetColor.opacity(0.8))
                .frame(width: 16)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 60, alignment: .leading)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
            
            Spacer()
        }
    }
    
    private var widgetColor: Color {
        switch data.colorName {
        case "blue":   return .blue
        case "green":  return .green
        case "orange": return .orange
        case "red":    return .red
        case "purple": return .purple
        case "teal":   return .teal
        case "indigo": return .indigo
        case "pink":   return .pink
        default:       return .gray
        }
    }
}
