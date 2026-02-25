import XCTest
@testable import BlindCore

final class BlindCoreTests: XCTestCase {

    func testBlindSettingsDefaults() {
        let settings = BlindSettings()
        XCTAssertEqual(settings.reminderInterval, 30)
        XCTAssertEqual(settings.eyeCloseDuration, 5)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testTimerServiceInitialization() {
        let timerService = TimerService()
        XCTAssertEqual(timerService.intervalMinutes, 30)
    }

    func testEyeDetectionServiceInitialization() {
        let eyeDetectionService = EyeDetectionService()
        XCTAssertNotNil(eyeDetectionService)
    }

    func testNonZeroOrExtension() {
        XCTAssertEqual(0.nonZeroOr(5), 5)
        XCTAssertEqual(10.nonZeroOr(5), 10)
        XCTAssertEqual((-1).nonZeroOr(5), -1)
    }
}
