import Foundation
import Combine
import BlindCore

/// 拡張オンボーディング（33画面）のフロー管理
@MainActor
class ExtendedOnboardingViewModel: ObservableObject {

    // MARK: - Published State

    /// 現在のフェーズ
    @Published var currentPhase: OnboardingPhase = .welcome

    /// 診断回答（進行中）
    @Published var diagnosis = DiagnosisResult()

    /// 生成されたプラン
    @Published var plan: PersonalizedPlan?

    /// 目キャラの状態
    @Published var eyeCharacterState: EyeCharacterState = .idle

    /// ローディング中か
    @Published var isLoadingPlan = false

    /// Day 7レポートコンテンツ（Day 7フロー時にセット）
    @Published var reportContent: Day7ReportContent?

    /// Day 7フローかどうか
    @Published var isDay7Flow = false

    /// プログレス（0.0〜1.0）
    var progress: Double {
        let sequence = currentSequence
        guard let index = sequence.firstIndex(of: currentPhase) else { return 0 }
        return Double(index + 1) / Double(sequence.count)
    }

    /// 現在の画面番号（1-indexed）
    var currentScreenNumber: Int {
        let sequence = currentSequence
        return (sequence.firstIndex(of: currentPhase) ?? 0) + 1
    }

    // MARK: - Callbacks

    /// フェーズ変更通知
    var onPhaseChanged: ((OnboardingPhase) -> Void)?

    /// カメラ権限要求
    var onRequestCameraPermission: ((@escaping (Bool) -> Void) -> Void)?

    /// お試しセッション開始
    var onStartTrySession: (() -> Void)?

    /// オンボーディング完了
    var onComplete: (() -> Void)?

    /// 早期スキップ（ESCなど）
    var onSkip: (() -> Void)?

    // MARK: - Data Store

    private let dataStore = OnboardingDataStore.shared

    /// 使用するシーケンス（Day 1 or Day 7）
    private var currentSequence: [OnboardingPhase] {
        isDay7Flow ? OnboardingPhase.day7Sequence : OnboardingPhase.day1Sequence
    }

    // MARK: - Day 7 Report

    /// Day 7レポートフローを開始
    func startDay7Flow() {
        isDay7Flow = true
        let stats = dataStore.computeWeeklyStats()
        let diagnosis = dataStore.diagnosisResult
        reportContent = Day7ReportContent(stats: stats, diagnosis: diagnosis)
        transitionTo(.reportTrainingLog)
    }

    // MARK: - Navigation

    /// 次のフェーズへ進む
    func advance() {
        let sequence = currentSequence
        guard let currentIndex = sequence.firstIndex(of: currentPhase) else { return }
        let nextIndex = currentIndex + 1

        guard nextIndex < sequence.count else {
            if isDay7Flow {
                completeDay7()
            } else {
                complete()
            }
            return
        }

        let nextPhase = sequence[nextIndex]
        transitionTo(nextPhase)
    }

    /// 特定のフェーズへ遷移
    func transitionTo(_ phase: OnboardingPhase) {
        currentPhase = phase
        updateEyeCharacterState()
        onPhaseChanged?(phase)

        // フェーズ固有のアクション
        switch phase {
        case .camera:
            break // UIでカメラ権限ボタンを表示、ボタン押下時にhandleCameraPermission呼び出し
        case .trySession:
            onStartTrySession?()
        case .planLoading:
            generatePlan()
        case .done:
            break
        default:
            break
        }
    }

    /// 前のフェーズに戻る
    func goBack() {
        let sequence = currentSequence
        guard let currentIndex = sequence.firstIndex(of: currentPhase), currentIndex > 0 else { return }
        let prevPhase = sequence[currentIndex - 1]
        currentPhase = prevPhase
        updateEyeCharacterState()
        onPhaseChanged?(prevPhase)
    }

    /// 診断ブロックをスキップ（最低限のプラン生成で先へ）
    func skipDiagnosis() {
        transitionTo(.camera)
    }

    /// オンボーディングを早期スキップ
    func skipAll() {
        // デフォルト設定で完了
        dataStore.isExtendedOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        onSkip?()
    }

    // MARK: - Diagnosis Answer Handling

    /// Q4: 予定と違う作業の頻度
    func answerDeviationFrequency(_ answer: DeviationFrequency) {
        diagnosis.deviationFrequency = answer
        advance()
    }

    /// Q5: 最長連続作業時間
    func answerMaxFocusDuration(_ answer: MaxFocusDuration) {
        diagnosis.maxFocusDuration = answer
        advance()
    }

    /// Q6: 過集中後の影響（複数選択）
    func answerConsequences(_ answers: [HyperFocusConsequence]) {
        diagnosis.consequences = answers
        advance()
    }

    /// Q7: AIツール利用時の脱線
    func answerAIDeviation(_ answer: AIDeviationFrequency) {
        diagnosis.aiDeviation = answer
        advance()
    }

    /// Q8: 内なる声タイプ
    func answerInnerVoice(_ answer: InnerVoiceType) {
        diagnosis.innerVoiceType = answer
        advance()
    }

    /// Q9: 過集中後の感情
    func answerPostFocusEmotion(_ answer: PostFocusEmotion) {
        diagnosis.postFocusEmotion = answer
        advance()
    }

    /// Q10: 切り上げるまでの時間
    func answerStopDelay(_ answer: StopDelay) {
        diagnosis.stopDelay = answer
        advance()
    }

    /// Q11: 中断への抵抗感
    func answerInterruptionResistance(_ answer: InterruptionResistance) {
        diagnosis.interruptionResistance = answer
        advance()
    }

    /// Q12: 自己認知レベル
    func answerSelfAwareness(_ answer: SelfAwarenessLevel) {
        diagnosis.selfAwareness = answer
        advance()
    }

    /// Q13: 自己制御レベル
    func answerSelfRegulation(_ answer: SelfRegulationLevel) {
        diagnosis.selfRegulation = answer
        advance()
    }

    /// Q14: メタ認知の習慣
    func answerMetaCognitionHabit(_ answer: MetaCognitionHabit) {
        diagnosis.metaCognitionHabit = answer
        advance()
    }

    /// Q15: Blindへの期待
    func answerBlindExpectation(_ answer: BlindExpectation) {
        diagnosis.blindExpectation = answer
        advance()
    }

    /// Q27: 体験後の気づき確認
    func answerTrialReflection(_ answer: TrialReflectionAnswer) {
        diagnosis.trialReflection = answer
        advance()
    }

    // MARK: - Camera Permission

    /// カメラ権限をリクエスト
    func handleCameraPermission() {
        onRequestCameraPermission? { [weak self] granted in
            guard let self else { return }
            if granted {
                self.advance() // → trySession
            } else {
                // カメラ拒否 → trySessionをスキップしてtrialReflectionの次へ
                self.transitionTo(.planLoading)
            }
        }
    }

    // MARK: - Plan Generation

    /// プラン生成（ローディング演出あり）
    private func generatePlan() {
        isLoadingPlan = true

        // 診断結果を保存
        dataStore.generateAndApplyPlan(from: diagnosis)
        plan = dataStore.personalizedPlan

        // 3秒のローディング演出
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self else { return }
            self.isLoadingPlan = false
            self.advance() // → planOverview
        }
    }

    // MARK: - Completion

    /// Day 7レポート完了
    private func completeDay7() {
        dataStore.isDay7ReportShown = true
        isDay7Flow = false
        onComplete?()
    }

    /// オンボーディング完了
    private func complete() {
        dataStore.isExtendedOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")

        // インストール日を記録（まだ未設定の場合）
        _ = dataStore.installDate

        onComplete?()
    }

    /// お試しセッション完了時（SessionViewModelから呼ばれる）
    func onTrySessionComplete() {
        // trySession → trialReflection
        advance()
    }

    // MARK: - Eye Character State

    private func updateEyeCharacterState() {
        switch currentPhase {
        case .welcome:
            eyeCharacterState = .idle
        case .hook:
            eyeCharacterState = .tracking
        case .promise:
            eyeCharacterState = .winking
        case _ where currentPhase.isDiagnosis:
            eyeCharacterState = .tracking
        case _ where currentPhase.isBridge:
            eyeCharacterState = .idle
        case _ where currentPhase.isKnowledge:
            eyeCharacterState = .tracking
        case .trySession:
            break // SessionViewModelが管理
        case .planLoading:
            eyeCharacterState = .searching
        case .planOverview, .planVoiceType, .planProPreview:
            eyeCharacterState = .tracking
        case .softPaywall:
            eyeCharacterState = .winking
        case .done:
            eyeCharacterState = .winking
        // Day 7
        case .reportTrainingLog, .reportRunawayPattern, .reportGrowth:
            eyeCharacterState = .tracking
        case .hardPaywallValue:
            eyeCharacterState = .winking
        case .hardPaywallChoice:
            eyeCharacterState = .idle
        default:
            eyeCharacterState = .idle
        }
    }

    // MARK: - Content Helpers

    /// 知識教育のQ5回答引用テキスト
    var quotedFocusDuration: String {
        diagnosis.maxFocusDuration?.quoteText ?? "長時間"
    }

    /// 知識教育のQ8回答引用テキスト
    var quotedInnerVoice: String {
        diagnosis.innerVoiceType?.voiceQuote ?? "もっと良くできるはず"
    }

    /// 知識教育のQ12回答引用テキスト
    var quotedSelfAwareness: String {
        diagnosis.selfAwareness?.displayText ?? "たまに気づく"
    }

    /// 知識教育のQ13回答引用テキスト
    var quotedSelfRegulation: String {
        diagnosis.selfRegulation?.displayText ?? "わかっていてもやめられない"
    }
}
