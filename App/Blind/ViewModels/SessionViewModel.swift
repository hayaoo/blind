import Foundation
import Combine
import BlindCore

@MainActor
class SessionViewModel: ObservableObject {
    @Published var eyesClosed = false
    @Published var faceDetected = true
    @Published var closedDuration: TimeInterval = 0
    @Published var isActive = false
    @Published var currentPhase: SessionPhase = .idle

    /// 目キャラの状態（EyeState + フェーズから導出）
    @Published var eyeCharacterState: EyeCharacterState = .idle

    /// Phase遷移時にAppDelegate（ウィンドウアニメーション）に通知
    var onPhaseChanged: ((SessionPhase) -> Void)?
    /// 目を閉じ始めた/開いた時のウィンドウ拡大/縮小通知
    var onEyesClosedChanged: ((Bool) -> Void)?
    var onSessionComplete: ((Bool) -> Void)?

    // MARK: - Onboarding

    /// オンボーディングモードかどうか
    @Published var isOnboarding = false

    /// 現在のオンボーディングフェーズ
    @Published var currentOnboardingPhase: OnboardingPhase?

    /// 拡張オンボーディングViewModel（33画面フロー管理）
    var extendedOnboardingVM: ExtendedOnboardingViewModel?

    /// オンボーディング完了コールバック
    var onOnboardingComplete: (() -> Void)?

    /// オンボーディングフェーズ変更コールバック
    var onOnboardingPhaseChanged: ((OnboardingPhase) -> Void)?

    var requiredClosedDuration: TimeInterval {
        if isOnboarding {
            return 3.0 // お試しセッション: 3秒
        }
        return TimeInterval(UserDefaults.standard.integer(forKey: "eyeCloseDuration").nonZeroOr(5))
    }

    var closedProgress: Double {
        min(closedDuration / requiredClosedDuration, 1.0)
    }

    /// Phase 3 没入時間: カウントダウン完了後、覚醒に入るまでの短い間
    var immersionDuration: TimeInterval { 0.5 }

    // MARK: - Pre-close / Post-close (Pro)

    /// Pre-closeで選択された内なる声
    @Published var preCloseVoice: InnerVoiceType?

    /// Post-closeで選択された行動
    @Published var postCloseAction: PostCloseAction?

    /// Pro機能が有効か
    var isProEnabled: Bool {
        OnboardingDataStore.shared.isProUnlocked
    }

    /// Pre-close: 内なる声を選択して次へ
    func selectPreCloseVoice(_ voice: InnerVoiceType) {
        preCloseVoice = voice
        advancePhase(trigger: .preCloseCompleted)
    }

    /// Post-close: 象使いの判断を選択して次へ
    func selectPostCloseAction(_ action: PostCloseAction) {
        postCloseAction = action
        advancePhase(trigger: .postCloseCompleted)
    }

    /// Pre-close: 声なしでスキップ
    func skipPreClose() {
        preCloseVoice = nil
        advancePhase(trigger: .preCloseCompleted)
    }

    private var eyeDetectionService: EyeDetectionService?
    private var closedTimer: Timer?
    private var immersionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func startSession() {
        isActive = true
        closedDuration = 0
        preCloseVoice = nil
        postCloseAction = nil

        // Phase 1: Summon
        transitionTo(.summon)

        eyeDetectionService = EyeDetectionService()
        eyeDetectionService?.onEyeStateChanged = { [weak self] state in
            DispatchQueue.main.async {
                self?.handleEyeState(state)
            }
        }
        eyeDetectionService?.start()
    }

    func stopSession() {
        isActive = false
        closedTimer?.invalidate()
        closedTimer = nil
        immersionTimer?.invalidate()
        immersionTimer = nil
        eyeDetectionService?.stop()
        eyeDetectionService = nil
    }

    func cancelSession() {
        guard isActive else { return }
        transitionTo(.cancelled)
        stopSession()
        let callback = onSessionComplete
        onSessionComplete = nil
        callback?(false)
    }

    /// アクセシビリティ: 手動で目閉じ完了と同等のトリガーを発火
    func manualComplete() {
        guard currentPhase == .encounter else { return }
        advancePhase(trigger: .eyesClosedDurationMet)
    }

    // MARK: - Onboarding Methods

    /// 拡張オンボーディング開始（33画面フロー）
    func startOnboarding() {
        isOnboarding = true
        let vm = ExtendedOnboardingViewModel()
        extendedOnboardingVM = vm

        // フェーズ変更をSessionViewModelに伝播
        vm.onPhaseChanged = { [weak self] phase in
            self?.currentOnboardingPhase = phase
            self?.onOnboardingPhaseChanged?(phase)
        }

        // お試しセッション開始
        vm.onStartTrySession = { [weak self] in
            self?.startTrySession()
        }

        // 完了
        vm.onComplete = { [weak self] in
            self?.completeOnboarding()
        }

        // 早期スキップ
        vm.onSkip = { [weak self] in
            self?.completeOnboarding()
        }

        currentOnboardingPhase = .welcome
        onOnboardingPhaseChanged?(.welcome)
    }

    /// オンボーディングの次のフェーズへ（拡張版: ExtendedOnboardingVMに委譲）
    func advanceOnboarding() {
        guard let vm = extendedOnboardingVM else {
            // フォールバック: 拡張VMがない場合はdoneへ
            completeOnboarding()
            return
        }

        // 特殊ケース: trySession完了後
        if currentOnboardingPhase == .trySession {
            vm.onTrySessionComplete()
            return
        }

        // 特殊ケース: done → 完了
        if currentOnboardingPhase == .done {
            completeOnboarding()
            return
        }

        vm.advance()
    }

    /// カメラ拒否時: trySessionをスキップしてプラン生成へ
    func skipToOnboardingDone() {
        if let vm = extendedOnboardingVM {
            vm.transitionTo(.planLoading)
        } else {
            currentOnboardingPhase = .done
            onOnboardingPhaseChanged?(.done)
        }
    }

    /// お試しセッション開始（短縮版: 3秒閉眼）
    private func startTrySession() {
        startSession()
    }

    /// オンボーディング完了
    private func completeOnboarding() {
        isOnboarding = false
        currentOnboardingPhase = nil
        extendedOnboardingVM = nil
        onOnboardingComplete?()
    }

    // MARK: - Phase Transitions

    /// Summonアニメーション完了時にAppDelegateから呼ばれる
    func onSummonAnimationComplete() {
        advancePhase(trigger: .animationCompleted)
    }

    /// Awakeningアニメーション完了時にAppDelegateから呼ばれる
    func onAwakeningAnimationComplete() {
        advancePhase(trigger: .animationCompleted)
    }

    private func advancePhase(trigger: SessionPhaseTransition.Trigger) {
        let proActive = isProEnabled && !isOnboarding
        guard let next = SessionPhaseTransition.next(from: currentPhase, trigger: trigger, proEnabled: proActive) else { return }
        transitionTo(next)
    }

    private func transitionTo(_ phase: SessionPhase) {
        currentPhase = phase
        updateEyeCharacterState()
        onPhaseChanged?(phase)

        switch phase {
        case .immersion:
            startImmersionTimer()
        case .completed:
            guard isActive else { return }
            stopSession()
            let callback = onSessionComplete
            onSessionComplete = nil
            callback?(true)
        default:
            break
        }
    }

    private func startImmersionTimer() {
        immersionTimer?.invalidate()
        immersionTimer = Timer.scheduledTimer(withTimeInterval: immersionDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.advancePhase(trigger: .immersionTimerCompleted)
            }
        }
    }

    private func updateEyeCharacterState() {
        switch currentPhase {
        case .idle, .summon:
            eyeCharacterState = .idle
        case .preClose:
            eyeCharacterState = .tracking
        case .postClose:
            eyeCharacterState = .winking
        case .encounter:
            if !faceDetected {
                eyeCharacterState = .searching
            } else if eyesClosed {
                eyeCharacterState = .closing(progress: closedProgress)
            } else {
                eyeCharacterState = .tracking
            }
        case .immersion:
            eyeCharacterState = .closed
        case .awakening:
            eyeCharacterState = .winking
        case .completed, .cancelled:
            eyeCharacterState = .idle
        }
    }

    private func handleEyeState(_ state: EyeState) {
        // Phase encounter以外ではEyeState変化を無視
        guard currentPhase == .encounter else { return }

        switch state {
        case .closed:
            let wasOpen = !eyesClosed
            eyesClosed = true
            faceDetected = true
            if wasOpen {
                startClosedTimer(reset: !wasPausedByNoFace)
                // 目を閉じ始めた → フルスクリーン拡大開始
                onEyesClosedChanged?(true)
            }
        case .open:
            let wasClosed = eyesClosed
            eyesClosed = false
            faceDetected = true
            wasPausedByNoFace = false
            resetClosedTimer()
            if wasClosed {
                // 目を開いた → encounterサイズに戻す
                onEyesClosedChanged?(false)
            }
        case .noFace:
            let wasClosed = eyesClosed
            eyesClosed = false
            faceDetected = false
            wasPausedByNoFace = closedTimer != nil || closedDuration > 0
            // タイマー一時停止（closedDurationはリセットしない）
            closedTimer?.invalidate()
            closedTimer = nil
            if wasClosed {
                onEyesClosedChanged?(false)
            }
        }
        updateEyeCharacterState()
    }

    private var wasPausedByNoFace = false

    private func startClosedTimer(reset: Bool = true) {
        closedTimer?.invalidate()
        if reset {
            closedDuration = 0
        }

        closedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateClosedDuration()
            }
        }
    }

    private func resetClosedTimer() {
        closedTimer?.invalidate()
        closedTimer = nil
        closedDuration = 0
    }

    private func updateClosedDuration() {
        guard eyesClosed else { return }

        closedDuration += 0.1

        if closedDuration >= requiredClosedDuration {
            completeSession()
        }
    }

    private func completeSession() {
        guard isActive else { return } // Prevent double completion
        // encounter → immersion に遷移（stopSessionではない）
        advancePhase(trigger: .eyesClosedDurationMet)
    }
}
