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

    // MARK: - summonFrame (legacy — 新仕様に置き換え済み)

    func testSummonFrame_withNotch() {
        let frame = Self.macbook.summonFrame
        // 新仕様: 物理ノッチ幅に一致、下方30pt拡張
        XCTAssertEqual(frame, CGRect(x: 420, y: 1050, width: 888, height: 67))
    }

    func testSummonFrame_withoutNotch() {
        let frame = Self.imac.summonFrame
        // 新仕様: 280×70のフェイクノッチ
        XCTAssertEqual(frame, CGRect(x: 1140, y: 1370, width: 280, height: 70))
    }

    // MARK: - encounterFrame (legacy — 新仕様に置き換え済み)

    func testEncounterFrame_withNotch() {
        let frame = Self.macbook.encounterFrame
        // summonFrame = (420, 1050, 888, 67)
        // 下にgap(12) + textBar(54) = 66pt拡張
        // y = 1050 - 66 = 984, height = 67 + 66 = 133
        XCTAssertEqual(frame, CGRect(x: 420, y: 984, width: 888, height: 133))
    }

    func testEncounterFrame_withoutNotch() {
        let frame = Self.imac.encounterFrame
        // summonFrame = (1140, 1370, 280, 70)
        // 下にgap(12) + textBar(54) = 66pt拡張
        // y = 1370 - 66 = 1304, height = 70 + 66 = 136
        XCTAssertEqual(frame, CGRect(x: 1140, y: 1304, width: 280, height: 136))
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

    // MARK: - displayMode

    func testDisplayMode_notch() {
        XCTAssertEqual(Self.macbook.displayMode, .notch)
    }

    func testDisplayMode_noNotch() {
        XCTAssertEqual(Self.imac.displayMode, .noNotch)
    }

    // MARK: - summonFrame (新: 拡張ノッチ)

    func testSummonFrame_notch_extendsPhysicalNotch() {
        let frame = Self.macbook.summonFrame
        // notchRect = (420, 1080, 888, 37)
        // 幅は物理ノッチに一致、下方30pt拡張
        // x = 420, y = 1080 - 30 = 1050
        // width = 888, height = 37 + 30 = 67
        XCTAssertEqual(frame, CGRect(x: 420, y: 1050, width: 888, height: 67))
    }

    func testSummonFrame_noNotch_fakeNotch() {
        let frame = Self.imac.summonFrame
        // 画面上部中央に280×70
        // x = (2560 - 280) / 2 = 1140
        // y = 1440 - 70 = 1370
        XCTAssertEqual(frame, CGRect(x: 1140, y: 1370, width: 280, height: 70))
    }

    // MARK: - encounterFrame (新: テキスト帯付き)

    func testEncounterFrame_notch_includesTextBarAndGap() {
        let frame = Self.macbook.encounterFrame
        let summon = Self.macbook.summonFrame
        let ext = NotchGeometry.gapHeight + NotchGeometry.textBarHeight  // 12 + 54 = 66
        XCTAssertEqual(frame.origin.x, summon.origin.x)
        XCTAssertEqual(frame.origin.y, summon.origin.y - ext)
        XCTAssertEqual(frame.width, summon.width)
        XCTAssertEqual(frame.height, summon.height + ext)
    }

    func testEncounterFrame_noNotch_includesTextBarAndGap() {
        let frame = Self.imac.encounterFrame
        let summon = Self.imac.summonFrame
        let ext = NotchGeometry.gapHeight + NotchGeometry.textBarHeight
        XCTAssertEqual(frame.height, summon.height + ext)
    }

    // MARK: - notchShapeHeight

    func testNotchShapeHeight_matchesSummonHeight() {
        XCTAssertEqual(Self.macbook.notchShapeHeight, Self.macbook.summonFrame.height)
        XCTAssertEqual(Self.imac.notchShapeHeight, Self.imac.summonFrame.height)
    }

    // MARK: - Layout Constants

    func testTextBarHeight() {
        XCTAssertEqual(NotchGeometry.textBarHeight, 54)
    }

    func testGapHeight() {
        XCTAssertEqual(NotchGeometry.gapHeight, 12)
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
