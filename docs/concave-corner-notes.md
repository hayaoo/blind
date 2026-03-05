# 凹角丸（Concave Corner）実装ノート

macOS ノッチ UI でベゼル境界に「外向き角丸」を実装する際の知見。

## ゴール

物理ノッチからアプリの拡張領域への遷移部分に、実際の MacBook ノッチと同じ
凹カーブ（concave corner / inverse rounded corner）を描画する。

```
████████████████████████  ← ベゼル（不可視）
██████████████████╮  ╭██  ← 凹角丸（外向き）
                  │  │
                  ╰──╯    ← 凸角丸（通常）
```

## 試行履歴と失敗パターン

### 試行1: 単一Path + addArc（arc中心をrect外に配置）

**旧コード（プロジェクト初期実装）:**
```swift
// center を rect の外側に配置
path.addArc(
    center: CGPoint(x: rect.width + ir, y: ir),
    radius: ir,
    startAngle: .degrees(180),
    endAngle: .degrees(90),
    clockwise: true
)
```

**結果**: arc が rect 外にはみ出し、ウィンドウフレームでクリップされて不可視。

**学び**: arc中心を rect 外に置くと、弧が rect 境界を超える。ウィンドウフレーム＝rect サイズなので見えない。

---

### 試行2: ベゼル境界でボディを狭めて凹遷移

```swift
// ベゼル境界(by)からボディを ir 分狭くする
path.addLine(to: CGPoint(x: w, y: by))
path.addArc(
    center: CGPoint(x: w, y: by + ir), // or (w - ir, by)
    radius: ir,
    startAngle: .degrees(270),
    endAngle: .degrees(180), // or .degrees(0)
    clockwise: true // or false
)
```

**結果**: 何度 center / startAngle / endAngle / clockwise を変えても凸角丸にしか見えない。

**学び**:
- SwiftUI Path の `clockwise` パラメータは **数学座標系（y-up）基準**。画面座標系（y-down）とは反転する。
  - `clockwise: false` = 角度増加方向（数学的反時計回り = 画面上は時計回り）
  - `clockwise: true` = 角度減少方向（数学的時計回り = 画面上は反時計回り）
- `startAngle: 270°, endAngle: 0°` のような wrap-around は挙動が不確実。`endAngle: 360°` を使うべき。
- arc中心の位置と clockwise の組み合わせで凹/凸が変わるが、直感に反する結果になりやすい。
- **ボディを狭めるアプローチ自体が凹に見えない**: 可視領域（ベゼル下）だけ見ると、狭い→広いの遷移は結局「凸角丸」に見える。

---

### 試行3: 3パーツ合成（rect + 凸角丸ボディ + 楔ピース）

```swift
// Part 1: ベゼル矩形
path.addRect(CGRect(x: 0, y: 0, width: w, height: by))
// Part 2: ボディ（addQuadCurve で凸角丸）
// Part 3: 楔ピース（addQuadCurve で隙間埋め）
```

**結果**: 変化なし。複数 sub-path の合成で winding rule の問題、
または addQuadCurve の曲線方向が期待と違った可能性。

**学び**:
- 複数 sub-path を `addPath` で合成する場合、non-zero winding rule により
  逆方向のパスが重なると打ち消し合う（穴が開く）。
- `addRect` の winding 方向と手動パスの方向が一致するか検証が必要。
- Quadratic Bézier は円弧の近似であり、control point の位置で曲線の膨らみ方向が変わる。

---

### 試行4: View合成 + blendMode(.destinationOut)

**結果**: destinationOut でCircleを切り抜く方向は「内側に凹む」。逆方向。
小さな正方形 + Circleで切り抜くことで「裾」を追加するアプローチは動作したが複雑。

---

### 試行5（採用）: Path.addArc による clipShape

```swift
// NotchShape: 凹角丸を含む単一パス
path.move(to: CGPoint(x: cr, y: 0))         // 上辺（cr分インセット）
path.addLine(to: CGPoint(x: w - cr, y: 0))
path.addLine(to: CGPoint(x: w - cr, y: by))  // ベゼル境界まで
path.addArc(                                  // 右凹角丸
    center: CGPoint(x: w - cr, y: by + cr),
    radius: cr,
    startAngle: .degrees(-90),
    endAngle: .degrees(0),
    clockwise: false
)
// ... 下辺凸角丸 → 左凹角丸 → close
```

**成功要因**:
1. ウィンドウフレーム（summonFrame）を左右 `concaveRadius` 分広げた → Path が rect 内に収まる
2. `clockwise: false` = SwiftUI y-down座標で角度増加方向（画面上時計回り）→ 外向きの弧
3. 凹角丸を「輪郭パスの一部」として描く → addArc 1回で済む（切り取り操作不要）

**設計**: `Color.black` + `.clipShape(NotchShape(...))` のみ。
destinationOut や compositingGroup は不要。最もシンプルなアプローチ。

---

## 重要な教訓

### ウィンドウフレームが全ての原因

凹角丸が見えなかった根本原因は Path の描き方ではなく、**NSWindow のフレームが物理ノッチと同サイズだった**こと。凹角丸はフレーム外にはみ出す形状のため、クリップされて不可視だった。フレームを `concaveRadius` 分広げることで解決。

### SwiftUI Path.addArc の罠

1. **clockwise の意味が座標系依存**: SwiftUI は y-down だが、`clockwise` パラメータは y-up 基準。
2. **凹角丸は addArc で描ける**: 初期の試行では「凹角丸は切り取り操作」と思い込んでいたが、実際にはパスの輪郭として描画可能。ウィンドウフレームのクリッピングが原因で見えていなかっただけ。

### デバッグ手法

- **赤枠オーバーレイ**: ウィンドウ境界の可視化に有効。
- **ファイル書き出しデバッグ**: LSUIElement アプリでは print/NSLog が見えない場合あり。`/tmp/` にファイルを書き出してランタイム値を確認。
- **プロセス再起動**: `pkill -x AppName` が必須。Finder からの「開く」は既存プロセスを前面に出すだけ。

## 関連ファイル

- `App/Blind/Views/NotchShape.swift` — 凹角丸を含むクリッピング Shape（全モード共通）
- `App/Blind/Views/NotchSessionView.swift` — ノッチUI + 目キャラ + テキスト帯
- `Packages/BlindCore/Sources/BlindCore/Models/NotchGeometry.swift` — ノッチ座標・フレーム計算
