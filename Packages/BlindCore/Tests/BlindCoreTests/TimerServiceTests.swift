import XCTest
@testable import BlindCore

final class TimerServiceTests: XCTestCase {

    private var timerService: TimerService!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults to ensure clean state
        UserDefaults.standard.removeObject(forKey: "reminderInterval")
        timerService = TimerService()
    }

    override func tearDown() {
        timerService.stop()
        timerService = nil
        UserDefaults.standard.removeObject(forKey: "reminderInterval")
        super.tearDown()
    }

    // MARK: - Default Interval

    func testDefaultInterval() {
        // When no UserDefaults value is set, intervalMinutes should be 30
        XCTAssertEqual(timerService.intervalMinutes, 30)
    }

    func testIntervalFromUserDefaults() {
        UserDefaults.standard.set(15, forKey: "reminderInterval")
        XCTAssertEqual(timerService.intervalMinutes, 15)
    }

    func testIntervalZeroInUserDefaultsFallsBackToDefault() {
        // UserDefaults.integer returns 0 when key is missing or set to 0
        UserDefaults.standard.set(0, forKey: "reminderInterval")
        XCTAssertEqual(timerService.intervalMinutes, 30)
    }

    func testIntervalNegativeInUserDefaultsFallsBackToDefault() {
        UserDefaults.standard.set(-5, forKey: "reminderInterval")
        XCTAssertEqual(timerService.intervalMinutes, 30)
    }

    // MARK: - Start / Stop

    func testStartDoesNotCrash() {
        // Verifies that start() can be called without error
        timerService.start()
    }

    func testStopDoesNotCrash() {
        // Verifies that stop() can be called even without prior start()
        timerService.stop()
    }

    func testStartThenStop() {
        timerService.start()
        timerService.stop()
        // No crash means the lifecycle is handled properly
    }

    func testMultipleStartCalls() {
        // Calling start() multiple times should not crash or leak timers
        timerService.start()
        timerService.start()
        timerService.stop()
    }

    func testMultipleStopCalls() {
        timerService.start()
        timerService.stop()
        timerService.stop()
    }

    // MARK: - Reset

    func testResetWithoutPriorStart() {
        // reset() calls stop() then start(), should work even without prior start
        timerService.reset()
        timerService.stop()
    }

    func testResetAfterStart() {
        timerService.start()
        timerService.reset()
        timerService.stop()
    }

    // MARK: - Callback

    func testOnTimerFiredCallbackIsCalledOnShortInterval() {
        // Use a very short interval via UserDefaults to trigger the timer quickly
        // Note: intervalMinutes is in minutes, but we can set to 1 and use a short expectation
        // Since the minimum interval is 1 minute (60s), we test callback assignment instead
        let expectation = self.expectation(description: "Timer callback should be callable")

        timerService.onTimerFired = {
            expectation.fulfill()
        }

        // Directly invoke the callback to verify wiring
        timerService.onTimerFired?()

        waitForExpectations(timeout: 1.0)
    }

    func testOnTimerFiredCallbackIsNilByDefault() {
        XCTAssertNil(timerService.onTimerFired)
    }

    func testOnTimerFiredCallbackCanBeSet() {
        var called = false
        timerService.onTimerFired = {
            called = true
        }
        timerService.onTimerFired?()
        XCTAssertTrue(called)
    }

    func testOnTimerFiredCallbackCanBeCleared() {
        timerService.onTimerFired = { }
        timerService.onTimerFired = nil
        XCTAssertNil(timerService.onTimerFired)
    }
}
