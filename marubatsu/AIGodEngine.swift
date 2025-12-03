import Foundation

// MARK: - AIゴッド引擎
/// 更强的AI引擎，用于AIゴッド模式，具有更高的胜率
class AIGodEngine: AIEngine {
    
    // MARK: - 初始化
    /// 初始化AIゴッド引擎
    /// - Parameter aiPlayer: AI使用的标记（"○" 或 "×"）
    override init(aiPlayer: String) {
        super.init(aiPlayer: aiPlayer)
    }
    
    // MARK: - AI 决策（增强版）
    /// 根据当前棋盘状态，寻找最佳下棋位置（增强版算法）
    /// - Parameter board: 当前棋盘状态
    /// - Returns: 最佳位置的索引，如果没有可用位置则返回 nil
    override func findBestMove(board: [String]) -> Int? {
        // 1. 优先：检查是否有可以获胜的位置（AI获胜）
        if let winningMove = findWinningMove(for: aiPlayer, in: board) {
            return winningMove
        }
        
        // 2. 防守：检查是否需要阻止对手获胜
        if let blockingMove = findWinningMove(for: humanPlayer, in: board) {
            return blockingMove
        }
        
        // 3. 增强策略：创建双重威胁（同时形成两个获胜机会）
        if let forkMove = findForkMove(board: board) {
            return forkMove
        }
        
        // 4. 增强策略：阻止对手创建双重威胁
        if let blockForkMove = findBlockForkMove(board: board) {
            return blockForkMove
        }
        
        // 5. 策略：优先选择中心位置（位置4）
        if board[4] == "" {
            return 4
        }
        
        // 6. 增强策略：优先选择对角位置（如果对手在角落）
        if let diagonalMove = findOptimalDiagonalMove(board: board) {
            return diagonalMove
        }
        
        // 7. 策略：优先选择角落位置
        let corners = [0, 2, 6, 8]
        let availableCorners = corners.filter { board[$0] == "" }
        if !availableCorners.isEmpty {
            return availableCorners.randomElement()
        }
        
        // 8. 兜底：选择任意可用位置
        let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        return availableMoves.randomElement()
    }
    
    // MARK: - 增强策略方法
    /// 查找可以创建双重威胁的位置（Fork）
    /// - Parameter board: 当前棋盘状态
    /// - Returns: 可以创建双重威胁的位置索引
    private func findForkMove(board: [String]) -> Int? {
        let emptyPositions = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        
        for position in emptyPositions {
            // 模拟在这个位置下棋
            var testBoard = board
            testBoard[position] = aiPlayer
            
            // 检查这个位置是否能在两条线上都形成威胁
            var threatCount = 0
            for line in winningLines {
                let marks = line.map { testBoard[$0] }
                let aiCount = marks.filter { $0 == aiPlayer }.count
                let emptyCount = marks.filter { $0 == "" }.count
                
                // 如果这一行有1个AI标记和2个空位，形成威胁
                if aiCount == 1 && emptyCount == 2 {
                    threatCount += 1
                }
            }
            
            // 如果能形成2个或更多威胁，返回这个位置
            if threatCount >= 2 {
                return position
            }
        }
        
        return nil
    }
    
    /// 查找可以阻止对手创建双重威胁的位置
    /// - Parameter board: 当前棋盘状态
    /// - Returns: 可以阻止对手双重威胁的位置索引
    private func findBlockForkMove(board: [String]) -> Int? {
        let emptyPositions = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        
        for position in emptyPositions {
            // 模拟对手在这个位置下棋
            var testBoard = board
            testBoard[position] = humanPlayer
            
            // 检查对手是否能在这个位置创建双重威胁
            var threatCount = 0
            for line in winningLines {
                let marks = line.map { testBoard[$0] }
                let humanCount = marks.filter { $0 == humanPlayer }.count
                let emptyCount = marks.filter { $0 == "" }.count
                
                // 如果这一行有1个人类标记和2个空位，形成威胁
                if humanCount == 1 && emptyCount == 2 {
                    threatCount += 1
                }
            }
            
            // 如果对手能形成2个或更多威胁，阻止它
            if threatCount >= 2 {
                return position
            }
        }
        
        return nil
    }
    
    /// 查找最优的对角位置
    /// - Parameter board: 当前棋盘状态
    /// - Returns: 最优的对角位置索引
    private func findOptimalDiagonalMove(board: [String]) -> Int? {
        // 检查对手是否在角落
        let corners = [0, 2, 6, 8]
        let humanCorners = corners.filter { board[$0] == humanPlayer }
        
        // 如果对手在角落，优先选择对角位置
        if !humanCorners.isEmpty {
            let oppositeCorners: [Int: Int] = [0: 8, 2: 6, 6: 2, 8: 0]
            for corner in humanCorners {
                if let opposite = oppositeCorners[corner], board[opposite] == "" {
                    return opposite
                }
            }
        }
        
        return nil
    }
}



