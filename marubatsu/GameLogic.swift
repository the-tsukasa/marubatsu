import Foundation

// MARK: - 游戏逻辑管理
/// 负责棋盘状态管理、胜负判断和回合切换
class GameLogic {
    
    // MARK: - 属性
    /// 棋盘状态（9个格子，空字符串表示空位）
    private(set) var board: [String]
    
    /// 当前玩家标记（"○" 或 "×"）
    private(set) var currentPlayer: String
    
    /// 游戏状态
    private(set) var gameState: GameState
    
    /// 获胜线组合（横、竖、斜）
    private let winningLines = [
        [0,1,2], [3,4,5], [6,7,8],  // 横
        [0,3,6], [1,4,7], [2,5,8],  // 竖
        [0,4,8], [2,4,6]             // 斜
    ]
    
    // MARK: - 初始化
    /// 初始化游戏逻辑
    init() {
        self.board = Array(repeating: "", count: GameConstants.totalCells)
        self.currentPlayer = "○"
        self.gameState = .playing
    }
    
    // MARK: - 游戏操作
    /// 在指定位置下棋
    /// - Parameters:
    ///   - index: 格子索引（0-8）
    /// - Returns: 是否成功下棋
    @discardableResult
    func makeMove(at index: Int) -> Bool {
        // 检查索引有效性
        guard index >= 0 && index < GameConstants.totalCells else {
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
        board = Array(repeating: "", count: GameConstants.totalCells)
        currentPlayer = "○"
        gameState = .playing
    }
    
    // MARK: - 辅助方法
    /// 获取指定位置的标记
    /// - Parameter index: 格子索引
    /// - Returns: 标记字符串，空位返回空字符串
    func getMark(at index: Int) -> String {
        guard index >= 0 && index < GameConstants.totalCells else {
            return ""
        }
        return board[index]
    }
    
    /// 检查指定位置是否为空
    /// - Parameter index: 格子索引
    /// - Returns: 如果位置为空返回 true
    func isEmpty(at index: Int) -> Bool {
        guard index >= 0 && index < GameConstants.totalCells else {
            return false
        }
        return board[index] == ""
    }
    
    /// 获取所有空位索引
    /// - Returns: 空位索引数组
    func getEmptyPositions() -> [Int] {
        return board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
    }
}



