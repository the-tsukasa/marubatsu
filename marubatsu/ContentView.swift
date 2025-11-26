import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var scene: GameScene = {
        let scene = GameScene()
        return scene
    }()

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .onAppear {
                    // 使用实际屏幕尺寸
                    scene.size = geometry.size
                }
                .onChange(of: geometry.size) { oldSize, newSize in
                    // 屏幕尺寸改变时更新
                    scene.size = newSize
                }
        }
    }
}
