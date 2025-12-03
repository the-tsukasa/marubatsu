import SpriteKit
import Foundation

// MARK: - 双人对战模式处理器
class TwoPlayerHandler: GameModeHandler {
    let gameMode: GameMode = .twoPlayer
    
    func setupUI(in scene: GameScene) {
        // 双人模式使用标准UI设置
        // 具体实现在GameScene中统一处理
    }
    
    func handleMove(at index: Int, in scene: GameScene) {
        scene.makeMove(at: index)
        checkGameState(in: scene)
    }
    
    func handleAITurn(in scene: GameScene) {
        // 双人模式不需要AI
    }
    
    func updateStatus(in scene: GameScene) {
        scene.updateStatusLabel()
    }
    
    func canMakeMove(at index: Int, in scene: GameScene) -> Bool {
        return scene.handlerGameLogic.isEmpty(at: index) && 
               scene.handlerGameLogic.gameState == .playing
    }
    
    func resetGame(in scene: GameScene) {
        scene.handlerGameLogic.reset()
        scene.setupGame()
    }
    
    func checkGameState(in scene: GameScene) {
        switch scene.handlerGameLogic.gameState {
        case .won(let winner):
            scene.showResult("\(winner) の勝ち!")
        case .draw:
            scene.showResult("引き分け!")
        case .playing:
            updateStatus(in: scene)
        }
    }
}

