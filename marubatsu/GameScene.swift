import SpriteKit

// MARK: - 游戏场景
/// 负责UI绘制、触摸事件处理和调用游戏逻辑
class GameScene: SKScene {
    
    // MARK: - 属性
    /// 游戏逻辑管理器
    private var gameLogic: GameLogic
    
    /// AI引擎
    private var aiEngine: AIEngine?
    
    /// 游戏模式
    var gameMode: GameMode = .twoPlayer {
        didSet {
            // 切换模式时更新AI引擎
            if gameMode == .vsAI || gameMode == .vsAIGod {
                aiEngine = AIEngine(aiPlayer: "×")
            } else {
                aiEngine = nil
            }
        }
    }
    
    /// 布局计算
    private var cellSize: CGFloat = 120
    private var offsetX: CGFloat = 0
    private var offsetY: CGFloat = 0
    
    /// UI 节点
    private var statusLabel: SKLabelNode?
    private var resultLabel: SKLabelNode?
    private var resetButton: SKLabelNode?
    private var modeButton: SKLabelNode?
    private var markNodes: [SKNode] = []
    
    /// AIゴッド模式：棋盘外标记节点（key: 位置标识，value: 节点）
    private var outsideMarkNodes: [String: SKNode] = [:]
    
    /// 长按检测（用于缩小棋盘）
    private var longPressTimer: Timer?
    private var longPressLocation: CGPoint?
    
    // MARK: - 初始化
    /// 无参数初始化器（使用默认尺寸）
    override init() {
        self.gameLogic = GameLogic()
        super.init()
    }
    
    /// 指定尺寸初始化器
    override init(size: CGSize) {
        self.gameLogic = GameLogic()
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.gameLogic = GameLogic()
        super.init(coder: aDecoder)
    }
    
    // MARK: - 场景生命周期
    override func didMove(to view: SKView) {
        // 设置渐变背景
        setupBackground()
        calculateLayout()
        setupGame()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        // 屏幕尺寸改变时重新计算布局
        calculateLayout()
        if children.count > 0 {
            setupGame()
        }
    }
    
    // MARK: - 背景设置
    /// 设置背景
    private func setupBackground() {
        backgroundColor = UIColor.systemBackground
    }
    
    // MARK: - 布局计算
    /// 计算响应式布局
    private func calculateLayout() {
        // 上下留出更多空白，避免被摄像头和状态栏遮挡
        let topPadding: CGFloat = 120  // 顶部留出120点空白（状态栏+安全区域）
        let bottomPadding: CGFloat = 100  // 底部留出100点空白（安全区域）
        
        // 根据屏幕尺寸计算合适的cellSize
        // 使用更合理的比例，确保棋盘不会太大或太小
        let availableWidth = size.width * 0.88  // 使用88%的宽度，留出更多边距
        let availableHeight = size.height - topPadding - bottomPadding  // 减去上下空白
        
        let widthBasedSize = availableWidth / CGFloat(GameConstants.boardSize)
        let heightBasedSize = availableHeight / CGFloat(GameConstants.boardSize)
        
        // 取较小值，但限制在最小和最大值之间
        cellSize = min(widthBasedSize, heightBasedSize)
        cellSize = max(GameConstants.minCellSize, min(cellSize, GameConstants.maxCellSize))
        
        // 计算棋盘偏移量（垂直居中，但考虑上下空白）
        let boardWidth = cellSize * CGFloat(GameConstants.boardSize)
        let boardHeight = cellSize * CGFloat(GameConstants.boardSize)
        offsetX = (size.width - boardWidth) / 2
        // 从顶部开始，加上顶部空白，然后居中剩余空间
        offsetY = topPadding + (availableHeight - boardHeight) / 2
    }
    
    // MARK: - 游戏设置
    /// 设置游戏UI
    private func setupGame() {
        removeAllChildren()
        markNodes.removeAll()
        outsideMarkNodes.removeAll()
        
        // 绘制棋盘
        let removedCells = gameMode == .vsAIGod ? getRemovedCells() : []
        UIFactory.drawBoard(
            in: self,
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY,
            removedCells: removedCells
        )
        
        // AIゴッド模式：绘制棋盘外区域提示
        if gameMode == .vsAIGod {
            drawOutsideAreas()
        }
        
        // 绘制模式按钮
        modeButton = UIFactory.createModeButton(
            in: self,
            gameMode: gameMode,
            sceneSize: size
        )
        
        // 更新状态标签
        updateStatusLabel()
        
        // AIゴッド模式：恢复棋盘外标记
        if gameMode == .vsAIGod {
            restoreOutsideMarks()
        }
    }
    
    /// 绘制棋盘外区域提示（AIゴッド模式）
    private func drawOutsideAreas() {
        // 这里可以添加一些视觉提示，比如虚线框等
        // 暂时不添加，保持简洁
    }
    
    /// 恢复棋盘外标记（AIゴッド模式）
    private func restoreOutsideMarks() {
        // 恢复所有棋盘外标记
        for (position, mark) in getOutsideMarksFromLogic() {
            drawOutsideMark(at: position, mark: mark)
        }
    }
    
    /// 从游戏逻辑获取所有棋盘外标记
    private func getOutsideMarksFromLogic() -> [String: String] {
        return gameLogic.getAllOutsideMarks()
    }
    
    // MARK: - 触摸事件处理
    /// 处理触摸结束事件
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // 检查是否点击模式按钮（任何状态下都可以切换）
        if let modeButton = modeButton {
            let buttonWidth: CGFloat = 180
            let buttonHeight: CGFloat = 50
            let buttonRect = CGRect(
                x: modeButton.position.x - buttonWidth / 2,
                y: modeButton.position.y - buttonHeight / 2,
                width: buttonWidth,
                height: buttonHeight
            )
            if buttonRect.contains(location) {
                toggleGameMode()
                return
            }
        }
        
        // 检查是否点击重置按钮（游戏结束时）
        if gameLogic.gameState != .playing {
            if let resetButton = resetButton {
                let buttonWidth: CGFloat = 200
                let buttonHeight: CGFloat = 50
                let buttonRect = CGRect(
                    x: resetButton.position.x - buttonWidth / 2,
                    y: resetButton.position.y - buttonHeight / 2,
                    width: buttonWidth,
                    height: buttonHeight
                )
                if buttonRect.contains(location) {
                    resetGame()
                    return
                }
            }
            // 游戏结束时，不允许其他操作
            return
        }
        
        // 游戏结束时不允许下棋
        if gameLogic.gameState != .playing {
            return
        }
        
        // AI模式下，如果当前是AI回合，不允许玩家点击
        if (gameMode == .vsAI || gameMode == .vsAIGod) && gameLogic.currentPlayer == aiEngine?.aiPlayer {
            return
        }
        
        // AIゴッド模式：检查是否点击棋盘外区域
        if gameMode == .vsAIGod {
            if let outsidePosition = checkOutsideAreaClick(location: location) {
                placeOutsideMark(at: outsidePosition)
                return
            }
        }
        
        // 检测点击的格子
        for row in 0..<GameConstants.boardSize {
            for col in 0..<GameConstants.boardSize {
                let index = row * GameConstants.boardSize + col
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize
                
                if location.x > x && location.x < x + cellSize &&
                   location.y > y && location.y < y + cellSize {
                    
                    // 检查格子是否被移除
                    if gameLogic.isCellRemoved(at: index) {
                        return  // 被移除的格子不能操作
                    }
                    
                    if gameLogic.isEmpty(at: index) {
                        makeMove(row: row, col: col, index: index)
                    }
                }
            }
        }
    }
    
    // MARK: - 游戏操作
    /// 切换游戏模式（三种模式循环：人間 -> AI -> AIゴッド -> 人間）
    private func toggleGameMode() {
        switch gameMode {
        case .twoPlayer:
            gameMode = .vsAI
        case .vsAI:
            gameMode = .vsAIGod
        case .vsAIGod:
            gameMode = .twoPlayer
        }
        modeButton?.removeFromParent()
        modeButton = UIFactory.createModeButton(
            in: self,
            gameMode: gameMode,
            sceneSize: size
        )
        resetGame()
    }
    
    /// 执行下棋
    /// - Parameters:
    ///   - row: 行索引
    ///   - col: 列索引
    ///   - index: 格子索引
    private func makeMove(row: Int, col: Int, index: Int) {
        // 调用游戏逻辑下棋
        guard gameLogic.makeMove(at: index) else {
            return
        }
        
        // 绘制标记
        let markNode = UIFactory.drawMark(
            in: self,
            row: row,
            col: col,
            mark: gameLogic.getMark(at: index),
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY
        )
        markNodes.append(markNode)
        
        // 检查游戏状态
        if gameMode == .vsAIGod {
            checkGameStateWithOutside()
        } else {
            switch gameLogic.gameState {
            case .won(let winner):
                showResult("\(winner) の勝ち!")
            case .draw:
                showResult("引き分け!")
            case .playing:
                // 更新状态标签
                updateStatusLabel()
                
                // AI模式下，如果轮到AI，延迟下棋
                if gameMode == .vsAI && gameLogic.gameState == .playing {
                    if let aiEngine = aiEngine, gameLogic.currentPlayer == aiEngine.aiPlayer {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self.makeAIMove()
                        }
                    }
                }
            }
        }
    }
    
    /// AI下棋
    private func makeAIMove() {
        guard gameLogic.gameState == .playing,
              let aiEngine = aiEngine,
              gameLogic.currentPlayer == aiEngine.aiPlayer else {
            return
        }
        
        // 获取当前棋盘状态
        let board = (0..<GameConstants.totalCells).map { gameLogic.getMark(at: $0) }
        
        // 获取AI最佳下棋位置
        if let bestMove = aiEngine.findBestMove(board: board) {
            let row = bestMove / GameConstants.boardSize
            let col = bestMove % GameConstants.boardSize
            makeMove(row: row, col: col, index: bestMove)
        }
    }
    
    // MARK: - AIゴッド模式
    /// AIゴッド模式：检查是否点击了棋盘外区域
    /// - Parameter location: 点击位置
    /// - Returns: 位置标识（如"top-1", "left-2"等），如果没有点击到则返回nil
    private func checkOutsideAreaClick(location: CGPoint) -> String? {
        let boardWidth = cellSize * CGFloat(GameConstants.boardSize)
        let boardHeight = cellSize * CGFloat(GameConstants.boardSize)
        let outsideAreaSize: CGFloat = cellSize * 0.6  // 棋盘外区域大小
        
        // 检查上方区域
        if location.y > offsetY + boardHeight && location.y < offsetY + boardHeight + outsideAreaSize {
            if location.x >= offsetX && location.x < offsetX + boardWidth {
                let col = Int((location.x - offsetX) / cellSize)
                return "top-\(col)"
            }
        }
        
        // 检查下方区域
        if location.y < offsetY && location.y > offsetY - outsideAreaSize {
            if location.x >= offsetX && location.x < offsetX + boardWidth {
                let col = Int((location.x - offsetX) / cellSize)
                return "bottom-\(col)"
            }
        }
        
        // 检查左侧区域
        if location.x < offsetX && location.x > offsetX - outsideAreaSize {
            if location.y >= offsetY && location.y < offsetY + boardHeight {
                let row = Int((location.y - offsetY) / cellSize)
                return "left-\(row)"
            }
        }
        
        // 检查右侧区域
        if location.x > offsetX + boardWidth && location.x < offsetX + boardWidth + outsideAreaSize {
            if location.y >= offsetY && location.y < offsetY + boardHeight {
                let row = Int((location.y - offsetY) / cellSize)
                return "right-\(row)"
            }
        }
        
        return nil
    }
    
    /// 在棋盘外放置标记（AIゴッド模式）
    /// - Parameter position: 位置标识
    private func placeOutsideMark(at position: String) {
        guard gameLogic.gameState == .playing else { return }
        
        // 调用游戏逻辑放置标记
        guard gameLogic.placeOutsideMark(at: position, mark: gameLogic.currentPlayer) else {
            return
        }
        
        // 绘制棋盘外标记
        drawOutsideMark(at: position, mark: gameLogic.getOutsideMark(at: position))
        
        // 检查游戏状态（包括棋盘外棋子的三连）
        checkGameStateWithOutside()
    }
    
    /// 绘制棋盘外标记
    /// - Parameters:
    ///   - position: 位置标识
    ///   - mark: 标记
    private func drawOutsideMark(at position: String, mark: String) {
        // 移除旧标记
        outsideMarkNodes[position]?.removeFromParent()
        
        let parts = position.split(separator: "-")
        guard parts.count == 2,
              let index = Int(parts[1]),
              index >= 0 && index < GameConstants.boardSize else {
            return
        }
        
        var centerX: CGFloat = 0
        var centerY: CGFloat = 0
        let outsideOffset: CGFloat = cellSize * 0.3
        
        switch String(parts[0]) {
        case "top":
            centerX = offsetX + CGFloat(index) * cellSize + cellSize / 2
            centerY = offsetY + cellSize * CGFloat(GameConstants.boardSize) + outsideOffset
        case "bottom":
            centerX = offsetX + CGFloat(index) * cellSize + cellSize / 2
            centerY = offsetY - outsideOffset
        case "left":
            centerX = offsetX - outsideOffset
            centerY = offsetY + CGFloat(index) * cellSize + cellSize / 2
        case "right":
            centerX = offsetX + cellSize * CGFloat(GameConstants.boardSize) + outsideOffset
            centerY = offsetY + CGFloat(index) * cellSize + cellSize / 2
        default:
            return
        }
        
        let radius = cellSize / 2 * (1 - GameConstants.markPaddingRatio) * 0.7  // 稍小一些
        let markNode = SKNode()
        markNode.position = CGPoint(x: centerX, y: centerY)
        markNode.zPosition = 5
        
        let markColor = UIColor.label
        
        if mark == "○" {
            let circle = SKShapeNode(circleOfRadius: radius)
            circle.strokeColor = markColor
            circle.fillColor = UIColor.clear
            circle.lineWidth = 5
            circle.lineCap = .round
            markNode.addChild(circle)
        } else {
            let path = UIBezierPath()
            let offset = radius * 0.9
            path.move(to: CGPoint(x: -offset, y: -offset))
            path.addLine(to: CGPoint(x: offset, y: offset))
            path.move(to: CGPoint(x: offset, y: -offset))
            path.addLine(to: CGPoint(x: -offset, y: offset))
            
            let cross = SKShapeNode(path: path.cgPath)
            cross.strokeColor = markColor
            cross.lineWidth = 5
            cross.lineCap = .round
            cross.lineJoin = .round
            markNode.addChild(cross)
        }
        
        markNode.alpha = 0
        markNode.setScale(0.4)
        addChild(markNode)
        outsideMarkNodes[position] = markNode
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        let group = SKAction.group([fadeIn, scaleUp])
        markNode.run(group)
    }
    
    /// 检查游戏状态（包括棋盘外棋子）
    private func checkGameStateWithOutside() {
        // 检查包括棋盘外棋子的获胜
        if let winner = gameLogic.checkWinnerWithOutside() {
            gameLogic.setGameState(.won(winner))
            showResult("\(winner) の勝ち!")
            return
        }
        
        // 检查普通棋盘状态
        switch gameLogic.gameState {
        case .won(let winner):
            showResult("\(winner) の勝ち!")
        case .draw:
            showResult("引き分け!")
        case .playing:
            updateStatusLabel()
            
            // AI模式下，如果轮到AI，延迟下棋
            if (gameMode == .vsAI || gameMode == .vsAIGod) && gameLogic.gameState == .playing {
                if let aiEngine = aiEngine, gameLogic.currentPlayer == aiEngine.aiPlayer {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if self.gameMode == .vsAIGod {
                            self.makeAIGodMove()
                        } else {
                            self.makeAIMove()
                        }
                    }
                }
            }
        }
    }
    
    /// 处理长按事件（缩小棋盘）
    private func handleLongPress(at location: CGPoint) {
        guard gameMode == .vsAIGod && gameLogic.gameState == .playing else { return }
        
        // 检查是否长按在格子上
        for row in 0..<GameConstants.boardSize {
            for col in 0..<GameConstants.boardSize {
                let index = row * GameConstants.boardSize + col
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize
                
                if location.x > x && location.x < x + cellSize &&
                   location.y > y && location.y < y + cellSize {
                    
                    // 只能移除空格子
                    if gameLogic.isEmpty(at: index) && !gameLogic.isCellRemoved(at: index) {
                        removeCell(at: index)
                        return
                    }
                }
            }
        }
    }
    
    /// 移除格子（缩小棋盘）
    private func removeCell(at index: Int) {
        guard gameLogic.removeCell(at: index) else { return }
        
        // 更新UI：隐藏被移除的格子
        updateBoardUI()
    }
    
    /// 获取被移除的格子集合
    private func getRemovedCells() -> Set<Int> {
        return gameLogic.getRemovedCells()
    }
    
    /// 更新棋盘UI（隐藏被移除的格子）
    private func updateBoardUI() {
        // 重新绘制棋盘，隐藏被移除的格子
        // 移除旧的棋盘节点（简化处理，重新绘制）
        setupGame()
    }
    
    /// AIゴッド模式：AI下棋（可以在棋盘外放置或缩小棋盘）
    private func makeAIGodMove() {
        guard gameLogic.gameState == .playing,
              let aiEngine = aiEngine,
              gameLogic.currentPlayer == aiEngine.aiPlayer else {
            return
        }
        
        // 简单策略：优先在棋盘内下棋，如果棋盘满了或需要防守，则在棋盘外放置
        let board = (0..<GameConstants.totalCells).map { gameLogic.getMark(at: $0) }
        
        // 先尝试在棋盘内下棋
        if let bestMove = aiEngine.findBestMove(board: board) {
            let row = bestMove / GameConstants.boardSize
            let col = bestMove % GameConstants.boardSize
            if !gameLogic.isCellRemoved(at: bestMove) && gameLogic.isEmpty(at: bestMove) {
                makeMove(row: row, col: col, index: bestMove)
                return
            }
        }
        
        // 如果棋盘内没有好位置，在棋盘外随机放置
        let outsidePositions = ["top-0", "top-1", "top-2", "bottom-0", "bottom-1", "bottom-2",
                                "left-0", "left-1", "left-2", "right-0", "right-1", "right-2"]
        let availableOutside = outsidePositions.filter { gameLogic.getOutsideMark(at: $0) == "" }
        if let randomPosition = availableOutside.randomElement() {
            placeOutsideMark(at: randomPosition)
        }
    }
    
    /// 重置游戏
    private func resetGame() {
        gameLogic.reset()
        setupGame()
        
        // AI模式下，如果AI先手，自动下第一步
        if (gameMode == .vsAI || gameMode == .vsAIGod),
           let aiEngine = aiEngine,
           gameLogic.currentPlayer == aiEngine.aiPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if self.gameMode == .vsAIGod {
                    self.makeAIGodMove()
                } else {
                    self.makeAIMove()
                }
            }
        }
    }
    
    // MARK: - UI 更新
    /// 显示游戏结果
    /// - Parameter message: 结果消息
    private func showResult(_ message: String) {
        // 移除状态标签和之前的结果
        statusLabel?.removeFromParent()
        resultLabel?.removeFromParent()
        resetButton?.removeFromParent()
        
        let boardBottom = offsetY + cellSize * CGFloat(GameConstants.boardSize)
        
        // 显示结果（在棋盘下方，简洁风格）
        resultLabel = UIFactory.createResultLabel(
            in: self,
            message: message,
            sceneSize: size,
            yPosition: boardBottom + 60
        )
        
        // 添加重置按钮（黑白简洁风格）
        resetButton = UIFactory.createResetButton(
            in: self,
            sceneSize: size,
            yPosition: boardBottom + 140
        )
    }
    
    /// 更新状态标签（显示当前玩家）
    private func updateStatusLabel() {
        statusLabel?.removeFromParent()
        
        var statusText = "\(gameLogic.currentPlayer) のターン"
        if gameMode == .vsAI,
           let aiEngine = aiEngine,
           gameLogic.currentPlayer == aiEngine.aiPlayer {
            statusText = "AIのターン..."
        }
        
        statusLabel = UIFactory.createStatusLabel(
            in: self,
            text: statusText,
            sceneSize: size,
            yPosition: offsetY - 70
        )
    }
}
