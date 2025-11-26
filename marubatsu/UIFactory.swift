import SpriteKit
import UIKit

// MARK: - UI 工厂类
/// 负责创建所有UI元素（按钮、标签、棋盘线等）
class UIFactory {
    
    // MARK: - 棋盘绘制
    /// 绘制3×3棋盘（黑白简洁风格）
    /// - Parameters:
    ///   - scene: 场景节点
    ///   - cellSize: 格子尺寸
    ///   - offsetX: 棋盘X偏移量
    ///   - offsetY: 棋盘Y偏移量
    ///   - removedCells: 被移除的格子索引集合（AIゴッド模式）
    static func drawBoard(
        in scene: SKScene,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat,
        removedCells: Set<Int> = []
    ) {
        let boardWidth = cellSize * CGFloat(GameConstants.boardSize)
        let boardHeight = cellSize * CGFloat(GameConstants.boardSize)
        let padding: CGFloat = 32
        let cornerRadius: CGFloat = 20
        
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
        scene.addChild(shadow)
        
        // 棋盘背景（纯白/纯黑，根据系统主题）
        let boardBackground = SKShapeNode(rect: CGRect(
            x: offsetX - padding,
            y: offsetY - padding,
            width: boardWidth + padding * 2,
            height: boardHeight + padding * 2
        ), cornerRadius: cornerRadius)
        boardBackground.fillColor = UIColor.systemBackground
        boardBackground.strokeColor = UIColor.label.withAlphaComponent(0.15)
        boardBackground.lineWidth = 1
        boardBackground.zPosition = -1
        scene.addChild(boardBackground)
        
        // 精致的网格线（黑白风格）
        let lineColor = UIColor.label.withAlphaComponent(0.25)
        
        // 垂直线
        for i in 1..<GameConstants.boardSize {
            let path = UIBezierPath()
            let x = offsetX + CGFloat(i) * cellSize
            path.move(to: CGPoint(x: x, y: offsetY))
            path.addLine(to: CGPoint(x: x, y: offsetY + cellSize * CGFloat(GameConstants.boardSize)))
            
            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = lineColor
            line.lineWidth = 2
            line.lineCap = .round
            line.zPosition = 1
            scene.addChild(line)
        }
        
        // 水平线
        for i in 1..<GameConstants.boardSize {
            let path = UIBezierPath()
            let y = offsetY + CGFloat(i) * cellSize
            path.move(to: CGPoint(x: offsetX, y: y))
            path.addLine(to: CGPoint(x: offsetX + cellSize * CGFloat(GameConstants.boardSize), y: y))
            
            let line = SKShapeNode(path: path.cgPath)
            line.strokeColor = lineColor
            line.lineWidth = 2
            line.lineCap = .round
            line.zPosition = 1
            scene.addChild(line)
        }
        
        // AIゴッド模式：绘制被移除的格子（变灰显示）
        if !removedCells.isEmpty {
            for index in removedCells {
                let row = index / GameConstants.boardSize
                let col = index % GameConstants.boardSize
                let x = offsetX + CGFloat(col) * cellSize
                let y = offsetY + CGFloat(row) * cellSize
                
                // 绘制灰色半透明覆盖层
                let removedCell = SKShapeNode(rect: CGRect(
                    x: x,
                    y: y,
                    width: cellSize,
                    height: cellSize
                ))
                removedCell.fillColor = UIColor.label.withAlphaComponent(0.1)
                removedCell.strokeColor = UIColor.label.withAlphaComponent(0.05)
                removedCell.lineWidth = 1
                removedCell.zPosition = 0
                scene.addChild(removedCell)
            }
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
    /// - Returns: 创建的标记节点
    @discardableResult
    static func drawMark(
        in scene: SKScene,
        row: Int,
        col: Int,
        mark: String,
        cellSize: CGFloat,
        offsetX: CGFloat,
        offsetY: CGFloat
    ) -> SKNode {
        let centerX = offsetX + CGFloat(col) * cellSize + cellSize / 2
        let centerY = offsetY + CGFloat(row) * cellSize + cellSize / 2
        let radius = cellSize / 2 * (1 - GameConstants.markPaddingRatio)
        
        let markNode = SKNode()
        markNode.position = CGPoint(x: centerX, y: centerY)
        markNode.zPosition = 5
        
        // 使用纯黑色
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
        // 按钮位置
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
    ///   - yPosition: Y坐标位置
    /// - Returns: 创建的按钮节点
    @discardableResult
    static func createResetButton(
        in scene: SKScene,
        sceneSize: CGSize,
        yPosition: CGFloat
    ) -> SKLabelNode {
        let button = SKLabelNode(text: "もう一度")
        button.fontSize = GameConstants.statusFontSize
        button.fontName = "Helvetica-Light"
        button.fontColor = UIColor.label.withAlphaComponent(0.6)
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
        buttonBackground.fillColor = UIColor.clear
        buttonBackground.strokeColor = UIColor.label.withAlphaComponent(0.3)
        buttonBackground.lineWidth = 1
        buttonBackground.zPosition = -1
        
        button.addChild(buttonBackground)
        button.position = CGPoint(x: sceneSize.width / 2, y: yPosition)
        button.zPosition = 10
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



