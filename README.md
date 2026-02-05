# まるばつ（○×）

SwiftUI と SpriteKit で作成した ○×ゲーム（三目並べ）です。  
二人対戦、AI 対戦、AI ゴッド対戦に対応しています。

---

## 動作環境
- iOS  
- Xcode でビルド・実行

---

## 画面

<p align="center">
  <img src="marubatsu/marubatsu_demo_iphone17promax_004.png" width="22%" />
  <img src="marubatsu/marubatsu_demo_iphone17promax_001.png" width="22%" />
  <img src="marubatsu/marubatsu_demo_iphone17promax_002.png" width="22%" />
  <img src="marubatsu/marubatsu_demo_iphone17promax_003.png" width="22%" />
</p>

<p align="center">
  <sub>タイトル ｜ 二人対戦 ｜ AI対戦 ｜ AIゴッド</sub>
</p>

---

## 主なファイル

- `ContentView.swift` — 画面切り替え  
- `GameScene.swift` — 盤面処理  
- `AIEngine.swift` / `AIGodEngine.swift` — AI ロジック
