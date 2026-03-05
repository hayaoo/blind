import SwiftUI
import BlindCore

/// ノッチ形状のクリッピング用Shape（将来の拡張用に残存）。
/// 現在、凹角丸の視覚効果は NotchSessionView 側の destinationOut 合成で実現。
/// このShapeは目キャラのオーバーフロー防止など、
/// 追加のクリッピングが必要になった場合に使用する。
struct NotchShape: Shape {
    let bezelHeight: CGFloat

    private let bottomRadius: CGFloat = 16
    private var cr: CGFloat { NotchGeometry.concaveRadius }

    func path(in rect: CGRect) -> Path {
        let br = bottomRadius
        let w = rect.width
        let h = rect.height

        var path = Path()
        path.move(to: CGPoint(x: cr, y: 0))
        path.addLine(to: CGPoint(x: w - cr, y: 0))
        path.addLine(to: CGPoint(x: w - cr, y: bezelHeight))
        path.addLine(to: CGPoint(x: w, y: bezelHeight))
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addQuadCurve(
            to: CGPoint(x: w - br, y: h),
            control: CGPoint(x: w, y: h)
        )
        path.addLine(to: CGPoint(x: br, y: h))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h - br),
            control: CGPoint(x: 0, y: h)
        )
        path.addLine(to: CGPoint(x: 0, y: bezelHeight))
        path.addLine(to: CGPoint(x: cr, y: bezelHeight))
        path.closeSubpath()
        return path
    }
}
