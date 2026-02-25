import Foundation

class TimerService {
    var onTimerFired: (() -> Void)?

    private var timer: Timer?

    var intervalMinutes: Int {
        let stored = UserDefaults.standard.integer(forKey: "reminderInterval")
        return stored > 0 ? stored : 30
    }

    func start() {
        scheduleTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func reset() {
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
