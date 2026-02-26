import XCTest
@testable import BlindCore

final class BlindCoreTests: XCTestCase {

    // MARK: - BlindSettings Defaults

    func testBlindSettingsDefaults() {
        let settings = BlindSettings()
        XCTAssertEqual(settings.reminderInterval, 30)
        XCTAssertEqual(settings.eyeCloseDuration, 5)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertFalse(settings.launchAtLogin)
    }

    // MARK: - BlindSettings Custom Initialization

    func testBlindSettingsCustomInit() {
        let settings = BlindSettings(
            reminderInterval: 15,
            eyeCloseDuration: 10,
            soundEnabled: false,
            launchAtLogin: true
        )
        XCTAssertEqual(settings.reminderInterval, 15)
        XCTAssertEqual(settings.eyeCloseDuration, 10)
        XCTAssertFalse(settings.soundEnabled)
        XCTAssertTrue(settings.launchAtLogin)
    }

    func testBlindSettingsPartialCustomInit() {
        let settings = BlindSettings(reminderInterval: 60)
        XCTAssertEqual(settings.reminderInterval, 60)
        // Other properties should retain defaults
        XCTAssertEqual(settings.eyeCloseDuration, 5)
        XCTAssertTrue(settings.soundEnabled)
        XCTAssertFalse(settings.launchAtLogin)
    }

    // MARK: - BlindSettings Codable

    func testBlindSettingsCodableRoundTrip() throws {
        let original = BlindSettings(
            reminderInterval: 45,
            eyeCloseDuration: 8,
            soundEnabled: false,
            launchAtLogin: true
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BlindSettings.self, from: data)

        XCTAssertEqual(decoded.reminderInterval, original.reminderInterval)
        XCTAssertEqual(decoded.eyeCloseDuration, original.eyeCloseDuration)
        XCTAssertEqual(decoded.soundEnabled, original.soundEnabled)
        XCTAssertEqual(decoded.launchAtLogin, original.launchAtLogin)
    }

    func testBlindSettingsCodableDefaultsRoundTrip() throws {
        let original = BlindSettings()

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BlindSettings.self, from: data)

        XCTAssertEqual(decoded.reminderInterval, 30)
        XCTAssertEqual(decoded.eyeCloseDuration, 5)
        XCTAssertTrue(decoded.soundEnabled)
        XCTAssertFalse(decoded.launchAtLogin)
    }

    func testBlindSettingsEncodesToExpectedJSON() throws {
        let settings = BlindSettings()
        let data = try JSONEncoder().encode(settings)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json)
        XCTAssertEqual(json?["reminderInterval"] as? Int, 30)
        XCTAssertEqual(json?["eyeCloseDuration"] as? Int, 5)
        XCTAssertEqual(json?["soundEnabled"] as? Bool, true)
        XCTAssertEqual(json?["launchAtLogin"] as? Bool, false)
    }

    // MARK: - TimerService Initialization

    func testTimerServiceInitialization() {
        let timerService = TimerService()
        XCTAssertEqual(timerService.intervalMinutes, 30)
    }

    // MARK: - EyeDetectionService Initialization

    func testEyeDetectionServiceInitialization() {
        let eyeDetectionService = EyeDetectionService()
        XCTAssertNotNil(eyeDetectionService)
    }

    // MARK: - nonZeroOr Extension

    func testNonZeroOrWithZero() {
        XCTAssertEqual(0.nonZeroOr(5), 5)
    }

    func testNonZeroOrWithPositiveValue() {
        XCTAssertEqual(10.nonZeroOr(5), 10)
    }

    func testNonZeroOrWithNegativeValue() {
        // nonZeroOr uses `self > 0`, so negative values return the default
        XCTAssertEqual((-1).nonZeroOr(5), 5)
    }

    func testNonZeroOrWithOne() {
        XCTAssertEqual(1.nonZeroOr(99), 1)
    }

    func testNonZeroOrWithLargeValue() {
        XCTAssertEqual(Int.max.nonZeroOr(5), Int.max)
    }

    func testNonZeroOrWithNegativeDefault() {
        // When self is 0 and default is negative, returns the negative default
        XCTAssertEqual(0.nonZeroOr(-10), -10)
    }

    func testNonZeroOrWithZeroDefault() {
        // When self is 0 and default is also 0
        XCTAssertEqual(0.nonZeroOr(0), 0)
    }

    func testNonZeroOrWithMinInt() {
        // Int.min is negative, so returns default
        XCTAssertEqual(Int.min.nonZeroOr(42), 42)
    }
}
