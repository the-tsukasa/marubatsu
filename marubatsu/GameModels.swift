import Foundation

// MARK: - 游戏常量配置
/// 游戏相关的常量配置
struct GameConstants {
    /// 棋盘大小（3x3）
    static let boardSize = 3
    /// 总格子数
    static let totalCells = 9
    /// 最小格子尺寸
    static let minCellSize: CGFloat = 80
    /// 最大格子尺寸
    static let maxCellSize: CGFloat = 140
    /// 棋盘线宽度
    static let lineWidth: CGFloat = 6
    /// 标记线宽度
    static let markLineWidth: CGFloat = 8
    /// 标记内边距比例（相对于格子尺寸）
    static let markPaddingRatio: CGFloat = 0.15
    /// 状态标签字体大小
    static let statusFontSize: CGFloat = 32
    /// 结果标签字体大小
    static let resultFontSize: CGFloat = 44
    /// 按钮字体大小
    static let buttonFontSize: CGFloat = 28
}

// MARK: - 游戏模式
/// 游戏模式枚举
enum GameMode {
    /// 双人对战模式
    case twoPlayer
    /// AI对战模式（玩家先手）
    case vsAI
    /// AIゴッド模式（可以在缩小棋盘和棋盘外放置棋子）
    case vsAIGod
}

// MARK: - 游戏状态
/// 游戏状态枚举
enum GameState: Equatable {
    /// 游戏中
    case playing
    /// 有玩家获胜（参数为获胜玩家标记）
    case won(String)
    /// 平局
    case draw
    
    /// 实现 Equatable 协议
    static func == (lhs: GameState, rhs: GameState) -> Bool {
        switch (lhs, rhs) {
        case (.playing, .playing):
            return true
        case (.won(let lhsPlayer), .won(let rhsPlayer)):
            return lhsPlayer == rhsPlayer
        case (.draw, .draw):
            return true
        default:
            return false
        }
    }
}



