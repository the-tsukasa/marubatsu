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
    
    /// AIゴッド模式：棋盘外放置的棋子（key: 位置标识，value: 玩家标记）
    private(set) var outsideMarks: [String: String] = [:]
    
    /// AIゴッド模式：被移除的格子索引（缩小棋盘）
    private(set) var removedCells: Set<Int> = []
    
    /// 获胜线组合（横、竖、斜）- 动态生成
    private var winningLines: [[Int]] {
        return generateWinningLines(for: boardSize)
    }
    
    // MARK: - 初始化
    /// 初始化游戏逻辑
    /// - Parameter boardSize: 棋盘大小（默认3x3）
    init(boardSize: Int = GameConstants.boardSize) {
        self.boardSize = min(max(boardSize, GameConstants.minBoardSize), GameConstants.maxBoardSize)
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
        outsideMarks = [:]
        removedCells = []
    }
    
    /// 改变棋盘大小（AIゴッド模式）
    /// - Parameter newSize: 新的棋盘大小（3-6）
    /// - Returns: 是否成功改变
    @discardableResult
    func changeBoardSize(to newSize: Int) -> Bool {
        let validSize = min(max(newSize, GameConstants.minBoardSize), GameConstants.maxBoardSize)
        guard validSize != boardSize else { return false }
        
        // 保存当前棋盘状态（只保留有效位置）
        let oldSize = boardSize
        let oldBoard = board
        boardSize = validSize
        let newTotalCells = boardSize * boardSize
        
        // 重新初始化棋盘
        board = Array(repeating: "", count: newTotalCells)
        
        // 迁移旧棋盘数据（如果新棋盘更大，保留旧数据）
        if validSize > oldSize {
            for row in 0..<oldSize {
                for col in 0..<oldSize {
                    let oldIndex = row * oldSize + col
                    let newIndex = row * boardSize + col
                    if newIndex < newTotalCells {
                        board[newIndex] = oldBoard[oldIndex]
                    }
                }
            }
        } else {
            // 新棋盘更小，只保留能放下的部分
            for row in 0..<validSize {
                for col in 0..<validSize {
                    let oldIndex = row * oldSize + col
                    let newIndex = row * boardSize + col
                    board[newIndex] = oldBoard[oldIndex]
                }
            }
        }
        
        // 清除无效的removedCells
        removedCells = removedCells.filter { $0 < newTotalCells }
        
        // 重新检查游戏状态
        updateGameState()
        
        return true
    }
    
    /// 设置游戏状态（用于AIゴッド模式的外部调用）
    /// - Parameter state: 新的游戏状态
    func setGameState(_ state: GameState) {
        gameState = state
    }
    
    // MARK: - AIゴッド模式特殊方法
    /// 在棋盘外放置棋子（AIゴッド模式）
    /// - Parameters:
    ///   - position: 位置标识（例如："top-1", "left-2"等）
    ///   - mark: 玩家标记
    /// - Returns: 是否成功放置
    @discardableResult
    func placeOutsideMark(at position: String, mark: String) -> Bool {
        guard gameState == .playing else { return false }
        guard outsideMarks[position] == nil else { return false }
        outsideMarks[position] = mark
        updateGameState()
        if gameState == .playing {
            switchPlayer()
        }
        return true
    }
    
    /// 移除棋盘格子（缩小棋盘，AIゴッド模式）
    /// - Parameter index: 格子索引
    /// - Returns: 是否成功移除
    @discardableResult
    func removeCell(at index: Int) -> Bool {
        let totalCells = boardSize * boardSize
        guard index >= 0 && index < totalCells else { return false }
        guard !removedCells.contains(index) else { return false }
        guard board[index] == "" else { return false } // 只能移除空格子
        removedCells.insert(index)
        return true
    }
    
    /// 获取棋盘外标记
    /// - Parameter position: 位置标识
    /// - Returns: 标记字符串，如果没有则返回空字符串
    func getOutsideMark(at position: String) -> String {
        return outsideMarks[position] ?? ""
    }
    
    /// 检查格子是否被移除
    /// - Parameter index: 格子索引
    /// - Returns: 如果格子被移除返回 true
    func isCellRemoved(at index: Int) -> Bool {
        return removedCells.contains(index)
    }
    
    /// AIゴッド模式：检查是否有获胜者（包括棋盘外棋子）
    /// - Returns: 获胜玩家的标记，如果没有则返回 nil
    func checkWinnerWithOutside() -> String? {
        // 先检查普通棋盘
        if let winner = checkWinner() {
            return winner
        }
        
        // 检查包含棋盘外棋子的三连
        // 棋盘外区域位置：
        // - top-0, top-1, ..., top-(boardSize-1): 对应棋盘各列的上方
        // - bottom-0, bottom-1, ..., bottom-(boardSize-1): 对应棋盘各列的下方
        // - left-0, left-1, ..., left-(boardSize-1): 对应棋盘各行的左侧
        // - right-0, right-1, ..., right-(boardSize-1): 对应棋盘各行的右侧
        
        // 检查横线（可能包含上方或下方棋盘外棋子）
        for row in 0..<boardSize {
            let col0 = row * GameConstants.boardSize
            let col1 = row * GameConstants.boardSize + 1
            let col2 = row * GameConstants.boardSize + 2
            
            let mark0 = board[col0]
            let mark1 = board[col1]
            let mark2 = board[col2]
            
            // 标准横线
            if mark0 != "" && mark0 == mark1 && mark1 == mark2 {
                return mark0
            }
            
            // 上方棋盘外 + 棋盘内两个
            let top0 = outsideMarks["top-0"] ?? ""
            let top1 = outsideMarks["top-1"] ?? ""
            let top2 = outsideMarks["top-2"] ?? ""
            
            if top0 != "" && top0 == mark1 && mark1 == mark2 { return top0 }
            if mark0 != "" && mark0 == top1 && top1 == mark2 { return mark0 }
            if mark0 != "" && mark0 == mark1 && mark1 == top2 { return mark0 }
            
            // 下方棋盘外 + 棋盘内两个
            let bottom0 = outsideMarks["bottom-0"] ?? ""
            let bottom1 = outsideMarks["bottom-1"] ?? ""
            let bottom2 = outsideMarks["bottom-2"] ?? ""
            
            if bottom0 != "" && bottom0 == mark1 && mark1 == mark2 { return bottom0 }
            if mark0 != "" && mark0 == bottom1 && bottom1 == mark2 { return mark0 }
            if mark0 != "" && mark0 == mark1 && mark1 == bottom2 { return mark0 }
        }
        
        // 检查竖线（可能包含左侧或右侧棋盘外棋子）
        for col in 0..<boardSize {
            let row0 = col
            let row1 = col + boardSize
            let row2 = col + boardSize * 2
            
            let mark0 = board[row0]
            let mark1 = board[row1]
            let mark2 = board[row2]
            
            // 标准竖线
            if mark0 != "" && mark0 == mark1 && mark1 == mark2 {
                return mark0
            }
            
            // 左侧棋盘外 + 棋盘内两个
            let left0 = outsideMarks["left-0"] ?? ""
            let left1 = outsideMarks["left-1"] ?? ""
            let left2 = outsideMarks["left-2"] ?? ""
            
            if left0 != "" && left0 == mark1 && mark1 == mark2 { return left0 }
            if mark0 != "" && mark0 == left1 && left1 == mark2 { return mark0 }
            if mark0 != "" && mark0 == mark1 && mark1 == left2 { return mark0 }
            
            // 右侧棋盘外 + 棋盘内两个
            let right0 = outsideMarks["right-0"] ?? ""
            let right1 = outsideMarks["right-1"] ?? ""
            let right2 = outsideMarks["right-2"] ?? ""
            
            if right0 != "" && right0 == mark1 && mark1 == mark2 { return right0 }
            if mark0 != "" && mark0 == right1 && right1 == mark2 { return mark0 }
            if mark0 != "" && mark0 == mark1 && mark1 == right2 { return mark0 }
        }
        
        // 检查斜线（对角线）
        // 主对角线：0, 4, 8
        let diag0 = board[0]
        let diag1 = board[4]
        let diag2 = board[8]
        if diag0 != "" && diag0 == diag1 && diag1 == diag2 { return diag0 }
        
        // 副对角线：2, 4, 6
        let diag20 = board[2]
        let diag21 = board[4]
        let diag22 = board[6]
        if diag20 != "" && diag20 == diag21 && diag21 == diag22 { return diag20 }
        
        return nil
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
    
    /// 获取所有棋盘外标记（AIゴッド模式）
    /// - Returns: 位置标识到标记的字典
    func getAllOutsideMarks() -> [String: String] {
        return outsideMarks
    }
    
    /// 获取被移除的格子集合（AIゴッド模式）
    /// - Returns: 被移除的格子索引集合
    func getRemovedCells() -> Set<Int> {
        return removedCells
    }
    
    /// 获取当前棋盘大小
    /// - Returns: 当前棋盘大小
    func getBoardSize() -> Int {
        return boardSize
    }
}



