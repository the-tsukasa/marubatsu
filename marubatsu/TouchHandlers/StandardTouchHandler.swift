import SpriteKit
import Foundation

// MARK: - 标准触摸处理器（双人模式和AI模式）
class StandardTouchHandler: TouchHandler {
    let gameMode: GameMode
    
    init(gameMode: GameMode) {
        self.gameMode = gameMode
    }
    
    func handleTouch(at location: CGPoint, in scene: GameScene) -> Bool {
        // 检查按钮点击
        if checkButtonClicks(at: location, in: scene) {
            return true
        }
        
        // 游戏结束时不允许下棋
        guard scene.handlerGameLogic.gameState == .playing else {
            return false
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
        // 标准模式不支持长按
    }
    
    func handleDoubleTap(at location: CGPoint, in scene: GameScene) {
        // 标准模式不支持双击
    }
    
    func cancelLongPress(in scene: GameScene) {
        // 标准模式不需要取消长按
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




