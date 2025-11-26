import SwiftUI
import SpriteKit

struct ContentView: View {
    /// 当前显示的场景类型
    @State private var currentSceneType: SceneType = .welcome
    
    /// 欢迎场景
    @State private var welcomeScene: WelcomeScene = {
        let scene = WelcomeScene()
        return scene
    }()
    
    /// 游戏场景
    @State private var gameScene: GameScene = {
        let scene = GameScene()
        return scene
    }()
    
    /// 场景类型枚举
    enum SceneType {
        case welcome
        case game
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if currentSceneType == .welcome {
                    SpriteView(scene: welcomeScene)
                        .ignoresSafeArea()
                        .onAppear {
                            welcomeScene.size = geometry.size
                            // 设置启动游戏回调
                            welcomeScene.onStartGame = {
                                withAnimation {
                                    currentSceneType = .game
                                }
                            }
                        }
                        .onChange(of: geometry.size) { oldSize, newSize in
                            welcomeScene.size = newSize
                        }
                } else {
                    SpriteView(scene: gameScene)
                        .ignoresSafeArea()
                        .onAppear {
                            gameScene.size = geometry.size
                            // 设置返回欢迎页面回调
                            gameScene.onBackToWelcome = {
                                withAnimation {
                                    currentSceneType = .welcome
                                }
                            }
                        }
                        .onChange(of: geometry.size) { oldSize, newSize in
                            gameScene.size = newSize
                        }
                }
            }
        }
    }
}
