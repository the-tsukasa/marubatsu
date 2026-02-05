# まるばつ（○×）

SwiftUI と SpriteKit で作った○×ゲームです。タイトル、二人対戦、AI 対戦、AIゴッド対戦ができます。

## 動作環境

- iOS
- Xcode でビルド・実行

## 画面

| 1 | 2 |
|---|---|
| ![デモ1](marubatsu/marubatsu_demo_iphone17promax_001.png) | ![デモ2](marubatsu/marubatsu_demo_iphone17promax_002.png) |
| 3 | 4 |
| ![デモ3](marubatsu/marubatsu_demo_iphone17promax_003.png) | ![デモ4](marubatsu/marubatsu_demo_iphone17promax_004.png) |

## 主なファイル

- `ContentView.swift` — 画面切り替え
- `GameScene.swift` — 盤面の処理
- `AIEngine.swift` / `AIGodEngine.swift` — AI と AIゴッド
