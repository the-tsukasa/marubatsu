import SpriteKit
import Foundation

// MARK: - AIゴッド模式处理器
class AIGodHandler: GameModeHandler {
    let gameMode: GameMode = .vsAIGod
    private var aiEngine: AIGodEngine?
    
    init() {
        self.aiEngine = AIGodEngine(aiPlayer: "×")
    }
    
    func setupUI(in scene: GameScene) {
        // AIゴッド模式使用特殊UI设置
        // 具体实现在GameScene中统一处理
    }
    
    func handleMove(at index: Int, in scene: GameScene) {
        scene.makeMove(at: index)
        checkGameState(in: scene)
        
        // 如果轮到AI，快速下棋（AIゴッド模式出手非常快）
        if scene.handlerGameLogic.gameState == .playing,
           let aiEngine = aiEngine,
           scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self.handleAITurn(in: scene)
            }
        }
    }
    
    func handleAITurn(in scene: GameScene) {
        guard scene.handlerGameLogic.gameState == .playing,
              let aiEngine = aiEngine,
              scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer else {
            return
        }

        let boardSize = scene.handlerGameLogic.getBoardSize()
        let totalCells = boardSize * boardSize
        let board = (0..<totalCells).map { scene.handlerGameLogic.getMark(at: $0) }

        if let bestMove = aiEngine.findBestMove(board: board) {
            handleMove(at: bestMove, in: scene)
        }
    }
    
    func updateStatus(in scene: GameScene) {
        scene.updateStatusLabel()
    }
    
    func canMakeMove(at index: Int, in scene: GameScene) -> Bool {
        // AIゴッド模式：检查是否在玩家回合且位置有效（与其他模式一致）
        guard scene.handlerGameLogic.gameState == .playing else { return false }
        
        // 检查是否是玩家回合
        if let aiEngine = aiEngine,
           scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer {
            return false
        }
        
        // 检查位置是否为空
        return scene.handlerGameLogic.isEmpty(at: index)
    }
    
    func resetGame(in scene: GameScene) {
        scene.handlerGameLogic.reset()
        // AIゴッド模式：设置AI先手（"×"）
        if let aiEngine = aiEngine {
            scene.handlerGameLogic.setCurrentPlayer(aiEngine.aiPlayer)
        }
        scene.setupGame()
        
        // AI先手，自动下第一步（快速执行，几乎无延迟）
        if let aiEngine = aiEngine,
           scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.handleAITurn(in: scene)
            }
        }
    }
    
    func checkGameState(in scene: GameScene) {
        // 使用标准的游戏状态检查（与其他模式一致）
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
