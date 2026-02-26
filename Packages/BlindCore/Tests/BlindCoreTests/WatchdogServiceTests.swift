import XCTest
@testable import BlindCore

final class WatchdogServiceTests: XCTestCase {

    private var watchdog: WatchdogService!

    override func setUp() {
        super.setUp()
        watchdog = WatchdogService()
    }

    override func tearDown() {
        watchdog.stop()
        watchdog = nil
        super.tearDown()
    }

    // MARK: - Init

    func testDefaultValues() {
        XCTAssertEqual(watchdog.checkInterval, 2.0)
        XCTAssertEqual(watchdog.timeout, 10.0)
        XCTAssertFalse(watchdog.isRunning)
        XCTAssertNil(watchdog.onMainThreadHung)
    }

    func testCustomValues() {
        let custom = WatchdogService(checkInterval: 1.0, timeout: 5.0)
        XCTAssertEqual(custom.checkInterval, 1.0)
        XCTAssertEqual(custom.timeout, 5.0)
    }

    // MARK: - Start / Stop

    func testStartSetsIsRunning() {
        watchdog.start()
        XCTAssertTrue(watchdog.isRunning)
    }

    func testStopClearsIsRunning() {
        watchdog.start()
        watchdog.stop()
        XCTAssertFalse(watchdog.isRunning)
    }

    func testStopWithoutStartDoesNotCrash() {
        watchdog.stop()
        XCTAssertFalse(watchdog.isRunning)
    }

    func testDoubleStartDoesNotCrash() {
        watchdog.start()
        watchdog.start()
        XCTAssertTrue(watchdog.isRunning)
        watchdog.stop()
    }

    func testDoubleStopDoesNotCrash() {
        watchdog.start()
        watchdog.stop()
        watchdog.stop()
        XCTAssertFalse(watchdog.isRunning)
    }

    func testStartStopStart() {
        watchdog.start()
        watchdog.stop()
        watchdog.start()
        XCTAssertTrue(watchdog.isRunning)
    }

    // MARK: - Callback

    func testOnMainThreadHungCallbackIsNilByDefault() {
        XCTAssertNil(watchdog.onMainThreadHung)
    }

    func testOnMainThreadHungCallbackCanBeSet() {
        var called = false
        watchdog.onMainThreadHung = {
            called = true
        }
        watchdog.onMainThreadHung?()
        XCTAssertTrue(called)
    }

    func testOnMainThreadHungCallbackCanBeCleared() {
        watchdog.onMainThreadHung = { }
        watchdog.onMainThreadHung = nil
        XCTAssertNil(watchdog.onMainThreadHung)
    }

    // MARK: - Lifecycle Stress

    func testRapidStartStop() {
        for _ in 0..<100 {
            watchdog.start()
            watchdog.stop()
        }
        XCTAssertFalse(watchdog.isRunning)
    }

    func testDeallocWhileRunning() {
        var service: WatchdogService? = WatchdogService(checkInterval: 0.1, timeout: 0.5)
        service?.start()
        XCTAssertTrue(service?.isRunning == true)
        service?.stop()
        service = nil
        // No crash on dealloc
    }
}
