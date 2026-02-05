import Foundation

// MARK: - 游戏逻辑管理
/// 负责棋盘状态管理、胜负判断和回合切换
class GameLogic {
    
    // MARK: - 属性
    /// 棋盘状态（空字符串表示空位）
    private(set) var board: [String]
    
    /// 当前棋盘大小（AIゴッド模式支持3x3到6x6）
    private(set) var boardSize: Int
    
    /// 当前玩家标记（"○" 或 "×"）
    private(set) var currentPlayer: String
    
    /// 游戏状态
    private(set) var gameState: GameState
    
    /// 获胜线组合（横、竖、斜）- 动态生成
    private var winningLines: [[Int]] {
        return generateWinningLines(for: boardSize)
    }
    
    // MARK: - 初始化
    /// 初始化游戏逻辑
    /// - Parameter boardSize: 棋盘大小（默认3x3）
    init(boardSize: Int = GameConstants.boardSize) {
        self.boardSize = boardSize
        let totalCells = self.boardSize * self.boardSize
        self.board = Array(repeating: "", count: totalCells)
        self.currentPlayer = "○"
        self.gameState = .playing
    }
    
    /// 生成获胜线组合
    /// - Parameter size: 棋盘大小
    /// - Returns: 获胜线数组
    private func generateWinningLines(for size: Int) -> [[Int]] {
        var lines: [[Int]] = []
        
        // 横线
        for row in 0..<size {
            for col in 0...(size - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append(row * size + col + i)
                }
                lines.append(line)
            }
        }
        
        // 竖线
        for col in 0..<size {
            for row in 0...(size - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * size + col)
                }
                lines.append(line)
            }
        }
        
        // 主对角线（左上到右下）
        for row in 0...(size - 3) {
            for col in 0...(size - 3) {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * size + col + i)
                }
                lines.append(line)
            }
        }
        
        // 副对角线（右上到左下）
        for row in 0...(size - 3) {
            for col in 2..<size {
                var line: [Int] = []
                for i in 0..<3 {
                    line.append((row + i) * size + col - i)
                }
                lines.append(line)
            }
        }
        
        return lines
    }
    
    // MARK: - 游戏操作
    /// 在指定位置下棋
    /// - Parameters:
    ///   - index: 格子索引
    /// - Returns: 是否成功下棋
    @discardableResult
    func makeMove(at index: Int) -> Bool {
        // 检查索引有效性
        let totalCells = boardSize * boardSize
        guard index >= 0 && index < totalCells else {
            return false
        }

        
        // 检查位置是否为空
        guard board[index] == "" else {
            return false
        }
        
        // 检查游戏是否还在进行中
        guard gameState == .playing else {
            return false
        }
        
        // 下棋
        board[index] = currentPlayer
        
        // 检查游戏状态
        updateGameState()
        
        // 如果游戏还在进行，切换玩家
        if gameState == .playing {
            switchPlayer()
        }
        
        return true
    }
    
    /// 切换当前玩家
    private func switchPlayer() {
        currentPlayer = (currentPlayer == "○") ? "×" : "○"
    }
    
    /// 更新游戏状态（检查胜负或平局）
    private func updateGameState() {
        // 检查是否有获胜者
        if let winner = checkWinner() {
            gameState = .won(winner)
            return
        }
        
        // 检查是否平局
        if checkDraw() {
            gameState = .draw
            return
        }
        
        // 游戏继续
        gameState = .playing
    }
    
    // MARK: - 胜负判断
    /// 检查是否有获胜者
    /// - Returns: 获胜玩家的标记，如果没有则返回 nil
    func checkWinner() -> String? {
        for line in winningLines {
            let a = line[0], b = line[1], c = line[2]
            if board[a] != "" && board[a] == board[b] && board[b] == board[c] {
                return board[a]
            }
        }
        return nil
    }
    
    /// 检查是否平局
    /// - Returns: 如果棋盘已满且没有获胜者，返回 true
    func checkDraw() -> Bool {
        return board.allSatisfy { $0 != "" } && checkWinner() == nil
    }
    
    // MARK: - 游戏重置
    /// 重置游戏到初始状态
    func reset() {
        let totalCells = boardSize * boardSize
        board = Array(repeating: "", count: totalCells)
        currentPlayer = "○"
        gameState = .playing
    }
    
    /// 设置游戏状态（用于AIゴッド模式的外部调用）
    /// - Parameter state: 新的游戏状态
    func setGameState(_ state: GameState) {
        gameState = state
    }
    
    /// 设置当前玩家（用于AIゴッド模式的外部调用）
    /// - Parameter player: 新的当前玩家标记（"○" 或 "×"）
    func setCurrentPlayer(_ player: String) {
        currentPlayer = player
    }
    
    
    // MARK: - 辅助方法
    /// 获取指定位置的标记
    /// - Parameter index: 格子索引
    /// - Returns: 标记字符串，空位返回空字符串
    func getMark(at index: Int) -> String {
        let totalCells = boardSize * boardSize
        guard index >= 0 && index < totalCells else {
            return ""
        }
        return board[index]
    }
    
    /// 检查指定位置是否为空
    /// - Parameter index: 格子索引
    /// - Returns: 如果位置为空返回 true
    func isEmpty(at index: Int) -> Bool {
        let totalCells = boardSize * boardSize
        guard index >= 0 && index < totalCells else {
            return false
        }
        return board[index] == ""
    }
    
    /// 获取所有空位索引
    /// - Returns: 空位索引数组
    func getEmptyPositions() -> [Int] {
        return board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
    }
    
    /// 获取当前棋盘大小
    /// - Returns: 当前棋盘大小
    func getBoardSize() -> Int {
        return boardSize
    }
    
    /// 获取所有可能的获胜线（AIゴッド模式使用）
    /// - Returns: 获胜线数组
    func getWinningLines() -> [[Int]] {
        return winningLines
    }
}
