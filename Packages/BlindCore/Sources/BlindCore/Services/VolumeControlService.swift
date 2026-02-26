import CoreAudio
import AudioToolbox
import Foundation

// MARK: - Protocol

public protocol VolumeControlling: Sendable {
    func getVolume() -> Float
    func setVolume(_ volume: Float)
    func fadeDown(to targetVolume: Float, duration: TimeInterval) async
    func fadeUp(to targetVolume: Float, duration: TimeInterval) async
    func emergencyRestore()
}

// MARK: - VolumeControlService

public final class VolumeControlService: VolumeControlling, @unchecked Sendable {
    public static let shared = VolumeControlService()

    /// 完全無音にしない安全策
    public static let minimumVolume: Float = 0.02

    /// クラッシュリカバリ用の保存キー
    private let savedVolumeKey = "blind_previous_volume"

    /// フェード間隔（約60fps）
    private static let fadeStepInterval: UInt64 = 16_000_000 // 16ms in nanoseconds

    public init() {}

    // MARK: - Volume Get/Set

    public func getVolume() -> Float {
        guard let deviceID = defaultOutputDeviceID() else { return 0.0 }

        var volume: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        guard status == noErr else { return 0.0 }
        return volume
    }

    public func setVolume(_ volume: Float) {
        let clamped = max(Self.minimumVolume, min(1.0, volume))
        guard let deviceID = defaultOutputDeviceID() else { return }

        var value = clamped
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &value)
    }

    // MARK: - Fade

    public func fadeDown(to targetVolume: Float, duration: TimeInterval) async {
        let target = max(Self.minimumVolume, min(1.0, targetVolume))
        await performFade(to: target, duration: duration)
    }

    public func fadeUp(to targetVolume: Float, duration: TimeInterval) async {
        let target = max(Self.minimumVolume, min(1.0, targetVolume))
        await performFade(to: target, duration: duration)
    }

    private func performFade(to targetVolume: Float, duration: TimeInterval) async {
        let startVolume = getVolume()
        guard duration > 0 else {
            setVolume(targetVolume)
            return
        }

        let stepDuration: TimeInterval = 0.016 // 16ms
        let steps = Int(duration / stepDuration)
        guard steps > 0 else {
            setVolume(targetVolume)
            return
        }

        let delta = (targetVolume - startVolume) / Float(steps)

        for i in 1...steps {
            if Task.isCancelled { break }
            let volume = startVolume + delta * Float(i)
            setVolume(volume)
            try? await Task.sleep(nanoseconds: Self.fadeStepInterval)
        }

        // 最終値を確実にセット
        setVolume(targetVolume)
    }

    // MARK: - Emergency Restore

    public func emergencyRestore() {
        guard let saved = savedVolume else { return }
        setVolume(saved)
        clearSavedVolume()
    }

    // MARK: - Volume Persistence

    public func saveCurrentVolume() {
        let current = getVolume()
        UserDefaults.standard.set(current, forKey: savedVolumeKey)
    }

    public func clearSavedVolume() {
        UserDefaults.standard.removeObject(forKey: savedVolumeKey)
    }

    public var hasSavedVolume: Bool {
        UserDefaults.standard.object(forKey: savedVolumeKey) != nil
    }

    public var savedVolume: Float? {
        guard hasSavedVolume else { return nil }
        return UserDefaults.standard.float(forKey: savedVolumeKey)
    }

    // MARK: - CoreAudio Helpers

    private func defaultOutputDeviceID() -> AudioObjectID? {
        var deviceID = AudioObjectID(0)
        var size = UInt32(MemoryLayout<AudioObjectID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )

        guard status == noErr, deviceID != kAudioObjectUnknown else { return nil }
        return deviceID
    }
}
