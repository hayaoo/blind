import XCTest
@testable import BlindCore

final class EyeDetectionServiceTests: XCTestCase {

    private var service: EyeDetectionService!

    override func setUp() {
        super.setUp()
        service = EyeDetectionService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Initialization

    func testInitialization() {
        XCTAssertNotNil(service)
    }

    func testInitialEarThreshold() {
        XCTAssertEqual(service.earThreshold, 0.2, accuracy: 0.001)
    }

    func testOnEyeStateChangedIsNilByDefault() {
        XCTAssertNil(service.onEyeStateChanged)
    }

    // MARK: - EAR Threshold

    func testEarThresholdCanBeModified() {
        service.earThreshold = 0.15
        XCTAssertEqual(service.earThreshold, 0.15, accuracy: 0.001)
    }

    func testEarThresholdAcceptsZero() {
        service.earThreshold = 0.0
        XCTAssertEqual(service.earThreshold, 0.0, accuracy: 0.001)
    }

    func testEarThresholdAcceptsHighValue() {
        service.earThreshold = 0.5
        XCTAssertEqual(service.earThreshold, 0.5, accuracy: 0.001)
    }

    // MARK: - EyeState Enum

    func testEyeStateEnumHasOpenCase() {
        let state: EyeState = .open
        if case .open = state {
            // pass
        } else {
            XCTFail("Expected .open")
        }
    }

    func testEyeStateEnumHasClosedCase() {
        let state: EyeState = .closed
        if case .closed = state {
            // pass
        } else {
            XCTFail("Expected .closed")
        }
    }

    func testEyeStateEnumHasNoFaceCase() {
        let state: EyeState = .noFace
        if case .noFace = state {
            // pass
        } else {
            XCTFail("Expected .noFace")
        }
    }

    // MARK: - Callback Wiring

    func testOnEyeStateChangedCanBeSet() {
        var receivedState: EyeState?
        service.onEyeStateChanged = { state in
            receivedState = state
        }
        service.onEyeStateChanged?(.closed)
        if case .closed = receivedState {
            // pass
        } else {
            XCTFail("Expected .closed, got \(String(describing: receivedState))")
        }
    }

    func testOnEyeStateChangedCanBeCleared() {
        service.onEyeStateChanged = { _ in }
        service.onEyeStateChanged = nil
        XCTAssertNil(service.onEyeStateChanged)
    }

    func testOnEyeStateChangedReportsOpenEyes() {
        var receivedState: EyeState?
        service.onEyeStateChanged = { state in
            receivedState = state
        }
        service.onEyeStateChanged?(.open)
        if case .open = receivedState {
            // pass
        } else {
            XCTFail("Expected .open, got \(String(describing: receivedState))")
        }
    }

    func testOnEyeStateChangedReportsNoFace() {
        var receivedState: EyeState?
        service.onEyeStateChanged = { state in
            receivedState = state
        }
        service.onEyeStateChanged?(.noFace)
        if case .noFace = receivedState {
            // pass
        } else {
            XCTFail("Expected .noFace, got \(String(describing: receivedState))")
        }
    }

    // MARK: - Multiple Instances

    func testMultipleInstancesAreIndependent() {
        let service2 = EyeDetectionService()
        service.earThreshold = 0.3
        // service2 should retain the default value
        XCTAssertEqual(service2.earThreshold, 0.2, accuracy: 0.001)
    }
}
