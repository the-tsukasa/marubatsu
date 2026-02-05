import SpriteKit
import Foundation

// MARK: - UI渲染器协议
/// 定义不同游戏模式的UI渲染接口
protocol UIRenderer {
    /// 游戏模式
    var gameMode: GameMode { get }
    
    /// 渲染背景
    /// - Parameter scene: 游戏场景
    func renderBackground(in scene: GameScene)
    
    /// 渲染棋盘
    /// - Parameter scene: 游戏场景
    func renderBoard(in scene: GameScene)
    
    /// 渲染所有标记
    /// - Parameter scene: 游戏场景
    func renderMarks(in scene: GameScene)
    
    /// 渲染机器人角色
    /// - Parameter scene: 游戏场景
    func renderHeroCharacters(in scene: GameScene)
    
    /// 渲染按钮
    /// - Parameter scene: 游戏场景
    func renderButtons(in scene: GameScene)
}

// MARK: - UI渲染器工厂
/// 根据游戏模式创建对应的渲染器
struct UIRendererFactory {
    static func create(for mode: GameMode) -> UIRenderer {
        switch mode {
        case .twoPlayer:
            return StandardRenderer(gameMode: .twoPlayer)
        case .vsAI:
            return StandardRenderer(gameMode: .vsAI)
        case .vsAIGod:
            return StandardRenderer(gameMode: .vsAIGod)
        }
    }
}






