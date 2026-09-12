import SwiftUI
import WidgetKit

extension DNSColorName {
    var color: Color {
        switch self {
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        case .red:    return .red
        case .purple: return .purple
        case .teal:   return .teal
        case .indigo: return .indigo
        case .pink:   return .pink
        case .gray:   return .gray
        }
    }
}

struct DNSWidgetEntryView: View {
    var entry: DNSWidgetEntry

    @Environment(\.widgetFamily) private var family

    private var accent: Color {
        let server = entry.data.activeServer
        return server?.color.color ?? (entry.data.isAutomatic ? .accentColor : .gray)
    }

    var body: some View {
        content
            .containerBackground(for: .widget) {
                WidgetSurface(accent: accent)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch family {
        case .systemMedium:
            MediumWidgetView(data: entry.data)
        case .systemLarge:
            LargeWidgetView(data: entry.data)
        default:
            SmallWidgetView(data: entry.data)
        }
    }
}

struct WidgetSurface: View {
    let accent: Color

    var body: some View {
        ZStack {
            Rectangle().fill(.background.secondary)
            LinearGradient(
                colors: [accent.opacity(0.26), accent.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct SmallWidgetView: View {
    let data: SharedWidgetData

    private var accent: Color {
        data.activeServer?.color.color ?? (data.isAutomatic ? .accentColor : .gray)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(accent: accent, status: data.isAutomatic ? "Automatic" : "Active")

            Spacer(minLength: 8)

            Text(data.activeDNSName)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .foregroundStyle(.primary)

            DNSAddressBlock(data: data, ipSize: 10)
                .padding(.top, 4)

            if let error = data.lastError {
                ErrorNotice(message: error)
                    .padding(.top, 4)
            }

            Spacer(minLength: 8)

            WidgetFooter(service: data.networkService, time: data.formattedTime)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
    }
}

struct MediumWidgetView: View {
    let data: SharedWidgetData

    private var accent: Color {
        data.activeServer?.color.color ?? (data.isAutomatic ? .accentColor : .gray)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            StatusColumn(data: data, accent: accent)
                .frame(maxWidth: .infinity, alignment: .topLeading)

            ServerColumn(data: data, limit: 3, includesReset: true)
                .frame(width: 132)
        }
        .padding(14)
    }
}

struct LargeWidgetView: View {
    let data: SharedWidgetData

    private var accent: Color {
        data.activeServer?.color.color ?? (data.isAutomatic ? .accentColor : .gray)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusColumn(data: data, accent: accent)

            ThinRule()

            Text("SWITCH TO")
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(.tertiary)

            ServerColumn(data: data, limit: 5, includesReset: true)

            Spacer(minLength: 0)

            WidgetFooter(service: data.networkService, time: data.formattedTime)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(16)
    }
}

struct StatusColumn: View {
    let data: SharedWidgetData
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            WidgetHeader(accent: accent, status: data.isAutomatic ? "Automatic" : "Active")

            Text(data.activeDNSName)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .padding(.top, 10)

            DNSAddressBlock(data: data, ipSize: 11)
                .padding(.top, 5)

            if let error = data.lastError {
                ErrorNotice(message: error)
                    .padding(.top, 6)
            }
        }
    }
}

struct DNSAddressBlock: View {
    let data: SharedWidgetData
    var ipSize: CGFloat = 11

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if data.isAutomatic {
                Text("From your router")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            if !data.primaryDNS.isEmpty {
                Text(data.primaryDNS)
                if data.hasSecondary {
                    Text(data.secondaryDNS).foregroundStyle(.tertiary)
                }
            }
        }
        .font(.system(size: ipSize, weight: .medium, design: .monospaced))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
}

struct WidgetHeader: View {
    let accent: Color
    let status: String

    var body: some View {
        HStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(accent.opacity(0.20))
                Image(systemName: "network")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(accent)
            }
            .frame(width: 20, height: 20)
            .widgetAccentable()

            Text(status.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.7)
                .foregroundStyle(.secondary)
        }
    }
}

struct WidgetFooter: View {
    let service: String
    let time: String

    var body: some View {
        HStack(spacing: 5) {
            if !service.isEmpty {
                Image(systemName: "wifi").font(.system(size: 8, weight: .semibold))
                Text(service)
                Text("•").font(.system(size: 8))
            }
            Image(systemName: "arrow.clockwise").font(.system(size: 8, weight: .semibold))
            Text(time)

            Spacer(minLength: 0)
        }
        .font(.system(size: 9, weight: .medium))
        .foregroundStyle(.tertiary)
        .lineLimit(1)
    }
}

struct ErrorNotice: View {
    let message: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 9, weight: .semibold))
            Text(message)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.orange)
    }
}

struct ThinRule: View {
    var body: some View {
        Rectangle()
            .fill(.primary.opacity(0.08))
            .frame(height: 0.5)
    }
}

struct ServerColumn: View {
    let data: SharedWidgetData
    let limit: Int
    let includesReset: Bool

    private var rows: [SharedDNSServer] {
        guard let activeID = data.activeServerID,
              let active = data.servers.first(where: { $0.id == activeID })
        else { return Array(data.servers.prefix(limit)) }

        let rest = data.servers.filter { $0.id != activeID }
        let slots = max(limit - 1, 0)
        return [active] + rest.prefix(slots)
    }

    var body: some View {
        VStack(spacing: 4) {
            if rows.isEmpty {
                EmptyServerHint()
            } else {
                ForEach(rows) { server in
                    ServerButton(
                        server: server,
                        isActive: server.id == data.activeServerID,
                        isApplying: data.isApplying(server.id)
                    )
                }
            }

            if includesReset {
                ResetButton(isApplying: data.isResetting)
            }
        }
    }
}

struct ServerButton: View {
    let server: SharedDNSServer
    let isActive: Bool
    let isApplying: Bool

    var body: some View {
        Button(intent: ApplyDNSServerIntent(serverID: server.id)) {
            HStack(spacing: 8) {
                Circle()
                    .fill(server.color.color)
                    .frame(width: 7, height: 7)

                VStack(alignment: .leading, spacing: 1) {
                    Text(server.name)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    if isApplying {
                        Text("Applying…")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(server.color.color)
                            .lineLimit(1)
                    } else {
                        Text(server.primaryDNS)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                if isApplying {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(server.color.color)
                        .widgetAccentable()
                } else if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(server.color.color)
                        .widgetAccentable()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowFill)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: isActive || isApplying ? 1 : 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rowFill: Color {
        isActive || isApplying ? server.color.color.opacity(0.14) : Color.primary.opacity(0.04)
    }

    private var borderColor: Color {
        isActive || isApplying ? server.color.color.opacity(0.55) : Color.primary.opacity(0.07)
    }
}

struct ResetButton: View {
    let isApplying: Bool

    var body: some View {
        Button(intent: ResetDNSIntent()) {
            HStack(spacing: 8) {
                Image(systemName: isApplying ? "clock.arrow.circlepath" : "arrow.uturn.backward")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(isApplying ? .orange : .secondary)
                    .frame(width: 7)

                Text(isApplying ? "Applying…" : "Automatic (DHCP)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(isApplying ? .orange : .secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isApplying ? Color.orange.opacity(0.12) : Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyServerHint: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "plus.circle")
                .font(.system(size: 9, weight: .semibold))
            Text("Open the app to add servers")
                .font(.system(size: 10, weight: .medium))
                .lineLimit(2)
        }
        .foregroundStyle(.tertiary)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
