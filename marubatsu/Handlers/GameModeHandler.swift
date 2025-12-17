import SpriteKit
import Foundation

// MARK: - 游戏模式处理器协议
/// 定义不同游戏模式的通用接口
protocol GameModeHandler {
    /// 游戏模式
    var gameMode: GameMode { get }
    
    /// 设置UI（背景、棋盘、按钮等）
    /// - Parameter scene: 游戏场景
    func setupUI(in scene: GameScene)
    
    /// 处理玩家下棋
    /// - Parameters:
    ///   - index: 格子索引
    ///   - scene: 游戏场景
    func handleMove(at index: Int, in scene: GameScene)
    
    /// 处理AI回合（如果需要）
    /// - Parameter scene: 游戏场景
    func handleAITurn(in scene: GameScene)
    
    /// 更新状态标签
    /// - Parameter scene: 游戏场景
    func updateStatus(in scene: GameScene)
    
    /// 检查是否可以在指定位置下棋
    /// - Parameters:
    ///   - index: 格子索引
    ///   - scene: 游戏场景
    /// - Returns: 是否可以下棋
    func canMakeMove(at index: Int, in scene: GameScene) -> Bool
    
    /// 重置游戏
    /// - Parameter scene: 游戏场景
    func resetGame(in scene: GameScene)
    
    /// 检查游戏状态并显示结果
    /// - Parameter scene: 游戏场景
    func checkGameState(in scene: GameScene)
}

// MARK: - 游戏模式处理器工厂
/// 根据游戏模式创建对应的处理器
struct GameModeHandlerFactory {
    static func create(for mode: GameMode) -> GameModeHandler {
        switch mode {
        case .twoPlayer:
            return TwoPlayerHandler()
        case .vsAI:
            return AIHandler()
        case .vsAIGod:
            return AIGodHandler()
        }
    }
}







