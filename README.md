# Marubatsu

SwiftUI + SpriteKit で作ったシンプルな○×ゲームのデモ。ウェルカム画面から対局、AI 対戦までの流れを確認できます。

## 使い方
1. Xcode 15 以降で `marubatsu.xcodeproj` を開く。
2. シミュレータまたは実機で実行すれば、モード切り替えや AI 対戦を試せます。

## 主なファイル
- `marubatsu/ContentView.swift`：SwiftUI 入口。`WelcomeScene` と `GameScene` を切り替え。
- `marubatsu/GameScene.swift`：盤面・入力・UI を統括。
- `marubatsu/AIEngine.swift` / `marubatsu/AIGodEngine.swift`：通常 AI と「AI ゴッド」。
- `marubatsu/Handlers`、`TouchHandlers`、`Renderers`：モード処理・タッチ・描画の分離実装。
