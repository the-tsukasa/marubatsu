import SpriteKit
import Foundation

// MARK: - AI对战模式处理器
class AIHandler: GameModeHandler {
    let gameMode: GameMode = .vsAI
    private var aiEngine: AIEngine?
    
    init() {
        self.aiEngine = AIEngine(aiPlayer: "×")
    }
    
    func setupUI(in scene: GameScene) {
        // AI模式使用标准UI设置
    }
    
    func handleMove(at index: Int, in scene: GameScene) {
        scene.makeMove(at: index)
        checkGameState(in: scene)
        
        // 如果轮到AI，随机延迟下棋（1-2秒）
        if scene.handlerGameLogic.gameState == .playing,
           let aiEngine = aiEngine,
           scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer {
            let randomDelay = Double.random(in: 1.0...2.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
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
        
        // 获取当前棋盘大小和状态
        let boardSize = scene.handlerGameLogic.getBoardSize()
        let totalCells = boardSize * boardSize
        let board = (0..<totalCells).map { scene.handlerGameLogic.getMark(at: $0) }
        
        // 获取AI最佳下棋位置
        if let bestMove = aiEngine.findBestMove(board: board) {
            handleMove(at: bestMove, in: scene)
        }
    }
    
    func updateStatus(in scene: GameScene) {
        scene.updateStatusLabel()
    }
    
    func canMakeMove(at index: Int, in scene: GameScene) -> Bool {
        return scene.handlerGameLogic.isEmpty(at: index) && 
               scene.handlerGameLogic.gameState == .playing &&
               scene.handlerGameLogic.currentPlayer != aiEngine?.aiPlayer
    }
    
    func resetGame(in scene: GameScene) {
        scene.handlerGameLogic.reset()
        scene.setupGame()
        
        // 如果AI先手，随机延迟后自动下第一步（1-2秒）
        if let aiEngine = aiEngine,
           scene.handlerGameLogic.currentPlayer == aiEngine.aiPlayer {
            let randomDelay = Double.random(in: 1.0...2.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
                self.handleAITurn(in: scene)
            }
        }
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

