import SpriteKit
import Foundation

// MARK: - 标准渲染器（双人模式和AI模式）
class StandardRenderer: UIRenderer {
    let gameMode: GameMode
    
    init(gameMode: GameMode) {
        self.gameMode = gameMode
    }
    
    func renderBackground(in scene: GameScene) {
        // 背景渲染在GameScene中统一处理
        scene.setupBackground()
    }
    
    func renderBoard(in scene: GameScene) {
        // 棋盘渲染在GameScene中统一处理
        // 这里可以添加模式特定的棋盘样式
    }
    
    func renderMarks(in scene: GameScene) {
        // 标记渲染在GameScene中统一处理
    }
    
    func renderHeroCharacters(in scene: GameScene) {
        // 机器人角色渲染在GameScene中统一处理
        scene.setupHeroCharacters()
    }
    
    func renderButtons(in scene: GameScene) {
        // 按钮渲染在GameScene中统一处理
    }
}




