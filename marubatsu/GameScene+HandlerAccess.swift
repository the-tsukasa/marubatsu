import SpriteKit

// MARK: - GameScene Handler Access Extension
/// 为Handler提供必要的访问接口
extension GameScene {
    /// 游戏逻辑（供Handler访问）
    var handlerGameLogic: GameLogic {
        return gameLogic
    }
    
    /// 布局信息（供Handler访问）
    var handlerCellSize: CGFloat {
        return cellSize
    }
    
    var handlerOffsetX: CGFloat {
        return offsetX
    }
    
    var handlerOffsetY: CGFloat {
        return offsetY
    }
    
    /// 标记节点列表（供Handler访问）
    var handlerMarkNodes: [SKNode] {
        get { return markNodes }
        set { markNodes = newValue }
    }
    
    /// 执行下棋（供Handler调用）
    /// - Parameter index: 格子索引
    func makeMove(at index: Int) {
        let boardSize = gameLogic.getBoardSize()
        let row = index / boardSize
        let col = index % boardSize
        makeMove(row: row, col: col, index: index)
    }
    
    // setupGame, getCurrentBoardSize, showResult, updateStatusLabel 已在GameScene中改为internal，可以直接访问
    
    /// 取消长按定时器（供Handler调用）
    func cancelLongPressTimer() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressLocation = nil
    }
    
    // currentHandler已在GameScene中定义，可以直接访问
    
    // hasScaled, makeAIGodMove, checkGameStateWithOutside 已在GameScene中改为internal，可以直接访问
}

