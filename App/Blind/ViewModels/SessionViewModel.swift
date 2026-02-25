import Foundation
import Combine
import BlindCore

@MainActor
class SessionViewModel: ObservableObject {
    @Published var eyesClosed = false
    @Published var closedDuration: TimeInterval = 0
    @Published var isActive = false

    var onSessionComplete: (() -> Void)?

    var requiredClosedDuration: TimeInterval {
        TimeInterval(UserDefaults.standard.integer(forKey: "eyeCloseDuration").nonZeroOr(5))
    }

    var closedProgress: Double {
        min(closedDuration / requiredClosedDuration, 1.0)
    }

    private var eyeDetectionService: EyeDetectionService?
    private var closedTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func startSession() {
        isActive = true
        closedDuration = 0

        eyeDetectionService = EyeDetectionService()
        eyeDetectionService?.onEyeStateChanged = { [weak self] closed in
            Task { @MainActor in
                self?.handleEyeStateChange(closed: closed)
            }
        }
        eyeDetectionService?.start()
    }

    func stopSession() {
        isActive = false
        closedTimer?.invalidate()
        closedTimer = nil
        eyeDetectionService?.stop()
        eyeDetectionService = nil
    }

    func cancelSession() {
        stopSession()
        onSessionComplete?()
    }

    private func handleEyeStateChange(closed: Bool) {
        let wasOpen = !eyesClosed
        eyesClosed = closed

        if closed && wasOpen {
            // Started closing eyes
            startClosedTimer()
        } else if !closed && !wasOpen {
            // Opened eyes - reset timer
            resetClosedTimer()
        }
    }

    private func startClosedTimer() {
        closedTimer?.invalidate()
        closedDuration = 0

        closedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateClosedDuration()
            }
        }
    }

    private func resetClosedTimer() {
        closedTimer?.invalidate()
        closedTimer = nil
        closedDuration = 0
    }

    private func updateClosedDuration() {
        guard eyesClosed else { return }

        closedDuration += 0.1

        if closedDuration >= requiredClosedDuration {
            completeSession()
        }
    }

    private func completeSession() {
        stopSession()
        onSessionComplete?()
    }
}
