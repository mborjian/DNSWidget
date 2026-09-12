import Foundation

final class WidgetCommandBridge: @unchecked Sendable {
    static let shared = WidgetCommandBridge()

    private let storage: StorageService
    private let network: NetworkService
    private let queue = DispatchQueue(label: "com.dnswidget.widget-commands")
    private let errorLock = NSLock()

    private var isObserving = false
    private var pollTimer: DispatchSourceTimer?
    private var isBusy = false
    private var storedError: String?

    var errorMessage: String? {
        errorLock.lock()
        defer { errorLock.unlock() }
        return storedError
    }

    init(storage: StorageService = .shared, network: NetworkService = .shared) {
        self.storage = storage
        self.network = network
    }

    func start() {
        observeCommands()
        startPolling()
    }

    private func observeCommands() {
        guard !isObserving else { return }
        isObserving = true

        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { _, _, _, _, _ in
                WidgetCommandBridge.shared.queue.async {
                    WidgetCommandBridge.shared.processPendingCommand()
                }
            },
            WidgetDataManager.commandNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func startPolling() {
        queue.async { [weak self] in
            guard let self, self.pollTimer == nil else { return }

            let timer = DispatchSource.makeTimerSource(queue: self.queue)
            timer.schedule(deadline: .now(), repeating: 1.5, leeway: .milliseconds(400))
            timer.setEventHandler { [weak self] in
                self?.processPendingCommand()
            }
            self.pollTimer = timer
            timer.resume()
        }
    }

    private func processPendingCommand() {
        guard !isBusy, let command = WidgetDataManager.shared.pendingCommand() else { return }
        WidgetDataManager.shared.clearPendingCommand()
        isBusy = true
        apply(command)
    }

    private func apply(_ command: WidgetCommand) {
        let service = network.activeService.isEmpty
            ? network.getPrimaryService(from: network.getNetworkServices())
            : network.activeService

        switch command.action {
        case .apply:
            guard let id = command.serverID,
                  let server = storage.allServers().first(where: { $0.id.uuidString == id })
            else {
                finish(error: "That DNS server no longer exists")
                return
            }

            guard network.setDNS(server, for: service) else {
                finish(error: "macOS refused the DNS change")
                return
            }

            verifyApplied(expected: server.servers, attempt: 0)

        case .reset:
            guard network.resetDNS(for: service) else {
                finish(error: "macOS refused the DNS change")
                return
            }

            verifyReset(service: service, attempt: 0)
        }
    }

    private func verifyApplied(expected: [String], attempt: Int) {
        queue.asyncAfter(deadline: .now() + delay(for: attempt)) { [weak self] in
            guard let self else { return }

            if Set(self.network.resolvedServers()) == Set(expected) {
                self.finish(error: nil)
            } else if attempt < 2 {
                self.verifyApplied(expected: expected, attempt: attempt + 1)
            } else {
                self.finish(error: "DNS didn't switch")
            }
        }
    }

    private func verifyReset(service: String, attempt: Int) {
        queue.asyncAfter(deadline: .now() + delay(for: attempt)) { [weak self] in
            guard let self else { return }

            if self.network.configuredServers(for: service) == nil {
                self.finish(error: nil)
            } else if attempt < 2 {
                self.verifyReset(service: service, attempt: attempt + 1)
            } else {
                self.finish(error: "DNS didn't switch")
            }
        }
    }

    private func delay(for attempt: Int) -> TimeInterval {
        attempt == 0 ? 0.8 : 1.5
    }

    private func finish(error: String?) {
        errorLock.lock()
        storedError = error
        errorLock.unlock()

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            WidgetDataManager.shared.syncFromNetwork(network: self.network, storage: self.storage)
            self.queue.async { self.isBusy = false }
        }
    }
}
