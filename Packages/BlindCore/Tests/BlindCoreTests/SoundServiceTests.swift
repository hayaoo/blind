import XCTest
@testable import BlindCore

final class SoundServiceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Ensure clean UserDefaults state for soundEnabled
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "soundEnabled")
        super.tearDown()
    }

    // MARK: - Singleton

    func testSharedInstanceIsNotNil() {
        XCTAssertNotNil(SoundService.shared)
    }

    func testSharedInstanceIsSameObject() {
        let instance1 = SoundService.shared
        let instance2 = SoundService.shared
        XCTAssertTrue(instance1 === instance2)
    }

    // MARK: - Sound Enabled Default

    func testSoundEnabledDefaultIsTrue() {
        // When no UserDefaults value is set, soundEnabled should default to true
        // BlindSettings.current reads from UserDefaults; when "soundEnabled" key is nil,
        // it returns true by design
        let settings = BlindSettings()
        XCTAssertTrue(settings.soundEnabled)
    }

    func testSoundEnabledRespectsUserDefaults() {
        UserDefaults.standard.set(false, forKey: "soundEnabled")
        let settings = BlindSettings.current
        XCTAssertFalse(settings.soundEnabled)
    }

    func testSoundEnabledExplicitlyTrue() {
        UserDefaults.standard.set(true, forKey: "soundEnabled")
        let settings = BlindSettings.current
        XCTAssertTrue(settings.soundEnabled)
    }

    // MARK: - Method Existence

    func testPlayCompletionSoundExists() {
        // Verify the method exists and is callable (actual sound output not tested)
        let service = SoundService.shared
        _ = service.playCompletionSound
        // If this compiles, the method exists
    }

    func testPlayErrorSoundExists() {
        // Verify the method exists and is callable (actual sound output not tested)
        let service = SoundService.shared
        _ = service.playErrorSound
        // If this compiles, the method exists
    }
}
