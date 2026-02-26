import XCTest
@testable import BlindCore

// MARK: - Mock

/// CoreAudioに依存しないモック。フェードロジックやpersistenceをテストする。
final class MockVolumeControl: VolumeControlling, @unchecked Sendable {
    private let lock = NSLock()
    private var _volume: Float = 0.5
    private var _volumeHistory: [Float] = []

    var volumeHistory: [Float] {
        get { lock.withLock { _volumeHistory } }
        set { lock.withLock { _volumeHistory = newValue } }
    }

    var volume: Float {
        get { lock.withLock { _volume } }
        set { lock.withLock { _volume = newValue } }
    }

    func getVolume() -> Float {
        return volume
    }

    func setVolume(_ volume: Float) {
        let clamped = max(VolumeControlService.minimumVolume, min(1.0, volume))
        self.volume = clamped
        lock.withLock { _volumeHistory.append(clamped) }
    }

    func fadeDown(to targetVolume: Float, duration: TimeInterval) async {
        let target = max(VolumeControlService.minimumVolume, min(1.0, targetVolume))
        let startVolume = getVolume()
        guard duration > 0 else {
            setVolume(target)
            return
        }
        let steps = Int(duration / 0.016)
        guard steps > 0 else {
            setVolume(target)
            return
        }
        let delta = (target - startVolume) / Float(steps)
        for i in 1...steps {
            if Task.isCancelled { break }
            setVolume(startVolume + delta * Float(i))
        }
        setVolume(target)
    }

    func fadeUp(to targetVolume: Float, duration: TimeInterval) async {
        await fadeDown(to: targetVolume, duration: duration)
    }

    func emergencyRestore() {
        // No-op for mock
    }
}

// MARK: - Tests

final class VolumeControlServiceTests: XCTestCase {

    // MARK: - Protocol / Mock Tests

    func testMockGetSetVolume() {
        let mock = MockVolumeControl()
        mock.setVolume(0.8)
        XCTAssertEqual(mock.getVolume(), 0.8, accuracy: 0.001)
    }

    func testMinimumVolumeClamp() {
        let mock = MockVolumeControl()
        mock.setVolume(0.0)
        XCTAssertEqual(mock.getVolume(), VolumeControlService.minimumVolume, accuracy: 0.001,
                       "0.0に設定しても minimumVolume にクランプされるべき")
    }

    func testMaximumVolumeClamp() {
        let mock = MockVolumeControl()
        mock.setVolume(1.5)
        XCTAssertEqual(mock.getVolume(), 1.0, accuracy: 0.001,
                       "1.0を超える値は1.0にクランプされるべき")
    }

    func testMinimumVolumeConstant() {
        XCTAssertEqual(VolumeControlService.minimumVolume, 0.02, accuracy: 0.001)
    }

    // MARK: - Fade Tests (Mock)

    func testFadeDownReducesVolume() async {
        let mock = MockVolumeControl()
        mock.volume = 0.8
        await mock.fadeDown(to: 0.2, duration: 0.1)
        XCTAssertEqual(mock.getVolume(), max(0.2, VolumeControlService.minimumVolume), accuracy: 0.01)
    }

    func testFadeUpIncreasesVolume() async {
        let mock = MockVolumeControl()
        mock.volume = 0.2
        await mock.fadeUp(to: 0.8, duration: 0.1)
        XCTAssertEqual(mock.getVolume(), 0.8, accuracy: 0.01)
    }

    func testFadeWithZeroDuration() async {
        let mock = MockVolumeControl()
        mock.volume = 0.8
        await mock.fadeDown(to: 0.3, duration: 0.0)
        XCTAssertEqual(mock.getVolume(), 0.3, accuracy: 0.01,
                       "duration=0ならすぐにtarget値に設定される")
    }

    func testFadeRecordsMultipleSteps() async {
        let mock = MockVolumeControl()
        mock.volume = 1.0
        mock.volumeHistory = []
        await mock.fadeDown(to: 0.5, duration: 0.1)
        XCTAssertGreaterThan(mock.volumeHistory.count, 1,
                             "フェード中に複数回の音量変更が記録される")
    }

    func testFadeDownClampsToMinimum() async {
        let mock = MockVolumeControl()
        mock.volume = 0.5
        await mock.fadeDown(to: 0.0, duration: 0.05)
        XCTAssertGreaterThanOrEqual(mock.getVolume(), VolumeControlService.minimumVolume,
                                     "フェード後もminimumVolume以上であるべき")
    }

    // MARK: - Persistence Tests (UserDefaults)

    private let testKey = "blind_previous_volume"

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: testKey)
        super.tearDown()
    }

    func testSaveAndRetrieveVolume() {
        let service = VolumeControlService()
        // saveCurrentVolumeは実際のCoreAudioに依存するため、
        // UserDefaultsのロジックを直接テストする
        UserDefaults.standard.set(Float(0.75), forKey: testKey)
        XCTAssertTrue(service.hasSavedVolume)
        XCTAssertEqual(service.savedVolume!, 0.75, accuracy: 0.001)
    }

    func testClearSavedVolume() {
        let service = VolumeControlService()
        UserDefaults.standard.set(Float(0.75), forKey: testKey)
        service.clearSavedVolume()
        XCTAssertFalse(service.hasSavedVolume)
        XCTAssertNil(service.savedVolume)
    }

    func testHasSavedVolumeWhenEmpty() {
        let service = VolumeControlService()
        UserDefaults.standard.removeObject(forKey: testKey)
        XCTAssertFalse(service.hasSavedVolume)
        XCTAssertNil(service.savedVolume)
    }

    // MARK: - VolumeControlService Direct Tests (CoreAudio dependent)

    func testServiceInitDoesNotCrash() {
        // CoreAudioがなくてもクラッシュしないことを確認
        let service = VolumeControlService()
        _ = service.getVolume()
    }

    func testSetVolumeDoesNotCrash() {
        // CIなどCoreAudioデバイスがない環境でもクラッシュしないことを確認
        let service = VolumeControlService()
        service.setVolume(0.5)
    }

    func testEmergencyRestoreDoesNotCrashWithNoSavedVolume() {
        let service = VolumeControlService()
        service.clearSavedVolume()
        // savedVolumeがない場合、emergencyRestoreは何もしない
        service.emergencyRestore()
    }
}
