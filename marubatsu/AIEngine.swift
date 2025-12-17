import Foundation

// MARK: - AI 引擎
/// 负责AI智能下棋算法
class AIEngine {
    
    // MARK: - 属性
    /// AI玩家标记
    let aiPlayer: String
    
    /// 人类玩家标记
    let humanPlayer: String
    
    /// 获胜线组合（横、竖、斜）- 动态生成，支持不同棋盘大小
    internal func getWinningLines(for boardSize: Int) -> [[Int]] {
        var lines: [[Int]] = []
        
        // 横线
        for row in 0..<boardSize {
            for col in 0...(boardSize - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append(row * boardSize + col + i)
                }
                lines.append(line)
            }
        }
        
        // 竖线
        for col in 0..<boardSize {
            for row in 0...(boardSize - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * boardSize + col)
                }
                lines.append(line)
            }
        }
        
        // 主对角线（左上到右下）
        for row in 0...(boardSize - 3) {
            for col in 0...(boardSize - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * boardSize + col + i)
                }
                lines.append(line)
            }
        }
        
        // 副对角线（右上到左下）
        for row in 0...(boardSize - 3) {
            for col in 2..<boardSize {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * boardSize + col - i)
                }
                lines.append(line)
            }
        }
        
        return lines
    }
    
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
        
        // 3. 策略：优先选择中心位置（动态计算）
        let centerRow = boardSize / 2
        let centerCol = boardSize / 2
        let centerIndex = centerRow * boardSize + centerCol
        if centerIndex < board.count && board[centerIndex] == "" {
            return centerIndex
        }
        
        // 4. 策略：优先选择角落位置（动态计算）
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
        
        // 5. 兜底：选择任意可用位置
        let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
        return availableMoves.randomElement()
    }
    
    // MARK: - 辅助方法
    /// 查找可以获胜的位置
    /// - Parameters:
    ///   - player: 玩家标记
    ///   - board: 当前棋盘状态
    ///   - boardSize: 棋盘大小
    /// - Returns: 可以获胜的位置索引，如果没有则返回 nil
    internal func findWinningMove(for player: String, in board: [String], boardSize: Int) -> Int? {
        let winningLines = getWinningLines(for: boardSize)
        
        for line in winningLines {
            // 检查索引是否有效
            guard line.allSatisfy({ $0 >= 0 && $0 < board.count }) else {
                continue
            }
            
            let marks = line.map { board[$0] }
            let playerCount = marks.filter { $0 == player }.count
            let emptyCount = marks.filter { $0 == "" }.count
            
            // 如果这一行已经有2个该玩家的标记，且有一个空位，返回空位
            if playerCount == 2 && emptyCount == 1 {
                return line.first { 
                    $0 < board.count && board[$0] == "" 
                }
            }
        }
        
        return nil
    }
}



