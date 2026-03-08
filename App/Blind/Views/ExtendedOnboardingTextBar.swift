import SwiftUI
import BlindCore

/// 拡張オンボーディング用テキスト帯（33画面対応）
/// 診断質問・知識教育・プラン提示などフェーズごとに異なるコンテンツを表示
struct ExtendedOnboardingTextBar: View {
    @ObservedObject var viewModel: ExtendedOnboardingViewModel
    var onDismiss: (() -> Void)?

    var body: some View {
        switch viewModel.currentPhase {
        case .trySession:
            EmptyView()
        default:
            bar
        }
    }

    // MARK: - Main Bar

    private var bar: some View {
        ZStack(alignment: .topTrailing) {
            // ×ボタン
            Button(action: { onDismiss?() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("閉じる")
            .padding(.top, 8)
            .padding(.trailing, 10)
            .zIndex(1)

            // コンテンツ
            VStack(alignment: .leading, spacing: 6) {
                // プログレスバー（診断・知識フェーズで表示）
                if showsProgressBar {
                    progressBar
                }

                // フェーズ固有のコンテンツ
                phaseContent

                // アクションボタン
                if let label = actionLabel {
                    HStack {
                        // 戻るボタン（導入・完了以外で表示）
                        if showsBackButton {
                            Button(action: { viewModel.goBack() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 28, height: 28)
                                    .background(Color.white.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        // スキップリンク（診断中に表示）
                        if viewModel.currentPhase.isDiagnosis {
                            Button(action: { viewModel.skipDiagnosis() }) {
                                Text("スキップ")
                                    .font(.system(size: 11, weight: .regular, design: .rounded))
                                    .foregroundColor(.white.opacity(0.35))
                            }
                            .buttonStyle(.plain)
                            .padding(.trailing, 8)
                        }

                        Button(action: { handleAction() }) {
                            Text(label)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .frame(height: 28)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Progress Bar

    private var showsProgressBar: Bool {
        let phase = viewModel.currentPhase
        return phase.isDiagnosis || phase.isKnowledge || viewModel.isDay7Flow
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.1))
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: geo.size.width * viewModel.progress)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
            }
        }
        .frame(height: 3)
        .padding(.bottom, 4)
    }

    // MARK: - Phase Content

    @ViewBuilder
    private var phaseContent: some View {
        switch viewModel.currentPhase {
        // 導入
        case .welcome:
            textContent(main: "はじめまして！", sub: "Blindは、5秒目を閉じるだけで頭をリセットするアプリです")
        case .hook:
            textContent(
                main: "こんな経験、ありませんか？",
                sub: "気づいたら予定と違うことに没頭していた——\n大事なタスクが抜け漏れていた——"
            )
        case .promise:
            textContent(main: "5分で、あなた専用の中断プランを作ります", sub: "いくつか質問に答えてください")

        // 診断 Block A
        case .diagnosisA1:
            diagnosisQuestion(
                category: "あなたの働き方について",
                question: "気づいたら予定と違う作業をしていた、ということはどのくらいありますか？"
            )
        case .diagnosisA2:
            diagnosisQuestion(
                category: "あなたの働き方について",
                question: "没頭すると、最長で何時間くらい連続作業しますか？"
            )
        case .diagnosisA3:
            diagnosisQuestion(
                category: "あなたの働き方について",
                question: "過集中の後に起きることは？（複数選択可）"
            )
        case .diagnosisA4:
            diagnosisQuestion(
                category: "あなたの働き方について",
                question: "AIツールを使っていて、当初の目的から脱線したことは？"
            )
        case .diagnosisBridgeAB:
            textContent(
                main: "なるほど。",
                sub: "次に、「なぜ止まれないのか」を少し深掘りしてみましょう"
            )

        // 診断 Block B
        case .diagnosisB1:
            diagnosisQuestion(
                category: "内なる声について",
                question: "没頭してしまう時、頭の中でどんな声が聞こえますか？\n一番近いものを選んでください"
            )
        case .diagnosisB2:
            diagnosisQuestion(
                category: "内なる声について",
                question: "過集中から抜けた後、最初に感じる感情は？"
            )
        case .diagnosisB3:
            diagnosisQuestion(
                category: "内なる声について",
                question: "「切り上げよう」と思った後、手を止めるまでにかかる時間は？"
            )
        case .diagnosisB4:
            diagnosisQuestion(
                category: "内なる声について",
                question: "作業を中断されることへの抵抗感は？"
            )
        case .diagnosisBridgeBC:
            textContent(
                main: "ありがとうございます。",
                sub: "最後に、「自分の状態に気づく力」について教えてください"
            )

        // 診断 Block C
        case .diagnosisC1:
            diagnosisQuestion(
                category: "気づきの力について",
                question: "「今、自分は過集中状態だ」と、最中に気づくことはありますか？"
            )
        case .diagnosisC2:
            diagnosisQuestion(
                category: "気づきの力について",
                question: "気づいたとして、実際に行動を変えられますか？"
            )
        case .diagnosisC3:
            diagnosisQuestion(
                category: "気づきの力について",
                question: "「今、正しいことをしているか？」を定期的に確認する習慣はありますか？"
            )
        case .diagnosisC4:
            diagnosisQuestion(
                category: "気づきの力について",
                question: "Blindに一番期待することは？"
            )

        // 知識教育
        case .knowledgeElephant1:
            textContent(
                main: "集中には2種類あります",
                sub: "「象使いが操る集中」——目的に向かって、意思で舵を取る集中\n「象が暴走する集中」——気づいたら別のところにいる、あの感覚です"
            )
        case .knowledgeElephant2:
            textContent(
                main: "あなたの象",
                sub: "さっき「\(viewModel.quotedFocusDuration)くらい連続作業する」と答えてくれましたね。\nその間、象使いはどこにいたと思いますか？\n……おそらく、象の上で居眠りしていたかもしれません"
            )
        case .knowledgeVoice1:
            textContent(
                main: "象を暴走させているもの",
                sub: "実は、あなたの頭の中にいる「内なる声」です。\nさっき選んでくれた「\(viewModel.quotedInnerVoice)」\n——あれがその声です"
            )
        case .knowledgeVoice2:
            voiceTypesContent
        case .knowledgeVoice3:
            textContent(
                main: "この声は敵ではありません",
                sub: "元は「もっと頑張ろう」「ちゃんとやろう」という善意から生まれたもの。\nでもブレーキがないまま走り続けると、象が暴走します。\n重要なのは、声を消すことではなく、声に気づくことです"
            )
        case .knowledgeAwareness1:
            textContent(
                main: "気づきの力",
                sub: "さっき「暴走中に気づくか？」と聞きました。\nあなたは「\(viewModel.quotedSelfAwareness)」と答えましたね。\n「気づく力」——これは鍛えられる筋肉です。使うほど強くなります"
            )
        case .knowledgeAwareness2:
            textContent(
                main: "気づいても止まれない理由",
                sub: "あなたも「\(viewModel.quotedSelfRegulation)」と答えてくれました。\nこれは意志が弱いのではなく、「止める仕組み」が存在しないだけです。\nBlindは、その仕組みです"
            )
        case .knowledgeFiveSeconds1:
            textContent(
                main: "Blindの5秒で起きること",
                sub: "❶ 象が止まる（中断）\n❷ 内なる声に気づく（ラベリング）\n❸ 象使いが地図を確認する（メタ認知）\nこの3ステップが「気づきの筋肉」を鍛えるトレーニングです"
            )
        case .knowledgeFiveSeconds2:
            textContent(
                main: "なぜ5秒で十分か",
                sub: "長い瞑想は不要です。筋トレと同じで、大事なのは重さではなく回数。\n1日8回、5秒ずつ。合計たった40秒で、象使いが手綱を握り直す回数が8回増えます"
            )

        // 体験
        case .camera:
            textContent(
                main: "カメラを使います",
                sub: "目を閉じたことを検知するために使います。映像は保存・送信しません"
            )
        case .trySession:
            EmptyView()
        case .trialReflection:
            textContent(
                main: "象使いが戻ってきた感覚",
                sub: "たった3秒で、「今、何をしていたか」を思い出せましたか？\nこれが「気づきの筋トレ」です"
            )

        // プラン提示
        case .planLoading:
            loadingContent
        case .planOverview:
            planContent
        case .planVoiceType:
            voiceTypeResultContent
        case .planProPreview:
            textContent(
                main: "7日後に成長をお見せします",
                sub: "7日間使った後、あなたの「暴走パターン」と「気づきの筋力の成長」をレポートでお届けします"
            )

        // ペイウォール
        case .softPaywall:
            softPaywallContent

        // 完了
        case .done:
            doneContent

        // Day 7 レポート
        case .reportTrainingLog:
            reportTrainingLogContent
        case .reportRunawayPattern:
            reportRunawayPatternContent
        case .reportGrowth:
            reportGrowthContent
        case .hardPaywallValue:
            hardPaywallValueContent
        case .hardPaywallChoice:
            hardPaywallChoiceContent

        // Day 2-6 tips等（このバーでは表示しない）
        default:
            EmptyView()
        }
    }

    // MARK: - Diagnosis Question Template

    private func diagnosisQuestion(category: String, question: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(category)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.35))
                .textCase(.uppercase)

            Text(question)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)

            // 選択肢はphaseContent内のswitchから別途呼び出し
            choicesForCurrentPhase
        }
    }

    // MARK: - Choices

    @ViewBuilder
    private var choicesForCurrentPhase: some View {
        switch viewModel.currentPhase {
        case .diagnosisA1:
            choiceButtons(DeviationFrequency.allCases) { viewModel.answerDeviationFrequency($0) }
        case .diagnosisA2:
            choiceButtons(MaxFocusDuration.allCases) { viewModel.answerMaxFocusDuration($0) }
        case .diagnosisA3:
            multiChoiceButtons(HyperFocusConsequence.allCases) { viewModel.answerConsequences($0) }
        case .diagnosisA4:
            choiceButtons(AIDeviationFrequency.allCases) { viewModel.answerAIDeviation($0) }
        case .diagnosisB1:
            innerVoiceChoices
        case .diagnosisB2:
            choiceButtons(PostFocusEmotion.allCases) { viewModel.answerPostFocusEmotion($0) }
        case .diagnosisB3:
            choiceButtons(StopDelay.allCases) { viewModel.answerStopDelay($0) }
        case .diagnosisB4:
            choiceButtons(InterruptionResistance.allCases) { viewModel.answerInterruptionResistance($0) }
        case .diagnosisC1:
            choiceButtons(SelfAwarenessLevel.allCases) { viewModel.answerSelfAwareness($0) }
        case .diagnosisC2:
            choiceButtons(SelfRegulationLevel.allCases) { viewModel.answerSelfRegulation($0) }
        case .diagnosisC3:
            choiceButtons(MetaCognitionHabit.allCases) { viewModel.answerMetaCognitionHabit($0) }
        case .diagnosisC4:
            choiceButtons(BlindExpectation.allCases) { viewModel.answerBlindExpectation($0) }
        case .trialReflection:
            choiceButtons(TrialReflectionAnswer.allCases) { viewModel.answerTrialReflection($0) }
        default:
            EmptyView()
        }
    }

    // MARK: - Choice Button Helpers

    private func choiceButtons<T: CaseIterable & RawRepresentable>(
        _ cases: [T],
        action: @escaping (T) -> Void
    ) -> some View where T: Sendable, T.RawValue == String {
        VStack(spacing: 4) {
            ForEach(Array(cases.enumerated()), id: \.offset) { _, item in
                Button(action: { action(item) }) {
                    Text(displayText(for: item))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 複数選択用ボタン（Q6: 過集中後の影響）
    @State private var selectedConsequences: Set<HyperFocusConsequence> = []

    private func multiChoiceButtons<T: CaseIterable & RawRepresentable & Hashable>(
        _ cases: [T],
        action: @escaping ([T]) -> Void
    ) -> some View where T: Sendable, T.RawValue == String {
        VStack(spacing: 4) {
            ForEach(Array(cases.enumerated()), id: \.offset) { _, item in
                Button(action: {
                    // 複数選択のトグル（HyperFocusConsequence専用）
                    if let consequence = item as? HyperFocusConsequence {
                        if selectedConsequences.contains(consequence) {
                            selectedConsequences.remove(consequence)
                        } else {
                            selectedConsequences.insert(consequence)
                        }
                    }
                }) {
                    HStack {
                        let isSelected: Bool = {
                            if let consequence = item as? HyperFocusConsequence {
                                return selectedConsequences.contains(consequence)
                            }
                            return false
                        }()

                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 12))
                            .foregroundColor(isSelected ? .white : .white.opacity(0.3))

                        Text(displayText(for: item))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // 複数選択の確定ボタン
            if !selectedConsequences.isEmpty {
                Button(action: {
                    if let typedItems = Array(selectedConsequences) as? [T] {
                        action(typedItems)
                    }
                }) {
                    Text("次へ（\(selectedConsequences.count)個選択）")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 14)
                        .frame(height: 28)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    /// 内なる声の選択肢（Q8: 特別なUI — 長い台詞を表示）
    private var innerVoiceChoices: some View {
        VStack(spacing: 4) {
            ForEach(InnerVoiceType.allCases, id: \.rawValue) { voice in
                Button(action: { viewModel.answerInnerVoice(voice) }) {
                    HStack(spacing: 8) {
                        Text(voice.icon)
                            .font(.system(size: 14))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("「\(voice.voiceQuote)」")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Special Content Views

    /// 声の4タイプ表示（#19）
    private var voiceTypesContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("内なる声の4タイプ")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            ForEach(InnerVoiceType.allCases, id: \.rawValue) { voice in
                let isUserType = voice == viewModel.diagnosis.innerVoiceType
                HStack(spacing: 8) {
                    Text(voice.icon)
                        .font(.system(size: 14))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(voice.displayName)
                            .font(.system(size: 12, weight: isUserType ? .bold : .medium, design: .rounded))
                            .foregroundColor(isUserType ? .white : .white.opacity(0.5))
                        Text(voice.runawayPattern)
                            .font(.system(size: 10, weight: .regular, design: .rounded))
                            .foregroundColor(isUserType ? .white.opacity(0.7) : .white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(isUserType ? Color.white.opacity(0.15) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    /// ローディング演出（#28）
    private var loadingContent: some View {
        VStack(spacing: 12) {
            if viewModel.isLoadingPlan {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
                Text("あなた専用のトレーニングプランを作成中...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// プラン概要（#29）
    private var planContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたの処方箋")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let plan = viewModel.plan {
                planRow(icon: "clock", label: "リマインド間隔", value: "\(plan.reminderInterval)分")
                planRow(icon: "eye.slash", label: "閉眼時間", value: "\(plan.eyeCloseDuration)秒")
                planRow(icon: "flame", label: "1日のトレーニング目標", value: "\(plan.dailyGoal)回")
            }
        }
    }

    private func planRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    /// あなたの内なる声タイプ（#30）
    private var voiceTypeResultContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("あなたの内なる声")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let voice = viewModel.diagnosis.innerVoiceType {
                HStack(spacing: 8) {
                    Text(voice.icon)
                        .font(.system(size: 20))
                    Text("「\(voice.displayName)」")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("中断の瞬間にこの声に気づくことが、最初のトレーニングです")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    /// ソフトペイウォール（#32）
    private var softPaywallContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("5秒を、もっと深いトレーニングに")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            proFeatureCard(icon: "🏋️", title: "トレーニングサイクル", desc: "閉眼前に内なる声チェック + 開眼後に象使いの判断ガイド")
            proFeatureCard(icon: "📊", title: "気づきの筋力トラッキング", desc: "毎週、成長をデータで確認")
            proFeatureCard(icon: "🚨", title: "暴走検知", desc: "スキップが続くと強めに介入")
        }
    }

    private func proFeatureCard(icon: String, title: String, desc: String) -> some View {
        HStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                Text(desc)
                    .font(.system(size: 10, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// 完了画面（#33）
    private var doneContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("準備完了！")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let plan = viewModel.plan {
                Text("最初のトレーニングは\(plan.reminderInterval)分後。\n7日後に成長をお見せします。")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("30分ごとにお知らせします。\n設定はメニューバーからいつでも。")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Day 7 Report Views

    /// トレーニング記録（#R1）
    private var reportTrainingLogContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7日間のトレーニング記録")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let report = viewModel.reportContent {
                reportRow(label: "セッション完了", value: "\(report.totalSessions - report.skippedSessions)回")
                reportRow(label: "合計閉眼時間", value: formatDuration(report.totalClosedDuration))
                reportRow(label: "スキップ率", value: "\(Int(report.skipRate * 100))%")
            }
        }
    }

    /// 暴走パターン（#R2: ヒートマップ）
    private var reportRunawayPatternContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("あなたの暴走パターン")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let report = viewModel.reportContent {
                if let voice = report.dominantVoiceType {
                    HStack(spacing: 6) {
                        Text(voice.icon)
                            .font(.system(size: 14))
                        Text("最も多い内なる声: 「\(voice.displayName)」")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                if let peak = report.peakSkipDayHour {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.8))
                        Text("スキップが多い時間帯: \(Day7ReportContent.weekdayName(peak.weekday))曜日 \(peak.hour)時台")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Text("象が暴走しやすい時間帯に注意すると、トレーニング効果が上がります")
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    /// 気づきの成長（#R3）
    private var reportGrowthContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("気づきの成長")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let report = viewModel.reportContent {
                reportRow(label: "軌道修正した回数", value: "\(report.courseCorrections)回")

                if let level = report.initialSelfRegulation {
                    Text("初日に「\(level.displayText)」と答えたあなたが、\(report.courseCorrections)回も軌道修正できました")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("気づきの筋肉は確実に育っています")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    /// ハードペイウォール — Pro価値提案（#R4）
    private var hardPaywallValueContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("もっと深いトレーニングへ")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            if let report = viewModel.reportContent {
                if report.skipRate > 0.3 {
                    Text("スキップ率\(Int(report.skipRate * 100))%——暴走検知で象を捕まえませんか？")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            proFeatureCard(icon: "🏋️", title: "トレーニングサイクル", desc: "閉眼前に内なる声チェック + 開眼後に象使いの判断ガイド")
            proFeatureCard(icon: "📊", title: "週次レポート", desc: "暴走パターンの変化を毎週データで確認")
            proFeatureCard(icon: "🚨", title: "暴走検知リマインド", desc: "スキップが続くと強めに介入して象を止める")
        }
    }

    /// ハードペイウォール — 選択（#R5）
    private var hardPaywallChoiceContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("選んでください")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            // Pro CTA
            Button(action: { /* TODO: Pro購入フロー */ }) {
                Text("Proにアップグレード")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            // 無料で続ける
            Button(action: { viewModel.advance() }) {
                Text("無料で続ける")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Report Helpers

    private func reportRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)分\(secs)秒"
        }
        return "\(secs)秒"
    }

    // MARK: - Text Content Helper

    private func textContent(main: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(main)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(2)

            Text(sub)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Action Handling

    private var actionLabel: String? {
        let phase = viewModel.currentPhase
        // 診断質問は選択肢タップで進むためボタン不要
        if phase.isDiagnosis && !phase.isBridge { return nil }
        // ローディング中はボタン不要
        if phase == .planLoading { return nil }

        switch phase {
        case .welcome, .hook, .promise: return "次へ"
        case .diagnosisBridgeAB, .diagnosisBridgeBC: return "次へ"
        case .camera: return "カメラを許可する"
        case .trialReflection: return nil // 選択肢で進む
        case .softPaywall: return "まずは7日間、無料で体験"
        case .done: return "はじめる"
        // Day 7
        case .reportTrainingLog, .reportRunawayPattern, .reportGrowth: return "次へ"
        case .hardPaywallValue: return "次へ"
        case .hardPaywallChoice: return nil // ボタンはコンテンツ内
        default: return "次へ"
        }
    }

    private var showsBackButton: Bool {
        if viewModel.isDay7Flow {
            let sequence = OnboardingPhase.day7Sequence
            guard let index = sequence.firstIndex(of: viewModel.currentPhase) else { return false }
            return index > 0
        }
        guard let index = viewModel.currentPhase.day1Index else { return false }
        return index > 0 && viewModel.currentPhase != .done
    }

    private func handleAction() {
        switch viewModel.currentPhase {
        case .camera:
            viewModel.handleCameraPermission()
        default:
            viewModel.advance()
        }
    }

    // MARK: - Display Text Helper

    private func displayText<T>(for item: T) -> String {
        switch item {
        case let v as DeviationFrequency: return v.displayText
        case let v as MaxFocusDuration: return v.displayText
        case let v as HyperFocusConsequence: return v.displayText
        case let v as AIDeviationFrequency: return v.displayText
        case let v as PostFocusEmotion: return v.displayText
        case let v as StopDelay: return v.displayText
        case let v as InterruptionResistance: return v.displayText
        case let v as SelfAwarenessLevel: return v.displayText
        case let v as SelfRegulationLevel: return v.displayText
        case let v as MetaCognitionHabit: return v.displayText
        case let v as BlindExpectation: return v.displayText
        case let v as TrialReflectionAnswer: return v.displayText
        default: return String(describing: item)
        }
    }
}
