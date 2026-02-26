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
        // 2560 - 0 - 0 = 2560
        XCTAssertEqual(Self.imac.notchWidth, 2560)
    }

    func testNotchHeight_imac() {
        XCTAssertEqual(Self.imac.notchHeight, 0)
    }

    // MARK: - notchRect

    func testNotchRect_macbook() {
        let rect = Self.macbook.notchRect
        // x = auxiliaryTopLeftWidth = 420
        // y = screenHeight - safeAreaInsetsTop = 1117 - 37 = 1080
        // width = 888, height = 37
        XCTAssertEqual(rect, CGRect(x: 420, y: 1080, width: 888, height: 37))
    }

    // MARK: - summonFrame

    func testSummonFrame_withNotch() {
        let frame = Self.macbook.summonFrame
        // ノッチありの場合、notchRectと同じ
        XCTAssertEqual(frame, Self.macbook.notchRect)
    }

    func testSummonFrame_withoutNotch() {
        let frame = Self.imac.summonFrame
        // 画面上部中央に幅200x高さ32のピル
        // x = (2560 - 200) / 2 = 1180
        // y = 1440 - 32 = 1408
        XCTAssertEqual(frame, CGRect(x: 1180, y: 1408, width: 200, height: 32))
    }

    // MARK: - encounterFrame

    func testEncounterFrame_withNotch() {
        let frame = Self.macbook.encounterFrame
        // summonFrame = (420, 1080, 888, 37)
        // 下に200pt拡張: y = 1080 - 200 = 880, height = 37 + 200 = 237
        XCTAssertEqual(frame, CGRect(x: 420, y: 880, width: 888, height: 237))
    }

    func testEncounterFrame_withoutNotch() {
        let frame = Self.imac.encounterFrame
        // summonFrame = (1180, 1408, 200, 32)
        // 下に200pt拡張: y = 1408 - 200 = 1208, height = 32 + 200 = 232
        XCTAssertEqual(frame, CGRect(x: 1180, y: 1208, width: 200, height: 232))
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
