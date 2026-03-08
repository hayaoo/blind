import SwiftUI
import AppKit
import BlindCore

/// 4フェーズを統合したセッションView。
/// ノッチ形状ゾーン + テキスト帯ゾーンに分離。
/// 全画面暗転は別のバックドロップウィンドウが担当。
struct NotchSessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    let displayMode: DisplayMode
    let notchZoneHeight: CGFloat
    /// 物理ノッチの高さ（ベゼル境界）。`.notch`以外では0。
    let bezelHeight: CGFloat
    var onDismiss: (() -> Void)?
    /// オンボーディングのアクションボタンタップ時のコールバック
    var onOnboardingAction: (() -> Void)?

    @State private var slideStartDate = Date()

    private var cr: CGFloat { NotchGeometry.concaveRadius }

    var body: some View {
        GeometryReader { geo in
            notchLayout(size: geo.size)
        }
        .ignoresSafeArea()
    }

    // MARK: - Text Bar Visibility

    /// 通常テキスト帯を表示するか（セッション中のみ）
    private var showsTextBar: Bool {
        // オンボーディングのtrySession中は通常テキスト帯を表示
        if viewModel.isOnboarding, viewModel.currentOnboardingPhase == .trySession {
            switch viewModel.currentPhase {
            case .encounter, .immersion, .awakening:
                return true
            default:
                return false
            }
        }
        // オンボーディング中（trySession以外）は通常テキスト帯は非表示
        if viewModel.isOnboarding { return false }
        // 通常セッション（preClose/postCloseは専用バーを使う）
        switch viewModel.currentPhase {
        case .encounter, .immersion, .awakening:
            return true
        default:
            return false
        }
    }

    /// オンボーディング拡張テキスト帯を表示するか
    private var showsOnboardingBar: Bool {
        guard viewModel.isOnboarding,
              let phase = viewModel.currentOnboardingPhase else { return false }
        // trySession中は通常テキスト帯を使う
        return phase != .trySession
    }

    // MARK: - Notch Black Shape

    /// 黒いノッチ形状。モード別:
    /// - `.noNotch`: 上辺フラット + 凹角丸の裾 + 下辺凸角丸（スクリーン端に融合）
    /// - `.notch`: 全角丸ピル。物理ノッチの下に表示。上部にノッチ高さ分の透明余白。
    /// - `.island`: 全角丸ピル。アイランド位置の下に表示。
    @ViewBuilder
    private func notchBlackShape(width: CGFloat) -> some View {
        switch displayMode {
        case .noNotch:
            // スクリーン端に融合: 上辺フラット + 凹角丸
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: 0
                )
                .fill(.black)
                .padding(.horizontal, cr)

                concaveFoot(alignment: .leading)
                concaveFoot(alignment: .trailing)
            }

        case .notch:
            // 物理ノッチと融合: ノッチ領域まで黒で覆い、ノッチ下端で凹角丸
            ZStack(alignment: .top) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 20,
                    bottomTrailingRadius: 20,
                    topTrailingRadius: 0
                )
                .fill(.black)
                .padding(.horizontal, cr)

                concaveFoot(alignment: .leading)
                concaveFoot(alignment: .trailing)
            }

        case .island:
            // アイランドの下に拡張: 上辺も角丸のピル形状
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.black)
                .padding(.horizontal, cr)
        }
    }

    /// 凹角丸の「裾」ピース（.noNotch 専用）。
    /// 黒い正方形(cr×cr) の内側コーナーを Circle で切り抜いて凹カーブを作る。
    @ViewBuilder
    private func concaveFoot(alignment: Alignment) -> some View {
        let isLeading = (alignment == .leading)

        Rectangle()
            .fill(.black)
            .frame(width: cr, height: cr)
            .overlay(alignment: isLeading ? .topTrailing : .topLeading) {
                Circle()
                    .fill(.black)
                    .frame(width: cr * 2, height: cr * 2)
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
            .frame(maxWidth: .infinity, alignment: isLeading ? .leading : .trailing)
    }

    // MARK: - Notch Layout

    private func maxSlideDistance(containerWidth: CGFloat) -> CGFloat {
        let eyeWidth = fixedEyeSize.width
        return max(0, (containerWidth - eyeWidth) / 2 - cr - 4)
    }

    @ViewBuilder
    private func notchLayout(size: CGSize) -> some View {
        VStack(spacing: NotchGeometry.gapHeight) {
            // ゾーン1: ノッチ形状 + 目キャラ（固定高さ）
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSince(slideStartDate)
                let slideX = computeSlideOffset(time: time, containerWidth: size.width)
                let maxDist = maxSlideDistance(containerWidth: size.width)
                let tilt: CGFloat = maxDist > 0 ? slideX / maxDist : 0

                ZStack {
                    notchBlackShape(width: size.width)

                    EyeCharacterView(
                        state: eyeState,
                        size: fixedEyeSize,
                        tiltFactor: tilt
                    )
                    .offset(x: slideX, y: eyeVerticalOffset)
                }
            }
            .frame(height: notchZoneHeight)

            // ゾーン2: テキスト帯 or オンボーディング拡張テキスト帯
            if showsOnboardingBar {
                if let extVM = viewModel.extendedOnboardingVM {
                    ExtendedOnboardingTextBar(
                        viewModel: extVM,
                        onDismiss: onDismiss
                    )
                    .padding(.horizontal, cr)
                    .padding(.bottom, 4)
                } else {
                    OnboardingTextBar(
                        phase: viewModel.currentOnboardingPhase ?? .welcome,
                        onAction: onOnboardingAction ?? { viewModel.advanceOnboarding() },
                        onDismiss: onDismiss
                    )
                    .padding(.horizontal, cr)
                    .padding(.bottom, 4)
                }
            } else if showsProTrainingBar {
                proTrainingBar
                    .padding(.horizontal, cr)
                    .padding(.bottom, 4)
            } else if showsTextBar {
                textBar(width: size.width)
                    .padding(.horizontal, cr)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Pro Training Bar (Pre-close / Post-close)

    @ViewBuilder
    private var proTrainingBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if viewModel.currentPhase == .preClose {
                preCloseContent
            } else if viewModel.currentPhase == .postClose {
                postCloseContent
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    /// Pre-close: 内なる声チェック
    private var preCloseContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("今、どの声が聞こえていますか？")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            ForEach(InnerVoiceType.allCases, id: \.rawValue) { voice in
                Button(action: { viewModel.selectPreCloseVoice(voice) }) {
                    HStack(spacing: 8) {
                        Text(voice.icon)
                            .font(.system(size: 12))
                        Text("「\(voice.voiceQuote)」")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }

            // 「静か」オプション（声なしで先に進む）
            Button(action: { viewModel.skipPreClose() }) {
                Text("静か（声は聞こえない）")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
        }
    }

    /// Post-close: 象使いの判断ガイド
    private var postCloseContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("象使いの判断")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            Text("目を開けて——今から何をしますか？")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.5))

            postCloseButton(.onTrack, label: "正しい方向に進んでいた。続ける", icon: "checkmark.circle")
            postCloseButton(.courseCorrect, label: "方向転換する", icon: "arrow.triangle.turn.up.right.circle")
            postCloseButton(.intentionalDetour, label: "意図的に別のことをしている", icon: "signpost.right")
            postCloseButton(.stillNeeded, label: "まだ必要な作業だった", icon: "hourglass.circle")
        }
    }

    private func postCloseButton(_ action: PostCloseAction, label: String, icon: String) -> some View {
        Button(action: { viewModel.selectPostCloseAction(action) }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Text(label)
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

    /// テキスト帯: テキスト左寄せ + ×ボタン右端
    @ViewBuilder
    private func textBar(width: CGFloat) -> some View {
        HStack(spacing: 8) {
            Text(textMessage)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)

            Spacer()

            if showsDismissButton {
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
                .accessibilityLabel("セッションを閉じる")
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 10)
        .frame(height: NotchGeometry.textBarHeight)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - State

    private var eyeState: EyeCharacterState {
        // オンボーディング（trySession以外）: フェーズに応じた目キャラ状態
        if viewModel.isOnboarding, viewModel.currentOnboardingPhase != .trySession {
            if let extVM = viewModel.extendedOnboardingVM {
                return extVM.eyeCharacterState
            }
            switch viewModel.currentOnboardingPhase {
            case .welcome: return .idle
            case .camera:  return .searching
            case .done:    return .winking
            default:       return .idle
            }
        }
        // 通常セッション or trySession
        switch viewModel.currentPhase {
        case .summon:
            return .idle
        case .encounter:
            return viewModel.eyeCharacterState
        case .immersion:
            return .closed
        case .awakening:
            return .closed
        case .completed:
            return .closed
        default:
            return .idle
        }
    }

    private var textMessage: String {
        switch viewModel.currentPhase {
        case .encounter:
            if !viewModel.faceDetected { return "ここだよ 👀" }
            return "目を閉じて、今を確かめよう"
        case .immersion:
            return "目を閉じて、今を確かめよう"
        case .awakening:
            return "おかえり"
        default:
            return ""
        }
    }

    /// Pre-close/Post-closeの拡張テキスト帯を表示するか
    private var showsProTrainingBar: Bool {
        guard !viewModel.isOnboarding else { return false }
        switch viewModel.currentPhase {
        case .preClose, .postClose:
            return true
        default:
            return false
        }
    }

    private var showsDismissButton: Bool {
        showsTextBar
    }

    // MARK: - Slide Animation

    private let defaultBias: CGFloat = -0.3

    private func computeSlideOffset(time: Double, containerWidth: CGFloat) -> CGFloat {
        let maxDist = maxSlideDistance(containerWidth: containerWidth)
        guard maxDist > 0 else { return 0 }

        switch viewModel.currentPhase {
        case .summon:
            return (defaultBias + CGFloat(sin(time * 0.3)) * 0.4) * maxDist
        case .encounter:
            if !viewModel.faceDetected {
                return CGFloat(saccadeSlide(time: time)) * maxDist
            }
            return defaultBias * maxDist
        default:
            return defaultBias * maxDist
        }
    }

    private func saccadeSlide(time: Double) -> Double {
        let holdDuration = 1.6
        let moveDuration = 0.2
        let cycleDuration = holdDuration + moveDuration
        let cycle = Int(time / cycleDuration)
        let cycleTime = time - Double(cycle) * cycleDuration

        func fixationPoint(_ index: Int) -> Double {
            let hash = sin(Double(index) * 127.1 + 311.7)
            return hash * 0.85
        }

        let from = fixationPoint(cycle)
        let to = fixationPoint(cycle + 1)

        if cycleTime < holdDuration {
            return from
        } else {
            let t = (cycleTime - holdDuration) / moveDuration
            let smooth = t * t * (3.0 - 2.0 * t)
            return from + (to - from) * smooth
        }
    }

    private var fixedEyeSize: CGSize {
        CGSize(width: 106, height: 64)
    }

    /// 目キャラの垂直オフセット。
    /// .notch/.island: 上部の物理領域(bezelHeight)を避けて、下の黒い領域の上下中央に配置。
    /// .noNotch: ZStack中央のまま（オフセットなし）。
    private var eyeVerticalOffset: CGFloat {
        guard bezelHeight > 0 else { return 0 }
        return bezelHeight / 2
    }
}

#Preview("Encounter") {
    let vm = SessionViewModel()
    NotchSessionView(viewModel: vm, displayMode: .notch, notchZoneHeight: 67, bezelHeight: 37)
        .frame(width: 888, height: 133)
}
