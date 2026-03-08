import SwiftUI
import BlindCore

/// オンボーディング用の拡張テキスト帯。
/// メインテキスト・サブテキスト・アクションボタン・×ボタンを含む。
/// `.trySession` フェーズでは EmptyView を返す。
struct OnboardingTextBar: View {
    let phase: OnboardingPhase
    var onAction: (() -> Void)?
    var onDismiss: (() -> Void)?

    var body: some View {
        switch phase {
        case .trySession:
            EmptyView()
        default:
            bar
        }
    }

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

            // メインコンテンツ
            VStack(alignment: .leading, spacing: 4) {
                Text(mainText)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)

                Text(subText)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Button(action: { onAction?() }) {
                        Text(actionLabel)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minHeight: 80)
        .frame(maxWidth: .infinity)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var mainText: String {
        switch phase {
        case .welcome:    return "はじめまして！"
        case .camera:     return "カメラを使います"
        case .done:       return "準備完了！"
        case .trySession: return ""
        default:          return ""
        }
    }

    private var subText: String {
        switch phase {
        case .welcome:    return "Blindは、画面から離れる小さな休憩を作るアプリです"
        case .camera:     return "目を閉じたことを感知するために使います。映像は保存・送信しません。"
        case .done:       return "30分ごとにお知らせします。設定はメニューバーからいつでも。"
        case .trySession: return ""
        default:          return ""
        }
    }

    private var actionLabel: String {
        switch phase {
        case .welcome:    return "次へ"
        case .camera:     return "カメラを許可する"
        case .done:       return "はじめる"
        case .trySession: return ""
        default:          return "次へ"
        }
    }
}

#Preview("welcome") {
    OnboardingTextBar(phase: .welcome)
        .frame(width: 360)
        .padding()
        .background(Color.gray.opacity(0.3))
}

#Preview("camera") {
    OnboardingTextBar(phase: .camera)
        .frame(width: 360)
        .padding()
        .background(Color.gray.opacity(0.3))
}

#Preview("done") {
    OnboardingTextBar(phase: .done)
        .frame(width: 360)
        .padding()
        .background(Color.gray.opacity(0.3))
}
