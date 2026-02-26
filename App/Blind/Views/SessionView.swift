import SwiftUI

/// レガシーフォールバック: NotchSessionViewに問題がある場合に切り戻し可能。
/// AppDelegateのstartSession()でNotchSessionView→SessionViewに差し替えるだけで復帰できる。
struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Eye status indicator
            Circle()
                .fill(indicatorColor)
                .frame(width: 40, height: 40)
                .shadow(color: indicatorColor.opacity(0.5), radius: 10)
                .animation(.easeInOut(duration: 0.3), value: viewModel.eyesClosed)
                .animation(.easeInOut(duration: 0.3), value: viewModel.faceDetected)

            // Status text
            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)

            // Progress indicator (when eyes are closed)
            if viewModel.eyesClosed {
                ProgressView(value: viewModel.closedProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .red))
                    .frame(width: 100)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
    }

    private var indicatorColor: Color {
        if !viewModel.faceDetected {
            return .yellow
        }
        return viewModel.eyesClosed ? .red : .green
    }

    private var statusText: String {
        if !viewModel.faceDetected {
            return "カメラに顔を向けてください"
        }
        if viewModel.eyesClosed {
            let remaining = viewModel.requiredClosedDuration - viewModel.closedDuration
            return "あと \(Int(remaining)) 秒..."
        } else {
            return "目を閉じてください"
        }
    }
}

#Preview {
    SessionView(viewModel: SessionViewModel())
        .frame(width: 200, height: 150)
        .background(Color.gray)
}
