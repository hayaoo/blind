import SwiftUI

struct SessionView: View {
    @ObservedObject var viewModel: SessionViewModel

    var body: some View {
        VStack(spacing: 12) {
            // Eye status indicator
            Circle()
                .fill(viewModel.eyesClosed ? Color.red : Color.green)
                .frame(width: 40, height: 40)
                .shadow(color: viewModel.eyesClosed ? .red.opacity(0.5) : .green.opacity(0.5), radius: 10)
                .animation(.easeInOut(duration: 0.3), value: viewModel.eyesClosed)

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
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC key
                    viewModel.cancelSession()
                    return nil
                }
                return event
            }
        }
    }

    private var statusText: String {
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
