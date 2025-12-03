import Foundation

// MARK: - AI 引擎
/// 负责AI智能下棋算法
class AIEngine {
    
    // MARK: - 属性
    /// AI玩家标记
    let aiPlayer: String
    
    /// 人类玩家标记
    let humanPlayer: String
    
    /// 获胜线组合（横、竖、斜）
    internal let winningLines = [
        [0,1,2], [3,4,5], [6,7,8],  // 横
        [0,3,6], [1,4,7], [2,5,8],  // 竖
        [0,4,8], [2,4,6]             // 斜
    ]
    
    // MARK: - 初始化
    /// 初始化AI引擎
    /// - Parameter aiPlayer: AI使用的标记（"○" 或 "×"）
    init(aiPlayer: String) {
        self.aiPlayer = aiPlayer
        self.humanPlayer = (aiPlayer == "○") ? "×" : "○"
    }
    
    // MARK: - AI 决策
    /// 根据当前棋盘状态，寻找最佳下棋位置
    /// - Parameter board: 当前棋盘状态
    /// - Returns: 最佳位置的索引，如果没有可用位置则返回 nil
    func findBestMove(board: [String]) -> Int? {
        // 1. 优先：检查是否有可以获胜的位置（AI获胜）
        if let winningMove = findWinningMove(for: aiPlayer, in: board) {
            return winningMove
        }
        
        // 2. 防守：检查是否需要阻止对手获胜
        if let blockingMove = findWinningMove(for: humanPlayer, in: board) {
            return blockingMove
        }
        
        // 3. 策略：优先选择中心位置（位置4）
        if board[4] == "" {
            return 4
        }
        
        // 4. 策略：优先选择角落位置
        let corners = [0, 2, 6, 8]
        let availableCorners = corners.filter { board[$0] == "" }
        if !availableCorners.isEmpty {
            return availableCorners.randomElement()
        }
        
        // 5. 兜底：选择任意可用位置
        let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        return availableMoves.randomElement()
    }
    
    // MARK: - 辅助方法
    /// 查找可以获胜的位置
    /// - Parameters:
    ///   - player: 玩家标记
    ///   - board: 当前棋盘状态
    /// - Returns: 可以获胜的位置索引，如果没有则返回 nil
    internal func findWinningMove(for player: String, in board: [String]) -> Int? {
        for line in winningLines {
            let marks = line.map { board[$0] }
            let playerCount = marks.filter { $0 == player }.count
            let emptyCount = marks.filter { $0 == "" }.count
            
            // 如果这一行已经有2个该玩家的标记，且有一个空位，返回空位
            if playerCount == 2 && emptyCount == 1 {
                return line.first { board[$0] == "" }
            }
        }
        
        return nil
    }
}



