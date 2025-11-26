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
            if gameMode == .vsAI {
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
        
        // 绘制棋盘
        UIFactory.drawBoard(
            in: self,
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY
        )
        
        // 绘制模式按钮
        modeButton = UIFactory.createModeButton(
            in: self,
            gameMode: gameMode,
            sceneSize: size
        )
        
        // 更新状态标签
        updateStatusLabel()
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
        if gameMode == .vsAI && gameLogic.currentPlayer == aiEngine?.aiPlayer {
            return
        }
        
        // 检测点击的格子
        for row in 0..<GameConstants.boardSize {
            for col in 0..<GameConstants.boardSize {
                let index = row * GameConstants.boardSize + col
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize
                
                if location.x > x && location.x < x + cellSize &&
                   location.y > y && location.y < y + cellSize {
                    
                    if gameLogic.isEmpty(at: index) {
                        makeMove(row: row, col: col, index: index)
                    }
                }
            }
        }
    }
    
    // MARK: - 游戏操作
    /// 切换游戏模式
    private func toggleGameMode() {
        gameMode = gameMode == .twoPlayer ? .vsAI : .twoPlayer
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
    
    /// 重置游戏
    private func resetGame() {
        gameLogic.reset()
        setupGame()
        
        // AI模式下，如果AI先手，自动下第一步
        if gameMode == .vsAI,
           let aiEngine = aiEngine,
           gameLogic.currentPlayer == aiEngine.aiPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.makeAIMove()
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
