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
        // 检查棋盘是否为空
        guard !board.isEmpty else { return nil }
        
        // 计算棋盘大小
        let boardSize = Int(sqrt(Double(board.count)))
        guard boardSize > 0 && boardSize * boardSize == board.count else {
            // 如果无法计算有效的棋盘大小，使用兜底策略
            let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
            return availableMoves.randomElement()
        }
        
        // 1. 优先：检查是否有可以获胜的位置（AI获胜）
        if let winningMove = findWinningMove(for: aiPlayer, in: board, boardSize: boardSize) {
            return winningMove
        }
        
        // 2. 防守：检查是否需要阻止对手获胜
        if let blockingMove = findWinningMove(for: humanPlayer, in: board, boardSize: boardSize) {
            return blockingMove
        }
        
        // 3. 增强策略：创建双重威胁（同时形成两个获胜机会）
        if let forkMove = findForkMove(board: board, boardSize: boardSize) {
            return forkMove
        }
        
        // 4. 增强策略：阻止对手创建双重威胁
        if let blockForkMove = findBlockForkMove(board: board, boardSize: boardSize) {
            return blockForkMove
        }
        
        // 5. 策略：优先选择中心位置（动态计算）
        let centerRow = boardSize / 2
        let centerCol = boardSize / 2
        let centerIndex = centerRow * boardSize + centerCol
        if centerIndex < board.count && board[centerIndex] == "" {
            return centerIndex
        }
        
        // 6. 增强策略：优先选择对角位置（如果对手在角落）
        if let diagonalMove = findOptimalDiagonalMove(board: board, boardSize: boardSize) {
            return diagonalMove
        }
        
        // 7. 策略：优先选择角落位置（动态计算）
        let corners = [
            0,                                    // 左上
            boardSize - 1,                        // 右上
            (boardSize - 1) * boardSize,          // 左下
            (boardSize - 1) * boardSize + (boardSize - 1)  // 右下
        ]
        let availableCorners = corners.filter { 
            $0 < board.count && board[$0] == "" 
        }
        if !availableCorners.isEmpty {
            return availableCorners.randomElement()
        }
        
        // 8. 兜底：选择任意可用位置
        let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        return availableMoves.randomElement()
    }
    
    // MARK: - 增强策略方法
    /// 查找可以创建双重威胁的位置（Fork）
    /// - Parameters:
    ///   - board: 当前棋盘状态
    ///   - boardSize: 棋盘大小
    /// - Returns: 可以创建双重威胁的位置索引
    private func findForkMove(board: [String], boardSize: Int) -> Int? {
        let emptyPositions = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        let winningLines = getWinningLines(for: boardSize)
        
        for position in emptyPositions {
            // 模拟在这个位置下棋
            var testBoard = board
            testBoard[position] = aiPlayer
            
            // 检查这个位置是否能在两条线上都形成威胁
            var threatCount = 0
            for line in winningLines {
                // 检查索引是否有效
                guard line.allSatisfy({ $0 >= 0 && $0 < testBoard.count }) else {
                    continue
                }
                
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
    /// - Parameters:
    ///   - board: 当前棋盘状态
    ///   - boardSize: 棋盘大小
    /// - Returns: 可以阻止对手双重威胁的位置索引
    private func findBlockForkMove(board: [String], boardSize: Int) -> Int? {
        let emptyPositions = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        let winningLines = getWinningLines(for: boardSize)
        
        for position in emptyPositions {
            // 模拟对手在这个位置下棋
            var testBoard = board
            testBoard[position] = humanPlayer
            
            // 检查对手是否能在这个位置创建双重威胁
            var threatCount = 0
            for line in winningLines {
                // 检查索引是否有效
                guard line.allSatisfy({ $0 >= 0 && $0 < testBoard.count }) else {
                    continue
                }
                
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
    /// - Parameters:
    ///   - board: 当前棋盘状态
    ///   - boardSize: 棋盘大小
    /// - Returns: 最优的对角位置索引
    private func findOptimalDiagonalMove(board: [String], boardSize: Int) -> Int? {
        // 只对3x3棋盘使用此策略（因为对角位置的概念主要适用于3x3）
        guard boardSize == 3 else { return nil }
        
        // 检查对手是否在角落
        let corners = [0, 2, 6, 8]
        let humanCorners = corners.filter { 
            $0 < board.count && board[$0] == humanPlayer 
        }
        
        // 如果对手在角落，优先选择对角位置
        if !humanCorners.isEmpty {
            let oppositeCorners: [Int: Int] = [0: 8, 2: 6, 6: 2, 8: 0]
            for corner in humanCorners {
                if let opposite = oppositeCorners[corner], 
                   opposite < board.count && board[opposite] == "" {
                    return opposite
                }
            }
        }
        
        return nil
    }
}






