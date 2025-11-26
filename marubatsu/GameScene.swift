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
    private var backButton: SKLabelNode?
    private var markNodes: [SKNode] = []
    
    /// 返回欢迎页面的回调
    var onBackToWelcome: (() -> Void)?
    
    /// AIゴッド模式：棋盘外标记节点（key: 位置标识，value: 节点）
    private var outsideMarkNodes: [String: SKNode] = [:]
    
    /// 长按检测（用于缩小棋盘）
    private var longPressTimer: Timer?
    private var longPressLocation: CGPoint?
    
    /// 双击检测（AIゴッド模式：触发隐藏棋盘）
    private var lastTapTime: TimeInterval = 0
    private var lastTapLocation: CGPoint = .zero
    private let doubleTapTimeInterval: TimeInterval = 0.3  // 双击时间间隔（秒）
    private let doubleTapDistanceThreshold: CGFloat = 20  // 双击位置容差（点）
    
    /// AIゴッド模式：是否已触发隐藏棋盘（用于控制隐藏棋盘显示）
    private var hasScaled: Bool = false
    
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
        
        // 获取当前棋盘大小
        let currentBoardSize = getCurrentBoardSize()
        
        // 根据屏幕尺寸计算合适的cellSize
        // 使用更合理的比例，确保棋盘不会太大或太小
        let availableWidth = size.width * 0.88  // 使用88%的宽度，留出更多边距
        let availableHeight = size.height - topPadding - bottomPadding  // 减去上下空白
        
        let widthBasedSize = availableWidth / CGFloat(currentBoardSize)
        let heightBasedSize = availableHeight / CGFloat(currentBoardSize)
        
        // 取较小值，但限制在最小和最大值之间
        cellSize = min(widthBasedSize, heightBasedSize)
        cellSize = max(GameConstants.minCellSize, min(cellSize, GameConstants.maxCellSize))
        
        // 计算棋盘偏移量（垂直居中，但考虑上下空白）
        let boardWidth = cellSize * CGFloat(currentBoardSize)
        let boardHeight = cellSize * CGFloat(currentBoardSize)
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
        let currentBoardSize = getCurrentBoardSize()
        UIFactory.drawBoard(
            in: self,
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY,
            boardSize: currentBoardSize,
            removedCells: removedCells
        )
        
        // AIゴッド模式：只有缩放后才绘制隐藏棋盘区域
        if gameMode == .vsAIGod && hasScaled {
            drawOutsideAreas()
        }
        
        // 绘制返回按钮
        backButton = UIFactory.createBackButton(
            in: self,
            sceneSize: size
        )
        
        // 绘制模式按钮
        modeButton = UIFactory.createModeButton(
            in: self,
            gameMode: gameMode,
            sceneSize: size
        )
        
        // 更新状态标签
        updateStatusLabel()
        
        // AIゴッド模式：只有缩放后才恢复棋盘外标记
        if gameMode == .vsAIGod && hasScaled {
            restoreOutsideMarks()
        }
    }
    
    /// 获取隐藏棋盘区域大小（动态调整）
    private func getOutsideAreaSize() -> CGFloat {
        let boardSize = getCurrentBoardSize()
        // 棋盘越小，隐藏区域越大，充分利用空间
        let multiplier: CGFloat = boardSize == 3 ? 1.5 : (boardSize == 4 ? 1.2 : 1.0)
        return cellSize * multiplier
    }
    
    /// 绘制棋盘外区域提示（AIゴッド模式）- 隐藏棋盘
    private func drawOutsideAreas() {
        let boardSize = getCurrentBoardSize()
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let outsideAreaSize = getOutsideAreaSize()  // 使用动态大小
        
        // 虚线样式（增强视觉提示）
        let lineColor = UIColor.label.withAlphaComponent(0.4)  // 从0.25改为0.4，更明显
        let lineWidth: CGFloat = 2.0  // 从1.5改为2.0，更粗
        let backgroundColor = UIColor.systemBlue.withAlphaComponent(0.05)  // 淡蓝色背景提示
        
        // 绘制上方隐藏棋盘区域（虚线框）
        for col in 0..<boardSize {
            let x = offsetX + CGFloat(col) * cellSize
            let y = offsetY + boardHeight
            
            // 绘制背景提示
            let backgroundArea = SKShapeNode(rect: CGRect(
                x: x,
                y: y,
                width: cellSize,
                height: outsideAreaSize
            ))
            backgroundArea.fillColor = backgroundColor
            backgroundArea.strokeColor = UIColor.clear
            backgroundArea.zPosition = 0.3
            addChild(backgroundArea)
            
            // 绘制虚线框（使用多个小线段模拟虚线）
            drawDashedRect(
                x: x,
                y: y,
                width: cellSize,
                height: outsideAreaSize,
                color: lineColor,
                lineWidth: lineWidth
            )
        }
        
        // 绘制下方隐藏棋盘区域（虚线框）
        for col in 0..<boardSize {
            let x = offsetX + CGFloat(col) * cellSize
            let y = offsetY - outsideAreaSize
            
            // 绘制背景提示
            let backgroundArea = SKShapeNode(rect: CGRect(
                x: x,
                y: y,
                width: cellSize,
                height: outsideAreaSize
            ))
            backgroundArea.fillColor = backgroundColor
            backgroundArea.strokeColor = UIColor.clear
            backgroundArea.zPosition = 0.3
            addChild(backgroundArea)
            
            drawDashedRect(
                x: x,
                y: y,
                width: cellSize,
                height: outsideAreaSize,
                color: lineColor,
                lineWidth: lineWidth
            )
        }
        
        // 绘制左侧隐藏棋盘区域（虚线框）
        for row in 0..<boardSize {
            let x = offsetX - outsideAreaSize
            let y = offsetY + CGFloat(row) * cellSize
            
            // 绘制背景提示
            let backgroundArea = SKShapeNode(rect: CGRect(
                x: x,
                y: y,
                width: outsideAreaSize,
                height: cellSize
            ))
            backgroundArea.fillColor = backgroundColor
            backgroundArea.strokeColor = UIColor.clear
            backgroundArea.zPosition = 0.3
            addChild(backgroundArea)
            
            drawDashedRect(
                x: x,
                y: y,
                width: outsideAreaSize,
                height: cellSize,
                color: lineColor,
                lineWidth: lineWidth
            )
        }
        
        // 绘制右侧隐藏棋盘区域（虚线框）
        for row in 0..<boardSize {
            let x = offsetX + boardWidth
            let y = offsetY + CGFloat(row) * cellSize
            
            // 绘制背景提示
            let backgroundArea = SKShapeNode(rect: CGRect(
                x: x,
                y: y,
                width: outsideAreaSize,
                height: cellSize
            ))
            backgroundArea.fillColor = backgroundColor
            backgroundArea.strokeColor = UIColor.clear
            backgroundArea.zPosition = 0.3
            addChild(backgroundArea)
            
            drawDashedRect(
                x: x,
                y: y,
                width: outsideAreaSize,
                height: cellSize,
                color: lineColor,
                lineWidth: lineWidth
            )
        }
    }
    
    /// 绘制虚线矩形（使用多个小线段模拟虚线效果）
    private func drawDashedRect(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor, lineWidth: CGFloat) {
        let dashLength: CGFloat = 6
        let gapLength: CGFloat = 3
        
        // 绘制上边（从左到右）
        var currentX = x
        while currentX < x + width {
            let segmentLength = min(dashLength, x + width - currentX)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: currentX, y: y + height))
            path.addLine(to: CGPoint(x: currentX + segmentLength, y: y + height))

            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = color
            line.lineWidth = lineWidth
            line.zPosition = 0.5
            addChild(line)
            
            currentX += dashLength + gapLength
        }
        
        // 绘制下边（从左到右）
        currentX = x
        while currentX < x + width {
            let segmentLength = min(dashLength, x + width - currentX)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: currentX, y: y))
            path.addLine(to: CGPoint(x: currentX + segmentLength, y: y))

            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = color
            line.lineWidth = lineWidth
            line.zPosition = 0.5
            addChild(line)
            
            currentX += dashLength + gapLength
        }
        
        // 绘制左边（从下到上）
        var currentY = y
        while currentY < y + height {
            let segmentLength = min(dashLength, y + height - currentY)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: currentY))
            path.addLine(to: CGPoint(x: x, y: currentY + segmentLength))

            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = color
            line.lineWidth = lineWidth
            line.zPosition = 0.5
            addChild(line)
            
            currentY += dashLength + gapLength
        }
        
        // 绘制右边（从下到上）
        currentY = y
        while currentY < y + height {
            let segmentLength = min(dashLength, y + height - currentY)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x + width, y: currentY))
            path.addLine(to: CGPoint(x: x + width, y: currentY + segmentLength))

            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = color
            line.lineWidth = lineWidth
            line.zPosition = 0.5
            addChild(line)
            
            currentY += dashLength + gapLength
        }
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
    /// 处理触摸开始事件（用于长按检测和双击检测）
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // AIゴッド模式：检测长按以缩小棋盘
        if gameMode == .vsAIGod && gameLogic.gameState == .playing {
            longPressLocation = location
            longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                self?.handleLongPress(at: location)
            }
        }
        
        // AIゴッド模式：检测双击上下空白区域（触发隐藏棋盘）
        if gameMode == .vsAIGod && !hasScaled {
            // 只检测在上下空白区域的双击
            if checkIfInTopBottomBlankArea(location: location) {
                let currentTime = touch.timestamp
                let timeSinceLastTap = currentTime - lastTapTime
                let distanceFromLastTap = distanceBetween(location, lastTapLocation)
                
                // 检查是否是双击（时间间隔短且位置相近）
                if timeSinceLastTap < doubleTapTimeInterval && 
                   distanceFromLastTap < doubleTapDistanceThreshold {
                    // 触发隐藏棋盘
                    triggerHiddenBoard()
                    // 重置双击检测
                    lastTapTime = 0
                    lastTapLocation = .zero
                    return  // 双击触发后，不继续处理其他操作
                } else {
                    // 记录第一次点击（在空白区域）
                    lastTapTime = currentTime
                    lastTapLocation = location
                    return  // 在空白区域的单次点击，不处理为游戏操作
                }
            } else {
                // 不在空白区域，重置双击检测
                lastTapTime = 0
                lastTapLocation = .zero
            }
        }
    }
    
    /// 处理触摸结束事件
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 取消长按计时器
        longPressTimer?.invalidate()
        longPressTimer = nil
        longPressLocation = nil
        
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        // 检查是否点击返回按钮（任何状态下都可以返回）
        if let backButton = backButton {
            let buttonWidth: CGFloat = 100
            let buttonHeight: CGFloat = 50
            let buttonRect = CGRect(
                x: backButton.position.x - buttonWidth / 2,
                y: backButton.position.y - buttonHeight / 2,
                width: buttonWidth,
                height: buttonHeight
            )
            if buttonRect.contains(touchLocation) {
                onBackToWelcome?()
                return
            }
        }

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
            if buttonRect.contains(touchLocation) {
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
                if buttonRect.contains(touchLocation) {
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
        
        // AIゴッド模式：只有缩放后才允许在隐藏棋盘区域放置棋子
        if gameMode == .vsAIGod && hasScaled {
            if let outsidePosition = checkOutsideAreaClick(location: touchLocation) {
                placeOutsideMark(at: outsidePosition)
                return
            }
        }

        // 检测点击的格子
        let boardSize = getCurrentBoardSize()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let index = row * boardSize + col
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize

                if touchLocation.x > x && touchLocation.x < x + cellSize &&
                   touchLocation.y > y && touchLocation.y < y + cellSize {
                    
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
        // 切换模式时重置缩放标志
        hasScaled = false
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
    /// 获取当前棋盘大小
    private func getCurrentBoardSize() -> Int {
        return gameLogic.getBoardSize()
    }
    
    /// 计算两点之间的距离
    private func distanceBetween(_ point1: CGPoint, _ point2: CGPoint) -> CGFloat {
        let dx = point2.x - point1.x
        let dy = point2.y - point1.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// 检查点击是否在上下空白区域
    /// - Parameter location: 点击位置
    /// - Returns: 如果在上下空白区域返回 true
    private func checkIfInTopBottomBlankArea(location: CGPoint) -> Bool {
        let boardSize = getCurrentBoardSize()
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        
        // 检查是否在棋盘上方空白区域
        let topBlankArea = CGRect(
            x: offsetX,
            y: offsetY + boardHeight,
            width: boardWidth,
            height: size.height - (offsetY + boardHeight)
        )
        
        // 检查是否在棋盘下方空白区域
        let bottomBlankArea = CGRect(
            x: offsetX,
            y: 0,
            width: boardWidth,
            height: offsetY
        )
        
        return topBlankArea.contains(location) || bottomBlankArea.contains(location)
    }
    
    /// 触发隐藏棋盘（双击上下空白区域后调用）
    private func triggerHiddenBoard() {
        guard gameMode == .vsAIGod && !hasScaled && gameLogic.gameState == .playing else { return }
        
        // 将棋盘变为6x6（最大尺寸）
        hasScaled = true
        changeBoardSize(to: GameConstants.maxBoardSize)
    }
    
    /// 改变棋盘大小
    /// - Parameter newSize: 新的棋盘大小
    private func changeBoardSize(to newSize: Int) {
        let oldSize = getCurrentBoardSize()
        guard newSize != oldSize else { return }
        guard gameLogic.changeBoardSize(to: newSize) else { return }
        
        // 添加缩放动画反馈
        let scaleAction = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        
        // 重新计算布局（基于新的棋盘大小）
        calculateLayout()
        
        // 重新绘制棋盘和所有标记
        setupGame()
        
        // 恢复所有已放置的标记
        restoreAllMarks()
        
        // 对棋盘应用缩放动画（如果有棋盘节点的话）
        // 注意：由于setupGame会重新创建所有节点，这里可以添加全局动画效果
    }
    
    /// 恢复所有已放置的标记
    private func restoreAllMarks() {
        let boardSize = getCurrentBoardSize()
        let totalCells = boardSize * boardSize
        
        // 恢复棋盘内的标记
        for index in 0..<totalCells {
            let mark = gameLogic.getMark(at: index)
            if mark != "" {
                let row = index / boardSize
                let col = index % boardSize
                let markNode = UIFactory.drawMark(
                    in: self,
                    row: row,
                    col: col,
                    mark: mark,
                    cellSize: cellSize,
                    offsetX: offsetX,
                    offsetY: offsetY
                )
                markNodes.append(markNode)
            }
        }
        
        // 恢复棋盘外标记
        restoreOutsideMarks()
    }
    
    /// AIゴッド模式：检查是否点击了棋盘外区域（隐藏棋盘）
    /// - Parameter location: 点击位置
    /// - Returns: 位置标识（如"top-1", "left-2"等），如果没有点击到则返回nil
    private func checkOutsideAreaClick(location: CGPoint) -> String? {
        let currentBoardSize = getCurrentBoardSize()
        let boardWidth = cellSize * CGFloat(currentBoardSize)
        let boardHeight = cellSize * CGFloat(currentBoardSize)
        let outsideAreaSize = getOutsideAreaSize()  // 使用统一的动态大小
        let tolerance: CGFloat = 10  // 容错范围，避免边缘点击失效
        
        // 检查上方区域（增加容错）
        if location.y > offsetY + boardHeight - tolerance && 
           location.y < offsetY + boardHeight + outsideAreaSize + tolerance {
            if location.x >= offsetX - tolerance && location.x < offsetX + boardWidth + tolerance {
                let col = Int((location.x - offsetX) / cellSize)
                if col >= 0 && col < currentBoardSize {
                    return "top-\(col)"
                }
            }
        }
        
        // 检查下方区域（增加容错）
        if location.y < offsetY + tolerance && 
           location.y > offsetY - outsideAreaSize - tolerance {
            if location.x >= offsetX - tolerance && location.x < offsetX + boardWidth + tolerance {
                let col = Int((location.x - offsetX) / cellSize)
                if col >= 0 && col < currentBoardSize {
                    return "bottom-\(col)"
                }
            }
        }
        
        // 检查左侧区域（增加容错）
        if location.x < offsetX + tolerance && 
           location.x > offsetX - outsideAreaSize - tolerance {
            if location.y >= offsetY - tolerance && location.y < offsetY + boardHeight + tolerance {
                let row = Int((location.y - offsetY) / cellSize)
                if row >= 0 && row < currentBoardSize {
                    return "left-\(row)"
                }
            }
        }
        
        // 检查右侧区域（增加容错）
        if location.x > offsetX + boardWidth - tolerance && 
           location.x < offsetX + boardWidth + outsideAreaSize + tolerance {
            if location.y >= offsetY - tolerance && location.y < offsetY + boardHeight + tolerance {
                let row = Int((location.y - offsetY) / cellSize)
                if row >= 0 && row < currentBoardSize {
                    return "right-\(row)"
                }
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
              let index = Int(parts[1]) else {
            return
        }
        
        let boardSize = getCurrentBoardSize()
        guard index >= 0 && index < boardSize else {
            return
        }
        
        var centerX: CGFloat = 0
        var centerY: CGFloat = 0
        let outsideOffset: CGFloat = cellSize * 0.3
        switch String(parts[0]) {
        case "top":
            centerX = offsetX + CGFloat(index) * cellSize + cellSize / 2
            centerY = offsetY + cellSize * CGFloat(boardSize) + outsideOffset
        case "bottom":
            centerX = offsetX + CGFloat(index) * cellSize + cellSize / 2
            centerY = offsetY - outsideOffset
        case "left":
            centerX = offsetX - outsideOffset
            centerY = offsetY + CGFloat(index) * cellSize + cellSize / 2
        case "right":
            centerX = offsetX + cellSize * CGFloat(boardSize) + outsideOffset
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
        // 重置缩放标志，初始状态不显示隐藏棋盘
        hasScaled = false
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
        
        let currentBoardSize = getCurrentBoardSize()
        let boardBottom = offsetY + cellSize * CGFloat(currentBoardSize)
        
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
        } else if gameMode == .vsAIGod,
                  let aiEngine = aiEngine,
                  gameLogic.currentPlayer == aiEngine.aiPlayer {
            statusText = "AIゴッドのターン..."
        }
        
        // AIゴッド模式：显示当前棋盘大小
        if gameMode == .vsAIGod {
            let boardSize = getCurrentBoardSize()
            statusText += " (\(boardSize)×\(boardSize))"
        }
        
        statusLabel = UIFactory.createStatusLabel(
            in: self,
            text: statusText,
            sceneSize: size,
            yPosition: offsetY - 70
        )
    }
}
