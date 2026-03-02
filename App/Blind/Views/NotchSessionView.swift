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
    var onDismiss: (() -> Void)?

    @State private var slideStartDate = Date()

    var body: some View {
        GeometryReader { geo in
            notchLayout(size: geo.size)
        }
        .ignoresSafeArea()
    }

    // MARK: - Text Bar Visibility

    /// テキスト帯を表示するか
    private var showsTextBar: Bool {
        switch viewModel.currentPhase {
        case .encounter, .immersion, .awakening:
            return true
        default:
            return false
        }
    }

    // MARK: - Notch Layout

    /// 目のスライド最大幅（ノッチ幅の端まで移動）
    private func maxSlideDistance(containerWidth: CGFloat) -> CGFloat {
        let eyeWidth = fixedEyeSize.width
        return max(0, (containerWidth - eyeWidth) / 2 - 4)
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
                    NotchShape(displayMode: displayMode)
                        .fill(.black)

                    EyeCharacterView(
                        state: eyeState,
                        size: fixedEyeSize,
                        tiltFactor: tilt
                    )
                    .offset(x: slideX)
                }
            }
            .frame(height: notchZoneHeight)
            .clipShape(NotchShape(displayMode: displayMode))

            // ゾーン2: テキスト帯（角丸黒背景）
            if showsTextBar {
                textBar(width: size.width)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// テキスト帯: テキスト左寄せ + ×ボタン右端 + bottom borderプログレスバー
    @ViewBuilder
    private func textBar(width: CGFloat) -> some View {
        HStack(spacing: 0) {
            Text(textMessage)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)

            Spacer()

            if showsDismissButton {
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("セッションを閉じる")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: NotchGeometry.textBarHeight)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .bottom) {
            // プログレスバー: テキスト帯の下端をバーとして使用
            if viewModel.eyesClosed {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(Color.white.opacity(0.5))
                        .frame(
                            width: geo.size.width * viewModel.closedProgress,
                            height: 3
                        )
                }
                .frame(height: 3)
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
            }
        }
    }

    // MARK: - State

    private var eyeState: EyeCharacterState {
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
            if viewModel.eyesClosed {
                let remaining = max(0, viewModel.requiredClosedDuration - viewModel.closedDuration)
                return "あと \(Int(ceil(remaining))) 秒..."
            }
            return "目を閉じて、今を確かめよう"
        case .immersion:
            return "..."
        case .awakening:
            return "おかえり"
        default:
            return ""
        }
    }

    /// ×ボタン: 目を閉じていない & immersion/awakeningでない時に表示
    private var showsDismissButton: Bool {
        switch viewModel.currentPhase {
        case .encounter where !viewModel.eyesClosed:
            return true
        default:
            return false
        }
    }

    // MARK: - Slide Animation

    /// デフォルトの左寄せバイアス（-1..1の範囲、負=左）
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
}

#Preview("Encounter") {
    let vm = SessionViewModel()
    NotchSessionView(viewModel: vm, displayMode: .notch, notchZoneHeight: 67)
        .frame(width: 888, height: 133)
}
