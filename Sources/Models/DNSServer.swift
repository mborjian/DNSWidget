import Foundation
import SwiftUI

struct DNSServer: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var primaryDNS: String
    var secondaryDNS: String
    var color: DNSColor
    var isPinned: Bool
    var isPreset: Bool
    var dateAdded: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, primaryDNS, secondaryDNS, color
        case isPinned = "isFavorite"
        case isPreset, dateAdded
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        primaryDNS: String,
        secondaryDNS: String = "",
        color: DNSColor = .blue,
        isPinned: Bool = false,
        isPreset: Bool = false
    ) {
        self.id = id
        self.name = name
        self.primaryDNS = primaryDNS
        self.secondaryDNS = secondaryDNS
        self.color = color
        self.isPinned = isPinned
        self.isPreset = isPreset
        self.dateAdded = Date()
    }
    
    var primaryAddress: String? {
        IPAddressFormatter.validate(primaryDNS) ? primaryDNS : nil
    }
    
    var secondaryAddress: String? {
        secondaryDNS.isEmpty ? nil : (IPAddressFormatter.validate(secondaryDNS) ? secondaryDNS : nil)
    }
    
    var servers: [String] {
        var list: [String] = [primaryDNS]
        if !secondaryDNS.isEmpty { list.append(secondaryDNS) }
        return list
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DNSServer, rhs: DNSServer) -> Bool {
        lhs.id == rhs.id
    }
}

enum DNSColor: String, Codable, CaseIterable {
    case blue, green, orange, red, purple, teal, indigo, pink
    
    var color: Color {
        switch self {
        case .blue:    return .blue
        case .green:   return .green
        case .orange:  return .orange
        case .red:     return .red
        case .purple:  return .purple
        case .teal:    return .teal
        case .indigo:  return .indigo
        case .pink:    return .pink
        }
    }
    
    var gradient: LinearGradient {
        LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct IPAddressFormatter {
    static func validate(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part) else { return false }
            return num >= 0 && num <= 255
        }
    }
}

// MARK: - Preset DNS Servers

extension DNSServer {
    static let presets: [DNSServer] = [
        DNSServer(
            name: "Google DNS",
            primaryDNS: "8.8.8.8",
            secondaryDNS: "8.8.4.4",
            color: .blue,
            isPinned: true,
            isPreset: true
        ),
        DNSServer(
            name: "Cloudflare",
            primaryDNS: "1.1.1.1",
            secondaryDNS: "1.0.0.1",
            color: .orange,
            isPinned: true,
            isPreset: true
        ),
        DNSServer(
            name: "Quad9",
            primaryDNS: "9.9.9.9",
            secondaryDNS: "149.112.112.112",
            color: .purple,
            isPinned: true,
            isPreset: true
        ),
        DNSServer(
            name: "OpenDNS",
            primaryDNS: "208.67.222.222",
            secondaryDNS: "208.67.220.220",
            color: .green,
            isPinned: true,
            isPreset: true
        ),
        DNSServer(
            name: "AdGuard DNS",
            primaryDNS: "94.140.14.14",
            secondaryDNS: "94.140.15.15",
            color: .teal,
            isPinned: true,
            isPreset: true
        ),
        DNSServer(
            name: "NextDNS",
            primaryDNS: "45.90.28.0",
            secondaryDNS: "45.90.30.0",
            color: .indigo,
            isPreset: true
        ),
        DNSServer(
            name: "Comodo Secure",
            primaryDNS: "8.26.56.26",
            secondaryDNS: "8.20.247.20",
            color: .red,
            isPreset: true
        ),
        DNSServer(
            name: "Level3",
            primaryDNS: "4.2.2.1",
            secondaryDNS: "4.2.2.2",
            color: .pink,
            isPreset: true
        ),
    ]
}
