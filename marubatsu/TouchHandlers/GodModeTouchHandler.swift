import SpriteKit
import Foundation

// MARK: - AIゴッド模式触摸处理器
class GodModeTouchHandler: TouchHandler {
    let gameMode: GameMode = .vsAIGod
    
    func handleTouch(at location: CGPoint, in scene: GameScene) -> Bool {
        // 检查按钮点击
        if checkButtonClicks(at: location, in: scene) {
            return true
        }
        
        // 游戏结束时不允许下棋
        guard scene.handlerGameLogic.gameState == .playing else {
            return false
        }
        
        // 检查是否点击在棋盘外区域（隐藏棋盘）
        if scene.hasScaled {
            if let position = scene.checkOutsideAreaClick(location: location) {
                // 在棋盘外放置标记
                scene.placeOutsideMark(at: position)
                return true
            }
        }
        
        // 检查是否点击在棋盘上
        let boardSize = scene.handlerGameLogic.getBoardSize()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let index = row * boardSize + col
                let x = scene.handlerOffsetX + CGFloat(col) * scene.handlerCellSize
                let y = scene.handlerOffsetY + CGFloat(row) * scene.handlerCellSize
                
                if location.x > x && location.x < x + scene.handlerCellSize &&
                   location.y > y && location.y < y + scene.handlerCellSize {
                    
                    // 检查是否可以下棋
                    if let handler = scene.currentHandler,
                       handler.canMakeMove(at: index, in: scene) {
                        handler.handleMove(at: index, in: scene)
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    func handleLongPress(at location: CGPoint, in scene: GameScene) {
        guard scene.handlerGameLogic.gameState == .playing else { return }
        
        // 检查是否长按在格子上
        let boardSize = scene.handlerGameLogic.getBoardSize()
        for row in 0..<boardSize {
            for col in 0..<boardSize {
                let index = row * boardSize + col
                let x = scene.handlerOffsetX + CGFloat(col) * scene.handlerCellSize
                let y = scene.handlerOffsetY + CGFloat(row) * scene.handlerCellSize
                
                if location.x > x && location.x < x + scene.handlerCellSize &&
                   location.y > y && location.y < y + scene.handlerCellSize {
                    
                    // 只能移除空格子
                    if scene.handlerGameLogic.isEmpty(at: index) && 
                       !scene.handlerGameLogic.isCellRemoved(at: index) {
                        scene.removeCell(at: index)
                        return
                    }
                }
            }
        }
    }
    
    func handleDoubleTap(at location: CGPoint, in scene: GameScene) {
        // 双击触发隐藏棋盘
        scene.triggerHiddenBoard()
    }
    
    func cancelLongPress(in scene: GameScene) {
        // 取消长按定时器
        scene.cancelLongPressTimer()
    }
    
    // MARK: - 辅助方法
    private func checkButtonClicks(at location: CGPoint, in scene: GameScene) -> Bool {
        // 检查MENU按钮（左上角）
        if let backButton = scene.backButton {
            let buttonRect = createButtonRect(for: backButton, width: 120, height: 50)
            if buttonRect.contains(location) {
                scene.onBackToWelcome?()
                return true
            }
        }
        
        // 检查模式切换按钮（右上角）
        if let modeButton = scene.modeButton {
            let buttonRect = createButtonRect(for: modeButton, width: 120, height: 50)
            if buttonRect.contains(location) {
                scene.toggleGameMode()
                return true
            }
        }
        
        // 检查RESET按钮（最底下）
        if let resetButton = scene.resetButton {
            let buttonRect = createButtonRect(for: resetButton, width: 140, height: 50)
            if buttonRect.contains(location) {
                if let handler = scene.currentHandler {
                    handler.resetGame(in: scene)
                }
                return true
            }
        }
        
        return false
    }
    
    private func createButtonRect(for button: SKLabelNode, width: CGFloat, height: CGFloat) -> CGRect {
        return CGRect(
            x: button.position.x - width / 2,
            y: button.position.y - height / 2,
            width: width,
            height: height
        )
    }
}







