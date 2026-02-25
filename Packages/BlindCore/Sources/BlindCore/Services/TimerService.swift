import Foundation

public class TimerService {
    public var onTimerFired: (() -> Void)?

    private var timer: Timer?

    public var intervalMinutes: Int {
        let stored = UserDefaults.standard.integer(forKey: "reminderInterval")
        return stored > 0 ? stored : 30
    }

    public init() {}

    public func start() {
        scheduleTimer()
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func reset() {
        stop()
        start()
    }

    private func scheduleTimer() {
        timer?.invalidate()

        let interval = TimeInterval(intervalMinutes * 60)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.onTimerFired?()
        }
    }
}
