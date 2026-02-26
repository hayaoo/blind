import XCTest
@testable import BlindCore

final class SessionPhaseTests: XCTestCase {

    // MARK: - 正常遷移パス

    func testNormalTransitionPath() {
        // summon → encounter
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .summon, trigger: .animationCompleted),
            .encounter
        )
        // encounter → immersion
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .encounter, trigger: .eyesClosedDurationMet),
            .immersion
        )
        // immersion → awakening
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .immersion, trigger: .immersionTimerCompleted),
            .awakening
        )
        // awakening → completed
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .awakening, trigger: .animationCompleted),
            .completed
        )
    }

    // MARK: - キャンセル遷移

    func testCancelFromSummon() {
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .summon, trigger: .userCancelled),
            .cancelled
        )
    }

    func testCancelFromEncounter() {
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .encounter, trigger: .userCancelled),
            .cancelled
        )
    }

    func testCancelFromImmersion() {
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .immersion, trigger: .userCancelled),
            .cancelled
        )
    }

    func testCancelFromAwakening() {
        XCTAssertEqual(
            SessionPhaseTransition.next(from: .awakening, trigger: .userCancelled),
            .cancelled
        )
    }

    // MARK: - idle/completed/cancelledからのキャンセルはnil

    func testCancelFromIdleReturnsNil() {
        XCTAssertNil(
            SessionPhaseTransition.next(from: .idle, trigger: .userCancelled)
        )
    }

    func testCancelFromCompletedReturnsNil() {
        XCTAssertNil(
            SessionPhaseTransition.next(from: .completed, trigger: .userCancelled)
        )
    }

    func testCancelFromCancelledReturnsNil() {
        XCTAssertNil(
            SessionPhaseTransition.next(from: .cancelled, trigger: .userCancelled)
        )
    }

    // MARK: - 不正遷移

    func testInvalidTransitionFromIdle() {
        XCTAssertNil(SessionPhaseTransition.next(from: .idle, trigger: .animationCompleted))
        XCTAssertNil(SessionPhaseTransition.next(from: .idle, trigger: .eyesClosedDurationMet))
        XCTAssertNil(SessionPhaseTransition.next(from: .idle, trigger: .immersionTimerCompleted))
    }

    func testInvalidTransitionFromCompleted() {
        XCTAssertNil(SessionPhaseTransition.next(from: .completed, trigger: .animationCompleted))
        XCTAssertNil(SessionPhaseTransition.next(from: .completed, trigger: .eyesClosedDurationMet))
        XCTAssertNil(SessionPhaseTransition.next(from: .completed, trigger: .immersionTimerCompleted))
    }

    func testInvalidTransitionWrongTrigger() {
        // summonにeyesClosedDurationMetは無効
        XCTAssertNil(SessionPhaseTransition.next(from: .summon, trigger: .eyesClosedDurationMet))
        // encounterにanimationCompletedは無効
        XCTAssertNil(SessionPhaseTransition.next(from: .encounter, trigger: .animationCompleted))
        // immersionにanimationCompletedは無効
        XCTAssertNil(SessionPhaseTransition.next(from: .immersion, trigger: .animationCompleted))
        // awakeningにimmersionTimerCompletedは無効
        XCTAssertNil(SessionPhaseTransition.next(from: .awakening, trigger: .immersionTimerCompleted))
    }
}
