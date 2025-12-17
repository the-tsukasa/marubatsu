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
    
    /// AIゴッド模式：棋盘外标记节点（key: 位置标识，value: 节点）
    private var outsideMarkNodes: [String: SKNode] = [:]
    
    /// 长按检测（用于缩小棋盘）
    internal var longPressTimer: Timer?
    internal var longPressLocation: CGPoint?
    
    /// AIゴッド模式：是否已触发隐藏棋盘（用于控制隐藏棋盘显示）
    internal var hasScaled: Bool = false
    
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
        outsideMarkNodes.forEach { $0.value.removeFromParent() }
        outsideMarkNodes.removeAll()
        
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
        let isGodMode = gameMode == .vsAIGod
        
        // 确保场景背景色是黑色（所有模式都使用黑色背景）
        backgroundColor = UIColor.black
        
        // AIゴッド模式：如果首次进入且当前玩家是默认的"○"，设置AI先手
        if isGodMode, gameLogic.currentPlayer == "○", 
           gameLogic.gameState == .playing,
           let aiEngine = aiEngine {
            gameLogic.setCurrentPlayer(aiEngine.aiPlayer)
        }
        
        UIFactory.drawBoard(
            in: self,
            cellSize: cellSize,
            offsetX: offsetX,
            offsetY: offsetY,
            boardSize: boardSize,
            removedCells: gameLogic.getRemovedCells(),
            isGodMode: isGodMode
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
        if isGodMode, gameLogic.gameState == .playing,
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
    
    /// 获取隐藏棋盘区域大小（动态调整）
    private func getOutsideAreaSize() -> CGFloat {
        let boardSize = getCurrentBoardSize()
        // 棋盘越小，隐藏区域越大，充分利用空间
        let multiplier: CGFloat = boardSize == 3 ? 1.5 : (boardSize == 4 ? 1.2 : 1.0)
        return cellSize * multiplier
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
    /// 处理触摸开始事件
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 所有模式使用统一的触摸处理
    }
    
    /// 处理触摸结束事件
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 取消长按计时器
        touchHandler?.cancelLongPress(in: self)
        
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: self)
        
        // 使用TouchHandler处理触摸事件
        if let touchHandler = touchHandler {
            if touchHandler.handleTouch(at: touchLocation, in: self) {
                return  // 已处理
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
    
    /// 触发隐藏棋盘（双击上下空白区域后调用）
    internal func triggerHiddenBoard() {
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
                    offsetY: offsetY,
                    gameMode: gameMode
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
    internal func checkOutsideAreaClick(location: CGPoint) -> String? {
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
    internal func placeOutsideMark(at position: String) {
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
        
        let markNode = SKNode()
        markNode.position = CGPoint(x: centerX, y: centerY)
        markNode.zPosition = 5
        
        // 根据游戏模式选择对应的棋子图片
        let imageSuffix: String
        switch gameMode {
        case .twoPlayer:
            imageSuffix = "_1"  // 人間モード：hero_o_1.png, hero_x_1.png
        case .vsAI:
            imageSuffix = "_2"  // AIモード：hero_o_2.png, hero_x_2.png
        case .vsAIGod:
            imageSuffix = "_3"  // AIゴッドモード：hero_o_3.png, hero_x_3.png
        }
        
        // 使用图片代替绘制
        let imageName = (mark == "○") ? "hero_o\(imageSuffix)" : "hero_x\(imageSuffix)"
        if let heroImage = UIImage(named: imageName) {
            let heroTexture = SKTexture(image: heroImage)
            let heroSprite = SKSpriteNode(texture: heroTexture)
            
            // 根据cellSize调整大小（棋盘外稍小一些）
            let maxSize = cellSize * 0.6  // 棋盘外稍小
            let scale = maxSize / max(heroImage.size.width, heroImage.size.height)
            heroSprite.setScale(scale)
            
            markNode.addChild(heroSprite)
        } else {
            // 如果图片不存在，使用绘制的方式作为后备
            let radius = cellSize / 2 * (1 - GameConstants.markPaddingRatio) * 0.7  // 稍小一些
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
    internal func checkGameStateWithOutside() {
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
    
    /// 移除格子（缩小棋盘）
    internal func removeCell(at index: Int) {
        guard gameLogic.removeCell(at: index) else { return }
        
        // 更新UI：隐藏被移除的格子
        setupGame()
    }
    
    /// AIゴッド模式：AI下棋（可以在棋盘外放置或缩小棋盘）
    internal func makeAIGodMove() {
        guard gameLogic.gameState == .playing,
              let aiEngine = aiEngine,
              gameLogic.currentPlayer == aiEngine.aiPlayer else {
            return
        }
        
        let boardSize = getCurrentBoardSize()
        let totalCells = boardSize * boardSize
        
        // 获取当前棋盘状态（排除被移除的格子）
        var board: [String] = []
        for i in 0..<totalCells {
            if gameLogic.isCellRemoved(at: i) {
                board.append("REMOVED") // 标记为已移除，AI不会选择
            } else {
                board.append(gameLogic.getMark(at: i))
            }
        }
        
        // 策略1：优先在棋盘内下棋
        // 创建一个临时棋盘，将已移除的格子标记为空，让AI可以评估
        let tempBoard = board.map { $0 == "REMOVED" ? "" : $0 }
        if let bestMove = aiEngine.findBestMove(board: tempBoard) {
            // 检查这个位置是否有效（未被移除且为空）
            if bestMove < totalCells && 
               !gameLogic.isCellRemoved(at: bestMove) && 
               gameLogic.isEmpty(at: bestMove) {
                let row = bestMove / boardSize
                let col = bestMove % boardSize
                makeMove(row: row, col: col, index: bestMove)
                return
            }
        }
        
        // 策略2：检查是否需要在棋盘外放置以阻止玩家获胜
        if let blockingPosition = findBlockingOutsidePosition(boardSize: boardSize) {
            placeOutsideMark(at: blockingPosition)
            return
        }
        
        // 策略3：检查是否可以在棋盘外放置以形成获胜
        if let winningPosition = findWinningOutsidePosition(boardSize: boardSize) {
            placeOutsideMark(at: winningPosition)
            return
        }
        
        // 策略4：在棋盘外随机放置（作为最后手段）
        let outsidePositions = generateOutsidePositions(boardSize: boardSize)
        let availableOutside = outsidePositions.filter { gameLogic.getOutsideMark(at: $0) == "" }
        if let randomPosition = availableOutside.randomElement() {
            placeOutsideMark(at: randomPosition)
        }
    }
    
    /// 生成棋盘外位置列表（动态）
    /// - Parameter boardSize: 当前棋盘大小
    /// - Returns: 棋盘外位置标识数组
    private func generateOutsidePositions(boardSize: Int) -> [String] {
        var positions: [String] = []
        for i in 0..<boardSize {
            positions.append("top-\(i)")
            positions.append("bottom-\(i)")
            positions.append("left-\(i)")
            positions.append("right-\(i)")
        }
        return positions
    }
    
    /// 查找需要阻止玩家获胜的棋盘外位置
    /// - Parameter boardSize: 当前棋盘大小
    /// - Returns: 需要放置的位置标识，如果没有则返回nil
    private func findBlockingOutsidePosition(boardSize: Int) -> String? {
        let humanPlayer = aiEngine?.humanPlayer ?? "○"
        
        // 检查所有可能的获胜线
        for line in gameLogic.getWinningLines() {
            guard line.count == 3 else { continue }
            
            let pos0 = line[0]
            let pos1 = line[1]
            let pos2 = line[2]
            
            let row0 = pos0 / boardSize
            let col0 = pos0 % boardSize
            let row1 = pos1 / boardSize
            let col1 = pos1 % boardSize
            let row2 = pos2 / boardSize
            let col2 = pos2 % boardSize
            
            let mark0 = gameLogic.getMark(at: pos0)
            let mark1 = gameLogic.getMark(at: pos1)
            let mark2 = gameLogic.getMark(at: pos2)
            
            // 检查是否是横线（同一行）
            if row0 == row1 && row1 == row2 {
                // 检查上方棋盘外位置
                let top0 = gameLogic.getOutsideMark(at: "top-\(col0)")
                let top1 = gameLogic.getOutsideMark(at: "top-\(col1)")
                let top2 = gameLogic.getOutsideMark(at: "top-\(col2)")
                
                // 检查这6个位置（3个棋盘内 + 3个上方棋盘外）中玩家是否有2个
                let marks = [mark0, mark1, mark2, top0, top1, top2]
                let humanCount = marks.filter { $0 == humanPlayer }.count
                if humanCount == 2 {
                    if top0 == "" { return "top-\(col0)" }
                    if top1 == "" { return "top-\(col1)" }
                    if top2 == "" { return "top-\(col2)" }
                }
                
                // 检查下方棋盘外位置
                let bottom0 = gameLogic.getOutsideMark(at: "bottom-\(col0)")
                let bottom1 = gameLogic.getOutsideMark(at: "bottom-\(col1)")
                let bottom2 = gameLogic.getOutsideMark(at: "bottom-\(col2)")
                
                let marksBottom = [mark0, mark1, mark2, bottom0, bottom1, bottom2]
                let humanCountBottom = marksBottom.filter { $0 == humanPlayer }.count
                if humanCountBottom == 2 {
                    if bottom0 == "" { return "bottom-\(col0)" }
                    if bottom1 == "" { return "bottom-\(col1)" }
                    if bottom2 == "" { return "bottom-\(col2)" }
                }
            }
            
            // 检查是否是竖线（同一列）
            if col0 == col1 && col1 == col2 {
                // 检查左侧棋盘外位置
                let left0 = gameLogic.getOutsideMark(at: "left-\(row0)")
                let left1 = gameLogic.getOutsideMark(at: "left-\(row1)")
                let left2 = gameLogic.getOutsideMark(at: "left-\(row2)")
                
                let marksLeft = [mark0, mark1, mark2, left0, left1, left2]
                let humanCountLeft = marksLeft.filter { $0 == humanPlayer }.count
                if humanCountLeft == 2 {
                    if left0 == "" { return "left-\(row0)" }
                    if left1 == "" { return "left-\(row1)" }
                    if left2 == "" { return "left-\(row2)" }
                }
                
                // 检查右侧棋盘外位置
                let right0 = gameLogic.getOutsideMark(at: "right-\(row0)")
                let right1 = gameLogic.getOutsideMark(at: "right-\(row1)")
                let right2 = gameLogic.getOutsideMark(at: "right-\(row2)")
                
                let marksRight = [mark0, mark1, mark2, right0, right1, right2]
                let humanCountRight = marksRight.filter { $0 == humanPlayer }.count
                if humanCountRight == 2 {
                    if right0 == "" { return "right-\(row0)" }
                    if right1 == "" { return "right-\(row1)" }
                    if right2 == "" { return "right-\(row2)" }
                }
            }
        }
        
        return nil
    }
    
    /// 查找可以形成获胜的棋盘外位置
    /// - Parameter boardSize: 当前棋盘大小
    /// - Returns: 可以获胜的位置标识，如果没有则返回nil
    private func findWinningOutsidePosition(boardSize: Int) -> String? {
        guard let aiEngine = aiEngine else { return nil }
        let aiPlayer = aiEngine.aiPlayer
        
        // 检查所有可能的获胜线
        for line in gameLogic.getWinningLines() {
            guard line.count == 3 else { continue }
            
            let pos0 = line[0]
            let pos1 = line[1]
            let pos2 = line[2]
            
            let row0 = pos0 / boardSize
            let col0 = pos0 % boardSize
            let row1 = pos1 / boardSize
            let col1 = pos1 % boardSize
            let row2 = pos2 / boardSize
            let col2 = pos2 % boardSize
            
            let mark0 = gameLogic.getMark(at: pos0)
            let mark1 = gameLogic.getMark(at: pos1)
            let mark2 = gameLogic.getMark(at: pos2)
            
            // 检查是否是横线（同一行）
            if row0 == row1 && row1 == row2 {
                // 检查上方棋盘外位置
                let top0 = gameLogic.getOutsideMark(at: "top-\(col0)")
                let top1 = gameLogic.getOutsideMark(at: "top-\(col1)")
                let top2 = gameLogic.getOutsideMark(at: "top-\(col2)")
                
                let marks = [mark0, mark1, mark2, top0, top1, top2]
                let aiCount = marks.filter { $0 == aiPlayer }.count
                if aiCount == 2 {
                    if top0 == "" { return "top-\(col0)" }
                    if top1 == "" { return "top-\(col1)" }
                    if top2 == "" { return "top-\(col2)" }
                }
                
                // 检查下方棋盘外位置
                let bottom0 = gameLogic.getOutsideMark(at: "bottom-\(col0)")
                let bottom1 = gameLogic.getOutsideMark(at: "bottom-\(col1)")
                let bottom2 = gameLogic.getOutsideMark(at: "bottom-\(col2)")
                
                let marksBottom = [mark0, mark1, mark2, bottom0, bottom1, bottom2]
                let aiCountBottom = marksBottom.filter { $0 == aiPlayer }.count
                if aiCountBottom == 2 {
                    if bottom0 == "" { return "bottom-\(col0)" }
                    if bottom1 == "" { return "bottom-\(col1)" }
                    if bottom2 == "" { return "bottom-\(col2)" }
                }
            }
            
            // 检查是否是竖线（同一列）
            if col0 == col1 && col1 == col2 {
                // 检查左侧棋盘外位置
                let left0 = gameLogic.getOutsideMark(at: "left-\(row0)")
                let left1 = gameLogic.getOutsideMark(at: "left-\(row1)")
                let left2 = gameLogic.getOutsideMark(at: "left-\(row2)")
                
                let marksLeft = [mark0, mark1, mark2, left0, left1, left2]
                let aiCountLeft = marksLeft.filter { $0 == aiPlayer }.count
                if aiCountLeft == 2 {
                    if left0 == "" { return "left-\(row0)" }
                    if left1 == "" { return "left-\(row1)" }
                    if left2 == "" { return "left-\(row2)" }
                }
                
                // 检查右侧棋盘外位置
                let right0 = gameLogic.getOutsideMark(at: "right-\(row0)")
                let right1 = gameLogic.getOutsideMark(at: "right-\(row1)")
                let right2 = gameLogic.getOutsideMark(at: "right-\(row2)")
                
                let marksRight = [mark0, mark1, mark2, right0, right1, right2]
                let aiCountRight = marksRight.filter { $0 == aiPlayer }.count
                if aiCountRight == 2 {
                    if right0 == "" { return "right-\(row0)" }
                    if right1 == "" { return "right-\(row1)" }
                    if right2 == "" { return "right-\(row2)" }
                }
            }
        }
        
        return nil
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
