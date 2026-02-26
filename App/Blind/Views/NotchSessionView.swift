import SwiftUI
import AppKit
import BlindCore

/// 4フェーズを統合したセッションView。
/// NotchOverlayWindowのcontentViewとして使用される。
struct NotchSessionView: View {
    @ObservedObject var viewModel: SessionViewModel
    let hasNotch: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 黒背景（目を閉じている間はopacityで暗転を表現）
                Color.black
                    .opacity(backgroundOpacity)

                // コンテンツ（フェーズに応じて切り替え）
                phaseContent(size: geo.size)
            }
        }
        .ignoresSafeArea()
    }

    /// 暗転のopacity: 小窓時は1.0、フルスクリーン時はclosedProgressで0→1
    private var backgroundOpacity: Double {
        switch viewModel.currentPhase {
        case .encounter where viewModel.eyesClosed:
            // 目を閉じ始め〜カウントダウン中: progressに応じて暗転
            return 0.15 + 0.85 * viewModel.closedProgress
        case .immersion, .awakening:
            return 1.0
        default:
            return 1.0
        }
    }

    @ViewBuilder
    private func phaseContent(size: CGSize) -> some View {
        switch viewModel.currentPhase {
        case .idle:
            EmptyView()

        case .summon:
            // Phase 1: 目キャラがidle状態で出現
            EyeCharacterView(
                state: .idle,
                size: fixedEyeSize
            )

        case .encounter:
            // Phase 2: 目キャラ + メッセージ
            encounterContent(size: size)

        case .immersion:
            // Phase 3: フルスクリーン黒 + 閉じた目
            immersionContent(size: size)

        case .awakening:
            // Phase 4: ウインク + 覚醒メッセージ
            awakeningContent(size: size)

        case .completed, .cancelled:
            EmptyView()
        }
    }

    // MARK: - Phase 2: Encounter

    @ViewBuilder
    private func encounterContent(size: CGSize) -> some View {
        // 目を上部に固定（フルスクリーン拡大時も位置・サイズ不変）
        VStack(spacing: 16) {
            EyeCharacterView(
                state: viewModel.eyeCharacterState,
                size: fixedEyeSize
            )

            // メッセージ（常に表示）
            Text(encounterMessage)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            // カウントダウン進捗（目を閉じている間、常に表示）
            if viewModel.eyesClosed {
                ProgressView(value: viewModel.closedProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .white.opacity(0.6)))
                    .frame(width: min(size.width * 0.5, 200))
            }

            // アクセシビリティ: 手動完了ボタン
            if !viewModel.eyesClosed {
                Button(action: {
                    viewModel.manualComplete()
                }) {
                    Text("手動で完了")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("セッションを手動で完了する")
            }
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.updatesFrequently)
    }

    private var encounterMessage: String {
        if !viewModel.faceDetected {
            return "ここだよ"
        }
        if viewModel.eyesClosed {
            let remaining = max(0, viewModel.requiredClosedDuration - viewModel.closedDuration)
            return "あと \(Int(ceil(remaining))) 秒..."
        }
        return "目を閉じて"
    }

    // MARK: - Phase 3: Immersion（短い遷移フェーズ、すぐawakeningへ）

    @ViewBuilder
    private func immersionContent(size: CGSize) -> some View {
        VStack(spacing: 20) {
            EyeCharacterView(
                state: .closed,
                size: fixedEyeSize
            )
            Text("...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Phase 4: Awakening

    @ViewBuilder
    private func awakeningContent(size: CGSize) -> some View {
        VStack(spacing: 20) {
            EyeCharacterView(
                state: .winking,
                size: fixedEyeSize
            )

            Text("おかえり")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Helpers

    /// 目キャラの固定サイズ（ウィンドウサイズに依存しない）
    private var fixedEyeSize: CGSize {
        CGSize(width: 176, height: 106)
    }
}

#Preview("Encounter") {
    let vm = SessionViewModel()
    NotchSessionView(viewModel: vm, hasNotch: true)
        .frame(width: 400, height: 250)
}
