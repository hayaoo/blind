import Foundation

/// メインスレッド監視サービス。
/// フルスクリーン黒画面中にアプリがハングした場合のセーフガード。
/// バックグラウンドスレッドからメインスレッドの応答性を定期チェックし、
/// タイムアウト超過で `onMainThreadHung` を発火する。
public final class WatchdogService {
    public var onMainThreadHung: (() -> Void)?

    /// 監視間隔
    public let checkInterval: TimeInterval
    /// ハング判定タイムアウト
    public let timeout: TimeInterval

    public private(set) var isRunning: Bool = false

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "blind.watchdog", qos: .background)

    /// メインスレッドがフラグを更新したかを示す。
    /// バックグラウンドからfalseにセットし、メインスレッドにtrueへ戻してもらう。
    private var mainThreadResponded: Bool = true

    /// メインスレッドが連続して応答しなかった累積時間
    private var unresponsiveDuration: TimeInterval = 0

    public init(checkInterval: TimeInterval = 2.0, timeout: TimeInterval = 10.0) {
        self.checkInterval = checkInterval
        self.timeout = timeout
    }

    public func start() {
        queue.sync { [self] in
            guard !isRunning else { return }

            isRunning = true
            mainThreadResponded = true
            unresponsiveDuration = 0

            let source = DispatchSource.makeTimerSource(queue: queue)
            source.schedule(
                deadline: .now() + checkInterval,
                repeating: checkInterval
            )
            source.setEventHandler { [weak self] in
                self?.check()
            }
            timer = source
            source.resume()
        }
    }

    public func stop() {
        queue.sync { [self] in
            guard isRunning else { return }

            timer?.cancel()
            timer = nil
            isRunning = false
            unresponsiveDuration = 0
        }
    }

    private func check() {
        if mainThreadResponded {
            // メインスレッドは前回のチェック以降に応答した
            unresponsiveDuration = 0
        } else {
            // メインスレッドが応答していない
            unresponsiveDuration += checkInterval
            if unresponsiveDuration >= timeout {
                // バックグラウンドスレッドから直接コールバック
                onMainThreadHung?()
                // 連続発火を防ぐためリセット
                unresponsiveDuration = 0
            }
        }

        // フラグをリセットし、メインスレッドに応答を要求
        mainThreadResponded = false
        DispatchQueue.main.async { [weak self] in
            self?.mainThreadResponded = true
        }
    }
}
