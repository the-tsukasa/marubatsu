import SpriteKit
import Foundation

// MARK: - 触摸处理器协议
/// 定义不同游戏模式的触摸事件处理接口
protocol TouchHandler {
    /// 游戏模式
    var gameMode: GameMode { get }
    
    /// 处理触摸结束事件
    /// - Parameters:
    ///   - location: 触摸位置
    ///   - scene: 游戏场景
    /// - Returns: 是否已处理该触摸事件
    func handleTouch(at location: CGPoint, in scene: GameScene) -> Bool
}

// MARK: - 触摸处理器工厂
/// 根据游戏模式创建对应的触摸处理器
struct TouchHandlerFactory {
    static func create(for mode: GameMode) -> TouchHandler {
        switch mode {
        case .twoPlayer, .vsAI, .vsAIGod:
            return StandardTouchHandler(gameMode: mode)
        }
    }
}






