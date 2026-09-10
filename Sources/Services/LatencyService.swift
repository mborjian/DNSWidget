import Foundation
import SwiftUI

final class LatencyService: ObservableObject, @unchecked Sendable {
    static let shared = LatencyService()
    
    @Published var latencies: [String: Double?] = [:]
    
    @Published var isTesting = false
    
    private let queue = DispatchQueue(label: "com.dnswidget.latency", qos: .userInitiated)
    
    // MARK: - Public
    
    func measureOne(_ ip: String, timeout: TimeInterval = 3) async -> Double? {
        let service = self
        return await withCheckedContinuation { cont in
            service.queue.async {
                let result = service.ping(ip: ip, count: 3, timeout: timeout)
                DispatchQueue.main.async {
                    service.latencies[ip] = result
                }
                cont.resume(returning: result)
            }
        }
    }
    
    func testAll(_ servers: [DNSServer]) {
        guard !isTesting else { return }
        isTesting = true
        
        for server in servers {
            latencies[server.primaryDNS] = nil
            if !server.secondaryDNS.isEmpty {
                latencies[server.secondaryDNS] = nil
            }
        }
        
        let group = DispatchGroup()
        
        for server in servers {
            group.enter()
            queue.async {
                let primary = self.ping(ip: server.primaryDNS, count: 3, timeout: 3)
                DispatchQueue.main.async {
                    self.latencies[server.primaryDNS] = primary
                }
                
                if !server.secondaryDNS.isEmpty {
                    let secondary = self.ping(ip: server.secondaryDNS, count: 3, timeout: 3)
                    DispatchQueue.main.async {
                        self.latencies[server.secondaryDNS] = secondary
                    }
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.isTesting = false
        }
    }
    
    func bestLatency(for server: DNSServer) -> Double? {
        let p = latencies[server.primaryDNS] ?? nil
        let s = server.secondaryDNS.isEmpty ? nil : (latencies[server.secondaryDNS] ?? nil)
        
        switch (p, s) {
        case let (p?, s?): return min(p, s)
        case let (p?, nil): return p
        case let (nil, s?): return s
        case (nil, nil): return nil
        }
    }
    
    // MARK: - Private
    
    private func ping(ip: String, count: Int = 3, timeout: TimeInterval = 3) -> Double? {
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "\(count)", "-W", "\(Int(timeout))", ip]
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            if let avgLine = output.components(separatedBy: "\n")
                .first(where: { $0.contains("avg") }),
               let avgString = avgLine.components(separatedBy: "=")
                .last?
                .components(separatedBy: "/")
                .dropFirst().first,
               let avg = Double(avgString) {
                return avg
            }
            return nil
        } catch {
            return nil
        }
    }
}

// MARK: - Latency Formatting Helpers

extension Double {
    var latencyFormatted: String {
        if self < 1000 {
            return String(format: "%.0fms", self)
        } else {
            return String(format: "%.1fs", self / 1000)
        }
    }
    
    var latencyColor: Color {
        switch self {
        case 0..<30:    return .green
        case 30..<80:   return .yellow
        case 80..<200:  return .orange
        default:        return .red
        }
    }
}
