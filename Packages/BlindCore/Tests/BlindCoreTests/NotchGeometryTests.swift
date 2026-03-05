import XCTest
@testable import BlindCore

final class NotchGeometryTests: XCTestCase {

    // MARK: - Test Fixtures

    /// MacBook Pro (ノッチあり)
    static let macbook = NotchGeometry(
        screenWidth: 1728,
        screenHeight: 1117,
        safeAreaInsetsTop: 37,
        auxiliaryTopLeftWidth: 420,
        auxiliaryTopRightWidth: 420
    )

    /// iMac (ノッチなし)
    static let imac = NotchGeometry(
        screenWidth: 2560,
        screenHeight: 1440,
        safeAreaInsetsTop: 0,
        auxiliaryTopLeftWidth: 0,
        auxiliaryTopRightWidth: 0
    )

    // MARK: - hasNotch

    func testHasNotch_withNotch() {
        XCTAssertTrue(Self.macbook.hasNotch)
    }

    func testHasNotch_withoutNotch() {
        XCTAssertFalse(Self.imac.hasNotch)
    }

    // MARK: - notchWidth / notchHeight

    func testNotchWidth_macbook() {
        // 1728 - 420 - 420 = 888
        XCTAssertEqual(Self.macbook.notchWidth, 888)
    }

    func testNotchHeight_macbook() {
        XCTAssertEqual(Self.macbook.notchHeight, 37)
    }

    func testNotchWidth_imac() {
        XCTAssertEqual(Self.imac.notchWidth, 2560)
    }

    func testNotchHeight_imac() {
        XCTAssertEqual(Self.imac.notchHeight, 0)
    }

    // MARK: - notchRect

    func testNotchRect_macbook() {
        let rect = Self.macbook.notchRect
        XCTAssertEqual(rect, CGRect(x: 420, y: 1080, width: 888, height: 37))
    }

    // MARK: - displayMode

    func testDisplayMode_notch() {
        XCTAssertEqual(Self.macbook.displayMode, .notch)
    }

    func testDisplayMode_noNotch() {
        XCTAssertEqual(Self.imac.displayMode, .noNotch)
    }

    // MARK: - summonFrame

    func testSummonFrame_notch() {
        let frame = Self.macbook.summonFrame
        let cr = NotchGeometry.concaveRadius
        // 物理ノッチ下に配置: ノッチ幅+cr*2 パディング、上部にノッチ高さ分余白
        XCTAssertEqual(frame.width, Self.macbook.notchWidth + cr * 2)
        XCTAssertTrue(frame.height > Self.macbook.notchHeight)
        // ウィンドウ上端 + ノッチ高さ = 物理ノッチの上端位置
        XCTAssertEqual(frame.origin.y + frame.height, Self.macbook.screenHeight)
    }

    func testSummonFrame_noNotch() {
        let frame = Self.imac.summonFrame
        let cr = NotchGeometry.concaveRadius
        // 280 + cr*2 のパディング付き、スクリーン上端に配置
        XCTAssertEqual(frame.width, 280 + cr * 2)
        XCTAssertEqual(frame.height, 70)
        // 上端がスクリーン上端に一致
        XCTAssertEqual(frame.origin.y + frame.height, Self.imac.screenHeight)
        // 水平中央
        XCTAssertEqual(frame.origin.x + frame.width / 2, Self.imac.screenWidth / 2)
    }

    func testSummonFrame_notch_horizontalCenter() {
        let frame = Self.macbook.summonFrame
        let notchCenter = Self.macbook.notchRect.origin.x + Self.macbook.notchRect.width / 2
        let frameCenter = frame.origin.x + frame.width / 2
        XCTAssertEqual(frameCenter, notchCenter, accuracy: 1)
    }

    // MARK: - encounterFrame

    func testEncounterFrame_extendsSummonFrame() {
        let ext = NotchGeometry.gapHeight + NotchGeometry.textBarHeight  // 12 + 54 = 66

        for geo in [Self.macbook, Self.imac] {
            let summon = geo.summonFrame
            let encounter = geo.encounterFrame
            XCTAssertEqual(encounter.origin.x, summon.origin.x)
            XCTAssertEqual(encounter.origin.y, summon.origin.y - ext)
            XCTAssertEqual(encounter.width, summon.width)
            XCTAssertEqual(encounter.height, summon.height + ext)
        }
    }

    // MARK: - onboardingFrame

    func testOnboardingTextBarHeight() {
        XCTAssertEqual(NotchGeometry.onboardingTextBarHeight, 120)
    }

    func testOnboardingFrame_extendsSummonFrame() {
        let ext = NotchGeometry.gapHeight + NotchGeometry.onboardingTextBarHeight  // 12 + 80 = 92

        for geo in [Self.macbook, Self.imac] {
            let summon = geo.summonFrame
            let onboarding = geo.onboardingFrame
            XCTAssertEqual(onboarding.origin.x, summon.origin.x)
            XCTAssertEqual(onboarding.origin.y, summon.origin.y - ext)
            XCTAssertEqual(onboarding.width, summon.width)
            XCTAssertEqual(onboarding.height, summon.height + ext)
        }
    }

    // MARK: - fullscreenFrame

    func testFullscreenFrame_macbook() {
        XCTAssertEqual(
            Self.macbook.fullscreenFrame,
            CGRect(x: 0, y: 0, width: 1728, height: 1117)
        )
    }

    func testFullscreenFrame_imac() {
        XCTAssertEqual(
            Self.imac.fullscreenFrame,
            CGRect(x: 0, y: 0, width: 2560, height: 1440)
        )
    }

    // MARK: - notchShapeHeight

    func testNotchShapeHeight_matchesSummonHeight() {
        XCTAssertEqual(Self.macbook.notchShapeHeight, Self.macbook.summonFrame.height)
        XCTAssertEqual(Self.imac.notchShapeHeight, Self.imac.summonFrame.height)
    }

    // MARK: - Layout Constants

    func testTextBarHeight() {
        XCTAssertEqual(NotchGeometry.textBarHeight, 36)
    }

    func testGapHeight() {
        XCTAssertEqual(NotchGeometry.gapHeight, 12)
    }

    func testConcaveRadius() {
        XCTAssertEqual(NotchGeometry.concaveRadius, 10)
    }

    // MARK: - Equatable / Sendable

    func testEquatable() {
        let a = NotchGeometry(
            screenWidth: 1728, screenHeight: 1117,
            safeAreaInsetsTop: 37,
            auxiliaryTopLeftWidth: 420, auxiliaryTopRightWidth: 420
        )
        let b = NotchGeometry(
            screenWidth: 1728, screenHeight: 1117,
            safeAreaInsetsTop: 37,
            auxiliaryTopLeftWidth: 420, auxiliaryTopRightWidth: 420
        )
        XCTAssertEqual(a, b)
    }
}
