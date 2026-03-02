import SwiftUI
import BlindCore

/// Macのノッチシルエットを描画するSwiftUI Shape。
/// 上辺はベゼルに融合するフラット、左上・右上は逆アール（凹カーブ）、
/// 左下・右下は通常の凸角丸。
struct NotchShape: Shape {
    let displayMode: DisplayMode

    /// 逆アールの半径
    private var inverseRadius: CGFloat { displayMode == .island ? 20 : 12 }
    /// 下部の角丸半径
    private var bottomRadius: CGFloat { displayMode == .island ? 20 : 16 }

    func path(in rect: CGRect) -> Path {
        let ir = inverseRadius
        let br = bottomRadius

        var path = Path()

        // 上辺: (0, 0) → (width, 0) ベゼルに融合
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // 右上: 逆アール（凹カーブ）
        // centerをシェイプ外（右外側）に配置して凹面弧を描く
        // 上辺右端 → 右辺上部へ凹カーブ
        path.addArc(
            center: CGPoint(x: rect.width + ir, y: ir),
            radius: ir,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        // 右辺直線（逆アール下端 → 右下角丸開始点）
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - br))

        // 右下: 通常の凸角丸
        path.addArc(
            center: CGPoint(x: rect.width - br, y: rect.height - br),
            radius: br,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        // 下辺
        path.addLine(to: CGPoint(x: br, y: rect.height))

        // 左下: 通常の凸角丸
        path.addArc(
            center: CGPoint(x: br, y: rect.height - br),
            radius: br,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        // 左辺直線（左下角丸上端 → 逆アール開始点）
        path.addLine(to: CGPoint(x: 0, y: ir))

        // 左上: 逆アール（凹カーブ）
        // centerをシェイプ外（左外側）に配置
        path.addArc(
            center: CGPoint(x: -ir, y: ir),
            radius: ir,
            startAngle: .degrees(270),
            endAngle: .degrees(360),
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Previews

#Preview("Notch") {
    NotchShape(displayMode: .notch)
        .fill(.black)
        .frame(width: 300, height: 67)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}

#Preview("No Notch") {
    NotchShape(displayMode: .noNotch)
        .fill(.black)
        .frame(width: 280, height: 70)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}

#Preview("Island") {
    NotchShape(displayMode: .island)
        .fill(.black)
        .frame(width: 360, height: 70)
        .padding(40)
        .background(Color.gray.opacity(0.3))
}
