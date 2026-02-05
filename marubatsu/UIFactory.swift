import SpriteKit
import UIKit

// MARK: - UI 工厂类
/// 负责创建所有UI元素（按钮、标签、棋盘线等）
class UIFactory {
    
    // MARK: - 棋盘绘制
    /// 绘制棋盘（黑白简洁风格，支持动态大小）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - cellSize: 格子尺寸
    ///   - offsetX: 棋盘X偏移量
    ///   - offsetY: 棋盘Y偏移量
    ///   - boardSize: 棋盘大小（默认3x3）
    static func drawBoard(
        in scene: SKScene,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        boardSize: Int = GameConstants.boardSize
    ) {
        // 移除旧的棋盘节点（通过 name 属性标识）
        scene.children.forEach { node in
            if let name = node.name, name.hasPrefix("board_") {
                node.removeFromParent()
            }
        }
        
        let boardWidth = cellSize * CGFloat(boardSize)
        let boardHeight = cellSize * CGFloat(boardSize)
        let padding: CGFloat = 32
        let cornerRadius: CGFloat = 20
        
        // 所有模式统一：绘制棋盘背景和阴影（半透明）
        // 精致的阴影效果（非常微妙）
        let shadow = SKShapeNode(rect: CGRect(
            x: offsetX - padding + 2,
            y: offsetY - padding - 2,
            width: boardWidth + padding * 2,
            height: boardHeight + padding * 2
        ), cornerRadius: cornerRadius)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.08)
        shadow.strokeColor = UIColor.clear
        shadow.zPosition = -2
        shadow.name = "board_shadow"  // 添加标识
        scene.addChild(shadow)
        
        // 棋盘背景（半透明白色，所有模式统一）
        let boardBackground = SKShapeNode(rect: CGRect(
            x: offsetX - padding,
            y: offsetY - padding,
            width: boardWidth + padding * 2,
            height: boardHeight + padding * 2
        ), cornerRadius: cornerRadius)
        boardBackground.fillColor = UIColor.white.withAlphaComponent(0.5)
        boardBackground.strokeColor = UIColor.label.withAlphaComponent(0.15)
        boardBackground.lineWidth = 1
        boardBackground.zPosition = -1
        boardBackground.name = "board_background"  // 添加标识
        scene.addChild(boardBackground)
        
        // 精致的网格线（所有模式统一样式）
        let lineColor = UIColor.label.withAlphaComponent(0.25)
        let lineWidth: CGFloat = 2
        
        // 垂直线
        for i in 1..<boardSize {
            let path = UIBezierPath()
            let x = offsetX + CGFloat(i) * cellSize
            path.move(to: CGPoint(x: x, y: offsetY))
            path.addLine(to: CGPoint(x: x, y: offsetY + cellSize * CGFloat(boardSize)))
            
            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = lineColor
            line.lineWidth = lineWidth
            line.lineCap = .round
            line.zPosition = 1
            line.name = "board_line"  // 添加标识
            scene.addChild(line)
        }
        
        // 水平线
        for i in 1..<boardSize {
            let path = UIBezierPath()
            let y = offsetY + CGFloat(i) * cellSize
            path.move(to: CGPoint(x: offsetX, y: y))
            path.addLine(to: CGPoint(x: offsetX + cellSize * CGFloat(boardSize), y: y))
            
            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = lineColor
            line.lineWidth = lineWidth
            line.lineCap = .round
            line.zPosition = 1
            line.name = "board_line"  // 添加标识
            scene.addChild(line)
        }
        
    }
    
    // MARK: - 标记绘制
    /// 绘制标记（○ 或 ×）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - row: 行索引
    ///   - col: 列索引
    ///   - mark: 标记（"○" 或 "×"）
    ///   - cellSize: 格子尺寸
    ///   - offsetX: 棋盘X偏移量
    ///   - offsetY: 棋盘Y偏移量
    ///   - gameMode: 游戏模式（用于选择对应的棋子图片）
    /// - Returns: 创建的标记节点
    @discardableResult
    static func drawMark(
        in scene: SKScene,
        row: Int,
        col: Int,
        mark: String,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        gameMode: GameMode = .twoPlayer
    ) -> SKNode {
        let centerX = offsetX + CGFloat(col) * cellSize + cellSize / 2
        let centerY = offsetY + CGFloat(row) * cellSize + cellSize / 2
        
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
            
            // 根据cellSize调整大小
            let maxSize = cellSize * 0.9  // 留出一些边距
            let scale = maxSize / max(heroImage.size.width, heroImage.size.height)
            heroSprite.setScale(scale)
            
            markNode.addChild(heroSprite)
        } else {
            // 如果图片不存在，使用绘制的方式作为后备
            let radius = cellSize / 2 * (1 - GameConstants.markPaddingRatio)
            let markColor = UIColor.label
            
            if mark == "○" {
                // 绘制精致的圆形
                let circle = SKShapeNode(circleOfRadius: radius)
                circle.strokeColor = markColor
                circle.fillColor = UIColor.clear
                circle.lineWidth = 6
                circle.lineCap = .round
                markNode.addChild(circle)
            } else {
                // 绘制精致的×
                let path = UIBezierPath()
                let offset = radius * 0.9
                path.move(to: CGPoint(x: -offset, y: -offset))
                path.addLine(to: CGPoint(x: offset, y: offset))
                path.move(to: CGPoint(x: offset, y: -offset))
                path.addLine(to: CGPoint(x: -offset, y: offset))
                
                let cross = SKShapeNode(path: path.cgPath)
                cross.strokeColor = markColor
                cross.lineWidth = 6
                cross.lineCap = .round
                cross.lineJoin = .round
                markNode.addChild(cross)
            }
        }
        
        // 精致的动画效果
        markNode.alpha = 0
        markNode.setScale(0.4)
        scene.addChild(markNode)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.2)
        let group = SKAction.group([fadeIn, scaleUp])
        markNode.run(group)
        
        return markNode
    }
    
    // MARK: - 按钮创建
    /// 创建返回按钮（MENU）- 统一布局
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - sceneSize: 场景尺寸
    /// - Returns: 创建的按钮节点
    @discardableResult
    static func createBackButton(
        in scene: SKScene,
        sceneSize: CGSize
    ) -> SKLabelNode {
        let button = SKLabelNode(text: "MENU")
        button.fontSize = GameConstants.buttonFontSize
        button.fontName = "Helvetica-Medium"
        button.fontColor = UIColor.label
        
        // 创建按钮背景（黑白风格）
        let buttonWidth: CGFloat = 100
        let buttonHeight: CGFloat = 44
        let buttonBackground = SKShapeNode(rect: CGRect(
            x: -buttonWidth / 2,
            y: -buttonHeight / 2,
            width: buttonWidth,
            height: buttonHeight
        ), cornerRadius: 8)
        
        button.verticalAlignmentMode = .center
        button.horizontalAlignmentMode = .center
        
        buttonBackground.fillColor = UIColor.secondarySystemBackground
        buttonBackground.strokeColor = UIColor.label.withAlphaComponent(0.2)
        buttonBackground.lineWidth = 1
        buttonBackground.zPosition = -1
        
        // 微妙的阴影
        let shadow = SKShapeNode(rect: CGRect(
            x: -buttonWidth / 2 + 1,
            y: -buttonHeight / 2 - 1,
            width: buttonWidth,
            height: buttonHeight
        ), cornerRadius: 8)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.05)
        shadow.strokeColor = UIColor.clear
        shadow.zPosition = -2
        
        button.addChild(shadow)
        button.addChild(buttonBackground)
        // 按钮位置：左上角（统一布局）
        button.position = CGPoint(x: 60, y: sceneSize.height - 70)
        button.name = "backButton"
        button.zPosition = 100
        scene.addChild(button)
        
        return button
    }
    
    /// 创建模式切换按钮（黑白简洁风格）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - gameMode: 当前游戏模式
    ///   - sceneSize: 场景尺寸
    /// - Returns: 创建的按钮节点
    @discardableResult
    static func createModeButton(
        in scene: SKScene,
        gameMode: GameMode,
        sceneSize: CGSize
    ) -> SKLabelNode {
        let modeText: String
        switch gameMode {
        case .twoPlayer:
            modeText = "人間"
        case .vsAI:
            modeText = "AI"
        case .vsAIGod:
            modeText = "AIゴッド"
        }
        let button = SKLabelNode(text: modeText)
        button.fontSize = GameConstants.buttonFontSize
        button.fontName = "Helvetica-Medium"
        button.fontColor = UIColor.label
        
        // 创建按钮背景（黑白风格）
        let buttonWidth: CGFloat = modeText.count > 4 ? 120 : 90  // AIゴッド需要更宽
        let buttonHeight: CGFloat = 44
        let buttonBackground = SKShapeNode(rect: CGRect(
            x: -buttonWidth / 2,
            y: -buttonHeight / 2,
            width: buttonWidth,
            height: buttonHeight
        ), cornerRadius: 8)
        
        button.verticalAlignmentMode = .center
        button.horizontalAlignmentMode = .center
        
        buttonBackground.fillColor = UIColor.secondarySystemBackground
        buttonBackground.strokeColor = UIColor.label.withAlphaComponent(0.2)
        buttonBackground.lineWidth = 1
        buttonBackground.zPosition = -1
        
        // 微妙的阴影
        let shadow = SKShapeNode(rect: CGRect(
            x: -buttonWidth / 2 + 1,
            y: -buttonHeight / 2 - 1,
            width: buttonWidth,
            height: buttonHeight
        ), cornerRadius: 8)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.05)
        shadow.strokeColor = UIColor.clear
        shadow.zPosition = -2
        
        button.addChild(shadow)
        button.addChild(buttonBackground)
        // 按钮位置：右上角（统一布局）
        button.position = CGPoint(x: sceneSize.width - 60, y: sceneSize.height - 70)
        button.name = "modeButton"
        button.zPosition = 100
        scene.addChild(button)
        
        return button
    }
    
    /// 创建重置按钮（黑白简洁风格）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - sceneSize: 场景尺寸
    ///   - yPosition: Y坐标位置（已废弃，统一使用底部位置80）
    /// - Returns: 创建的按钮节点
    @discardableResult
    static func createResetButton(
        in scene: SKScene,
        sceneSize: CGSize,
        yPosition: CGFloat = 80
    ) -> SKLabelNode {
        let button = SKLabelNode(text: "RESET")
        button.fontSize = GameConstants.buttonFontSize
        button.fontName = "Helvetica-Medium"
        button.fontColor = UIColor.label
        // 让文字真正居中
        button.verticalAlignmentMode = .center
        button.horizontalAlignmentMode = .center
        // 按钮背景（简洁边框）
        let buttonWidth: CGFloat = 140
        let buttonHeight: CGFloat = 50
        let buttonBackground = SKShapeNode(rect: CGRect(
            x: -buttonWidth / 2,
            y: -buttonHeight / 2,
            width: buttonWidth,
            height: buttonHeight
        ), cornerRadius: 10)
        buttonBackground.fillColor = UIColor.secondarySystemBackground
        buttonBackground.strokeColor = UIColor.label.withAlphaComponent(0.3)
        buttonBackground.lineWidth = 1
        buttonBackground.zPosition = -1
        
        button.addChild(buttonBackground)
        // 按钮位置：最底下（居中，统一布局）
        button.position = CGPoint(x: sceneSize.width / 2, y: 80)
        button.zPosition = 100
        button.name = "resetButton"
        scene.addChild(button)
        
        return button
    }
    
    // MARK: - 标签创建
    /// 创建状态标签（显示当前玩家）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - text: 状态文本
    ///   - sceneSize: 场景尺寸
    ///   - yPosition: Y坐标位置
    /// - Returns: 创建的标签节点
    @discardableResult
    static func createStatusLabel(
        in scene: SKScene,
        text: String,
        sceneSize: CGSize,
        yPosition: CGFloat
    ) -> SKLabelNode {
        let label = SKLabelNode(text: text)
        label.fontSize = GameConstants.statusFontSize
        label.fontName = "Helvetica-Light"
        label.fontColor = UIColor.label.withAlphaComponent(0.7)
        
        // 状态标签在棋盘上方（无背景，简洁）
        label.position = CGPoint(x: sceneSize.width / 2, y: yPosition)
        label.zPosition = 10
        scene.addChild(label)
        
        return label
    }
    
    /// 创建结果标签（显示游戏结果）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - message: 结果消息
    ///   - sceneSize: 场景尺寸
    ///   - yPosition: Y坐标位置
    /// - Returns: 创建的标签节点
    @discardableResult
    static func createResultLabel(
        in scene: SKScene,
        message: String,
        sceneSize: CGSize,
        yPosition: CGFloat
    ) -> SKLabelNode {
        let label = SKLabelNode(text: message)
        label.fontSize = GameConstants.resultFontSize
        label.fontName = "Helvetica-Medium"
        label.fontColor = UIColor.label
        
        label.position = CGPoint(x: sceneSize.width / 2, y: yPosition)
        label.zPosition = 20
        scene.addChild(label)
        
        return label
    }
    
}
