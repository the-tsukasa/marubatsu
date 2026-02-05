import Foundation

// MARK: - AIゴッド引擎
/// 更强的AI引擎，用于AIゴッド模式
class AIGodEngine: AIEngine {

    override func findBestMove(board: [String]) -> Int? {
        guard !board.isEmpty else { return nil }

        let boardSize = Int(sqrt(Double(board.count)))
        guard boardSize > 0 && boardSize * boardSize == board.count else {
            let availableMoves = board.enumerated().compactMap { $0.element == "" ? $0.offset : nil }
            return availableMoves.first
        }

        if boardSize == 3 {
            return findBestMoveByMinimax(board: board, boardSize: boardSize)
        }

        return super.findBestMove(board: board)
    }

    // MARK: - Minimax (3x3)
    private func findBestMoveByMinimax(board: [String], boardSize: Int) -> Int? {
        var bestScore = Int.min
        var bestMove: Int?

        for (index, mark) in board.enumerated() where mark == "" {
            var testBoard = board
            testBoard[index] = aiPlayer
            let score = minimax(
                board: testBoard,
                boardSize: boardSize,
                isMaximizing: false,
                depth: 0,
                alpha: Int.min,
                beta: Int.max
            )

            if score > bestScore {
                bestScore = score
                bestMove = index
            }
        }

        return bestMove
    }

    private func minimax(
        board: [String],
        boardSize: Int,
        isMaximizing: Bool,
        depth: Int,
        alpha: Int,
        beta: Int
    ) -> Int {
        if let winner = checkWinner(on: board, boardSize: boardSize) {
            if winner == aiPlayer {
                return 10 - depth
            }
            return depth - 10
        }

        if board.allSatisfy({ $0 != "" }) {
            return 0
        }

        var alphaValue = alpha
        var betaValue = beta

        if isMaximizing {
            var bestScore = Int.min
            for (index, mark) in board.enumerated() where mark == "" {
                var testBoard = board
                testBoard[index] = aiPlayer
                let score = minimax(
                    board: testBoard,
                    boardSize: boardSize,
                    isMaximizing: false,
                    depth: depth + 1,
                    alpha: alphaValue,
                    beta: betaValue
                )
                bestScore = max(bestScore, score)
                alphaValue = max(alphaValue, bestScore)
                if betaValue <= alphaValue {
                    break
                }
            }
            return bestScore
        } else {
            var bestScore = Int.max
            for (index, mark) in board.enumerated() where mark == "" {
                var testBoard = board
                testBoard[index] = humanPlayer
                let score = minimax(
                    board: testBoard,
                    boardSize: boardSize,
                    isMaximizing: true,
                    depth: depth + 1,
                    alpha: alphaValue,
                    beta: betaValue
                )
                bestScore = min(bestScore, score)
                betaValue = min(betaValue, bestScore)
                if betaValue <= alphaValue {
                    break
                }
            }
            return bestScore
        }
    }

    private func checkWinner(on board: [String], boardSize: Int) -> String? {
        let winningLines = getWinningLines(for: boardSize)
        for line in winningLines {
            guard line.allSatisfy({ $0 >= 0 && $0 < board.count }) else {
                continue
            }
            let a = line[0]
            let b = line[1]
            let c = line[2]
            let mark = board[a]
            if mark != "" && mark == board[b] && mark == board[c] {
                return mark
            }
        }
        return nil
    }
}
