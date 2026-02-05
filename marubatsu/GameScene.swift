import SpriteKit

// MARK: - 游戏场景
/// 负责UI绘制、触摸事件处理和调用游戏逻辑
class GameScene: SKScene {
    
    // MARK: - 属性
    /// 游戏逻辑管理器
    internal var gameLogic: GameLogic
    
    /// AI引擎
    private var aiEngine: AIEngine?
    
    /// 游戏模式
    var gameMode: GameMode = .twoPlayer {
        didSet {
            // 切换模式时更新AI引擎
            if gameMode == .vsAI {
                aiEngine = AIEngine(aiPlayer: "×")
            } else if gameMode == .vsAIGod {
                aiEngine = AIGodEngine(aiPlayer: "×")
            } else {
                aiEngine = nil
            }
            
            // 创建对应的Handler、TouchHandler和Renderer
            currentHandler = GameModeHandlerFactory.create(for: gameMode)
            touchHandler = TouchHandlerFactory.create(for: gameMode)
            renderer = UIRendererFactory.create(for: gameMode)
        }
    }
    
    /// 当前模式处理器
    internal var currentHandler: GameModeHandler?
    
    /// 当前触摸处理器
    private var touchHandler: TouchHandler?
    
    /// 当前UI渲染器
    private var renderer: UIRenderer?
    
    /// 布局计算
    internal var cellSize: CGFloat = 120
    internal var offsetX: CGFloat = 0
    internal var offsetY: CGFloat = 0
    
    /// UI 节点
    private var statusLabel: SKLabelNode?
    private var resultLabel: SKLabelNode?
    internal var resetButton: SKLabelNode?
    internal var modeButton: SKLabelNode?
    internal var backButton: SKLabelNode?
    internal var markNodes: [SKNode] = []
    
    /// AIゴッド模式：背景节点
    private var backgroundGradient: SKSpriteNode?
    
    /// AIゴッド模式：机器人角色节点
    private var heroX: SKSpriteNode?
    private var heroO: SKSpriteNode?
    
    /// 返回欢迎页面的回调
    var onBackToWelcome: (() -> Void)?
    
    
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
        // 初始化Handler
        currentHandler = GameModeHandlerFactory.create(for: gameMode)
        touchHandler = TouchHandlerFactory.create(for: gameMode)
        renderer = UIRendererFactory.create(for: gameMode)
        
        // 设置背景（所有模式都使用黑色背景）
        backgroundColor = UIColor.black
        // 设置渐变背景
        setupBackground()
        calculateLayout()
        setupGame()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        // 屏幕尺寸改变时重新计算布局
        calculateLayout()
        // 确保场景背景色是黑色（所有模式都使用黑色背景）
        backgroundColor = UIColor.black
        // 更新背景尺寸
        backgroundGradient?.size = size
        backgroundGradient?.position = CGPoint(x: size.width / 2, y: size.height / 2)
        if children.count > 0 {
            setupGame()
        }
    }
    
    // MARK: - 背景设置
    /// 设置背景
    /// 不同模式的背景图：
    /// - 人間モード (twoPlayer): bg_gradient_1.png
    /// - AIモード (vsAI): bg_gradient_2.png
    /// - AIゴッドモード (vsAIGod): bg_gradient_3.png
    internal func setupBackground() {
        // 移除旧的背景节点
        backgroundGradient?.removeFromParent()
        
        // 根据游戏模式选择背景图
        let gradientImageName: String
        switch gameMode {
        case .twoPlayer:
            // 人間モード：使用 bg_gradient_1.png
            gradientImageName = "bg_gradient_1"
            backgroundColor = UIColor.black
        case .vsAI:
            // AIモード：使用 bg_gradient_2.png
            gradientImageName = "bg_gradient_2"
            backgroundColor = UIColor.black
        case .vsAIGod:
            // AIゴッドモード：使用 bg_gradient_3.png
            gradientImageName = "bg_gradient_3"
            backgroundColor = UIColor.black
        }
        
        // 创建渐变背景（最底层）
        if let gradientImage = UIImage(named: gradientImageName) {
            let gradientTexture = SKTexture(image: gradientImage)
            backgroundGradient = SKSpriteNode(texture: gradientTexture)
            backgroundGradient?.size = size
            backgroundGradient?.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundGradient?.zPosition = -10  // 最底层
            addChild(backgroundGradient!)
        }
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
    internal func setupGame() {
        // 移除游戏相关的节点（但保留背景）
        markNodes.forEach { $0.removeFromParent() }
        markNodes.removeAll()
        
        // 移除旧的UI节点（但保留背景）
        statusLabel?.removeFromParent()
        resultLabel?.removeFromParent()
        resetButton?.removeFromParent()
        modeButton?.removeFromParent()
        backButton?.removeFromParent()
        heroX?.removeFromParent()
        heroO?.removeFromParent()
        
        // 设置背景（如果模式改变或首次设置）
        setupBackground()
        
        // 绘制棋盘（动态获取实际棋盘大小）
        let boardSize = gameLogic.getBoardSize()
        
        // 确保场景背景色是黑色（所有模式都使用黑色背景）
        backgroundColor = UIColor.black
        
        // AIゴッド模式：如果首次进入且当前玩家是默认的"○"，设置AI先手
        if gameMode == .vsAIGod, gameLogic.currentPlayer == "○", 
           gameLogic.gameState == .playing,
           let aiEngine = aiEngine {
            gameLogic.setCurrentPlayer(aiEngine.aiPlayer)
        }
        
        UIFactory.drawBoard(
            in: self,
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY,
            boardSize: boardSize
        )
        
        // 所有模式：添加机器人角色（根据模式显示对应的角色）
        setupHeroCharacters()
        
        // 统一按钮布局（所有模式）
        // MENU按钮：左上角
        backButton = UIFactory.createBackButton(
            in: self,
            sceneSize: size
        )
        
        // 模式切换按钮：右上角
        modeButton = UIFactory.createModeButton(
            in: self,
            gameMode: gameMode,
            sceneSize: size
        )
        
        // RESET按钮：最底下（居中，所有模式统一）
        resetButton = UIFactory.createResetButton(
            in: self,
            sceneSize: size
        )
        
        // 更新状态标签
        updateStatusLabel()
        
        // AIゴッド模式：如果AI先手，自动下第一步（快速执行）
        if gameMode == .vsAIGod, gameLogic.gameState == .playing,
           let aiEngine = aiEngine,
           gameLogic.currentPlayer == aiEngine.aiPlayer {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let handler = self.currentHandler {
                    handler.handleAITurn(in: self)
                }
            }
        }
    }
    
    /// 设置机器人角色（所有模式）
    internal func setupHeroCharacters() {
        // 计算机器人位置（棋盘两侧）
        let boardSize = gameLogic.getBoardSize()
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let boardCenterY = offsetY + boardHeight / 2
        
        // 机器人大小（根据棋盘大小调整）
        let heroSize: CGFloat = min(cellSize * 1.5, 200)
        
        // 根据游戏模式选择对应的机器人角色图片
        let imageSuffix: String
        switch gameMode {
        case .twoPlayer:
            imageSuffix = "_1"  // 人間モード：hero_x_1.png, hero_o_1.png
        case .vsAI:
            imageSuffix = "_2"  // AIモード：hero_x_2.png, hero_o_2.png
        case .vsAIGod:
            imageSuffix = "_3"  // AIゴッドモード：hero_x_3.png, hero_o_3.png
        }
        
        // X机器人（左侧）
        if let heroXImage = UIImage(named: "hero_x\(imageSuffix)") {
            let heroXTexture = SKTexture(image: heroXImage)
            heroX = SKSpriteNode(texture: heroXTexture)
            let scale = heroSize / heroXImage.size.width
            heroX?.setScale(scale)
            heroX?.position = CGPoint(
                x: offsetX - heroSize * 0.8,
                y: boardCenterY
            )
            heroX?.zPosition = 10
            addChild(heroX!)
        }
        
        // O机器人（右侧）
        if let heroOImage = UIImage(named: "hero_o\(imageSuffix)") {
            let heroOTexture = SKTexture(image: heroOImage)
            heroO = SKSpriteNode(texture: heroOTexture)
            let scale = heroSize / heroOImage.size.width
            heroO?.setScale(scale)
            heroO?.position = CGPoint(
                x: offsetX + boardWidth + heroSize * 0.8,
                y: boardCenterY
            )
            heroO?.zPosition = 10
            addChild(heroO!)
        }
    }
    
    // MARK: - 触摸事件处理
    /// 处理触摸结束事件
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)

        // 使用TouchHandler处理触摸事件
        if let touchHandler = touchHandler {
            if touchHandler.handleTouch(at: touchLocation, in: self) {
                return
            }
        }

        // 如果TouchHandler未处理，使用原有逻辑（向后兼容）
        // 游戏结束时，不允许其他操作
        if gameLogic.gameState != .playing {
            return
        }

        // AI模式下，如果当前是AI回合，不允许玩家点击
        if (gameMode == .vsAI || gameMode == .vsAIGod) && gameLogic.currentPlayer == aiEngine?.aiPlayer {
            return
        }

        // 检测点击的格子（动态获取实际棋盘大小）
        let boardSize = gameLogic.getBoardSize()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let index = row * boardSize + col
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize

                if touchLocation.x > x && touchLocation.x < x + cellSize &&
                   touchLocation.y > y && touchLocation.y < y + cellSize {
                    if gameLogic.isEmpty(at: index) {
                        makeMove(row: row, col: col, index: index)
                    }
                }
            }
        }
    }
    
    // MARK: - 游戏操作
    /// 切换游戏模式（三种模式循环：人間 -> AI -> AIゴッド -> 人間）
    internal func toggleGameMode() {
        switch gameMode {
        case .twoPlayer:
            gameMode = .vsAI
        case .vsAI:
            gameMode = .vsAIGod
        case .vsAIGod:
            gameMode = .twoPlayer
        }
        // 重新设置游戏（会重新创建所有按钮，保持布局一致）
        resetGame()
    }
    
    /// 执行下棋
    /// - Parameters:
    ///   - row: 行索引
    ///   - col: 列索引
    ///   - index: 格子索引
    internal func makeMove(row: Int, col: Int, index: Int) {
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
            offsetY: offsetY,
            gameMode: gameMode
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
            if (gameMode == .vsAI || gameMode == .vsAIGod) && gameLogic.gameState == .playing {
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
        
        // 获取当前棋盘状态（动态获取实际棋盘大小）
        let boardSize = gameLogic.getBoardSize()
        let totalCells = boardSize * boardSize
        let board = (0..<totalCells).map { gameLogic.getMark(at: $0) }
        
        // 获取AI最佳下棋位置
        if let bestMove = aiEngine.findBestMove(board: board) {
            let row = bestMove / boardSize
            let col = bestMove % boardSize
            makeMove(row: row, col: col, index: bestMove)
        }
    }
    
    // MARK: - 辅助方法
    /// 获取当前棋盘大小（动态获取）
    internal func getCurrentBoardSize() -> Int {
        return gameLogic.getBoardSize()
    }
    
    /// 重置游戏
    internal func resetGame() {
        // 使用Handler重置游戏
        currentHandler?.resetGame(in: self)
    }
    
    // MARK: - UI 更新
    /// 显示游戏结果
    /// - Parameter message: 结果消息
    internal func showResult(_ message: String) {
        // 移除状态标签和之前的结果
        statusLabel?.removeFromParent()
        resultLabel?.removeFromParent()
        
        let currentBoardSize = getCurrentBoardSize()
        let boardBottom = offsetY + cellSize * CGFloat(currentBoardSize)
        
        // 显示结果（在棋盘下方，简洁风格）
        resultLabel = UIFactory.createResultLabel(
            in: self,
            message: message,
            sceneSize: size,
            yPosition: boardBottom + 60
        )
        
        // 注意：resetButton已经在setupGame中创建，不需要重新创建
    }
    
    /// 更新状态标签（显示当前玩家）
    internal func updateStatusLabel() {
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
        
        // 所有模式使用统一的样式
        statusLabel = UIFactory.createStatusLabel(
            in: self,
            text: statusText,
            sceneSize: size,
            yPosition: offsetY - 70
        )
    }
}
