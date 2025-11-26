import SpriteKit
import UIKit

class WelcomeScene: SKScene {

    private var startButton: SKNode?

    var onStartGame: (() -> Void)?

    override func didMove(to view: SKView) {
        setupBackground()
        setupGridBackground()
        setupTitleImages()
        setupHeroes()
        setupStartButtonImages()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        removeAllChildren()
        setupBackground()
        setupGridBackground()
        setupTitleImages()
        setupHeroes()
        setupStartButtonImages()
    }

    // MARK: - 背景
    private func setupBackground() {
        backgroundColor = .black
    }

    // MARK: - 地板背景
    private func setupGridBackground() {
        let grid = SKSpriteNode(imageNamed: "ground_grid")
        grid.size = CGSize(width: size.width, height: size.height)
        grid.position = CGPoint(x: size.width / 2, y: size.height / 2)
        grid.zPosition = 0
        addChild(grid)
    }

    // MARK: - 标题图片 (缩小为 10% + 入场动画)
    private func setupTitleImages() {

        let scale: CGFloat = 0.10

        let imgMaru = SKSpriteNode(imageNamed: "title_maru")
        let imgBatsu = SKSpriteNode(imageNamed: "title_batsu")
        let imgTaisen = SKSpriteNode(imageNamed: "title_taisen")

        imgMaru.setScale(scale)
        imgBatsu.setScale(scale)
        imgTaisen.setScale(scale)

        let spacingY: CGFloat = 10 * scale
        let baseY = size.height * 0.82

        // 最终位置
        let finalYMaru = baseY
        let finalYBatsu = baseY
        let finalYTaisen = baseY - imgMaru.size.height - spacingY

        imgMaru.position = CGPoint(x: size.width/2 - imgMaru.size.width*0.55, y: finalYMaru)
        imgBatsu.position = CGPoint(x: size.width/2 + imgBatsu.size.width*0.55, y: finalYBatsu)
        imgTaisen.position = CGPoint(x: size.width/2, y: finalYTaisen)

        imgMaru.zPosition = 200
        imgBatsu.zPosition = 200
        imgTaisen.zPosition = 200

        // 初始从屏幕顶部外部开始
        let startY = size.height + 200
        [imgMaru, imgBatsu, imgTaisen].forEach {
            $0.alpha = 0
            $0.position.y = startY
            self.addChild($0)
        }

        // 入场动画函数（带音效和循环）
        func drop(_ node: SKSpriteNode, toY: CGFloat, delay: Double) {
            // 音效（如果文件存在，静默失败）
            let soundAction = SKAction.playSoundFileNamed("drop.wav", waitForCompletion: false)
            
            let dropAnimation = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                soundAction, // 播放音效
                SKAction.group([
                    SKAction.fadeIn(withDuration: 0.25),
                    SKAction.moveTo(y: toY, duration: 0.30)
                ]),
                // 像素抖动
                SKAction.sequence([
                    SKAction.moveBy(x: 0, y: -6, duration: 0.08),
                    SKAction.moveBy(x: 0, y: 6, duration: 0.08),
                    SKAction.moveBy(x: 0, y: -3, duration: 0.08),
                    SKAction.moveBy(x: 0, y: 3, duration: 0.08)
                ]),
                SKAction.wait(forDuration: 2.0), // 等待2秒
                // 重置位置和透明度，准备下一次循环
                SKAction.run { [node, startY] in
                    node.alpha = 0
                    node.position.y = startY
                },
                SKAction.wait(forDuration: 0.1) // 短暂延迟
            ])
            
            // 循环播放动画
            node.run(SKAction.repeatForever(dropAnimation))
        }

        drop(imgMaru, toY: finalYMaru, delay: 0.10)
        drop(imgBatsu, toY: finalYBatsu, delay: 0.25)
        drop(imgTaisen, toY: finalYTaisen, delay: 0.40)
    }

    // MARK: - 英雄
    private func setupHeroes() {

        let baseHeroSize: CGFloat = 150
        let scaleFactor = min(size.width / 375, size.height / 667)
        let heroSize = baseHeroSize * min(scaleFactor, 1.1)

        let y = size.height * 0.50 - heroSize * 0.6
        let spacing = size.width * 0.20
        let center = size.width / 2

        let maru = SKSpriteNode(imageNamed: "maru-hero")
        maru.size = CGSize(width: heroSize, height: heroSize)
        let maruFinalX = center - spacing
        maru.position = CGPoint(x: -heroSize, y: y)
        maru.alpha = 0
        maru.setScale(0.5)
        maru.zPosition = 100

        let batsu = SKSpriteNode(imageNamed: "batsu-hero")
        batsu.size = CGSize(width: heroSize, height: heroSize)
        let batsuFinalX = center + spacing
        batsu.position = CGPoint(x: size.width + heroSize, y: y)
        batsu.alpha = 0
        batsu.setScale(0.5)
        batsu.zPosition = 100

        addChild(maru)
        addChild(batsu)

        // 入场动画（带音效和循环）
        let slideSound = SKAction.playSoundFileNamed("slide.wav", waitForCompletion: false)
        let bounceSound = SKAction.playSoundFileNamed("bounce.wav", waitForCompletion: false)
        
        let maruEntrance = SKAction.sequence([
            slideSound, // 滑入音效
            SKAction.group([
                SKAction.moveTo(x: maruFinalX, duration: 0.8),
                SKAction.fadeIn(withDuration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ]),
            bounceSound, // 弹跳音效
            SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]),
            SKAction.wait(forDuration: 3.0), // 等待3秒
            // 重置位置和状态，准备下一次循环
            SKAction.run { [weak maru, heroSize] in
                maru?.alpha = 0
                maru?.setScale(0.5)
                maru?.position.x = -heroSize
            },
            SKAction.wait(forDuration: 0.1) // 短暂延迟
        ])
        
        let batsuEntrance = SKAction.sequence([
            SKAction.wait(forDuration: 0.2),
            slideSound, // 滑入音效
            SKAction.group([
                SKAction.moveTo(x: batsuFinalX, duration: 0.8),
                SKAction.fadeIn(withDuration: 0.8),
                SKAction.scale(to: 1.0, duration: 0.8)
            ]),
            bounceSound, // 弹跳音效
            SKAction.sequence([
                SKAction.scale(to: 1.1, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ]),
            SKAction.wait(forDuration: 3.0), // 等待3秒
            // 重置位置和状态，准备下一次循环
            SKAction.run { [weak batsu, sceneWidth = self.size.width, heroSize] in
                batsu?.alpha = 0
                batsu?.setScale(0.5)
                batsu?.position.x = sceneWidth + heroSize
            },
            SKAction.wait(forDuration: 0.1) // 短暂延迟
        ])
        
        // 循环播放动画
        maru.run(SKAction.repeatForever(maruEntrance))
        batsu.run(SKAction.repeatForever(batsuEntrance))
    }

    // MARK: - 按钮图片 (合并为一个按钮 + 弹跳出现 + 浮动 + 闪烁 + 循环动画)
    private func setupStartButtonImages() {

        let scale: CGFloat = 0.10

        // 创建容器节点，合并两个按钮为一个
        let buttonContainer = SKNode()
        buttonContainer.position = CGPoint(x: size.width / 2, y: size.height * 0.12)
        buttonContainer.zPosition = 200

        let btnPress = SKSpriteNode(imageNamed: "btn_press")
        let btnStart = SKSpriteNode(imageNamed: "btn_start")

        btnPress.setScale(scale)
        btnStart.setScale(scale)

        let spacingX: CGFloat = 25 * scale

        // 将两个按钮添加到容器中
        btnPress.position = CGPoint(
            x: -btnStart.size.width/2 - spacingX,
            y: 0
        )
        btnStart.position = CGPoint(
            x: btnPress.size.width/2 + spacingX,
            y: 0
        )

        buttonContainer.addChild(btnPress)
        buttonContainer.addChild(btnStart)

        // 初始状态
        buttonContainer.alpha = 0
        buttonContainer.setScale(0.01)

        addChild(buttonContainer)
        startButton = buttonContainer

        // 弹跳入场动画（带音效和循环）
        let popSound = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
        
        let popInAnimation = SKAction.sequence([
            SKAction.wait(forDuration: 0.9),
            popSound, // 播放音效
            SKAction.group([
                SKAction.fadeIn(withDuration: 0.25),
                SKAction.scale(to: scale, duration: 0.25)
            ]),
            SKAction.sequence([
                SKAction.scale(to: scale * 1.2, duration: 0.10),
                SKAction.scale(to: scale, duration: 0.10)
            ]),
            SKAction.wait(forDuration: 2.0), // 等待2秒
            // 重置状态，准备下一次循环
            SKAction.run { [weak buttonContainer, scale] in
                buttonContainer?.alpha = 0
                buttonContainer?.setScale(0.01)
            },
            SKAction.wait(forDuration: 0.1) // 短暂延迟
        ])
        
        // 循环播放入场动画
        buttonContainer.run(SKAction.repeatForever(popInAnimation))

        // START 闪烁（循环）- 只在按钮显示时闪烁
        let fade = SKAction.sequence([
            SKAction.wait(forDuration: 0.9 + 0.25 + 0.2), // 等待入场动画完成
            SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.6),
                SKAction.fadeAlpha(to: 1.0, duration: 0.6)
            ]))
        ])
        btnStart.run(fade)

        // 上下浮动动画（持续循环）- 使用相对位置移动，不受重置影响
        let float = SKAction.sequence([
            SKAction.wait(forDuration: 1.4), // 等待入场动画完成
            SKAction.repeatForever(SKAction.sequence([
                SKAction.moveBy(x: 0, y: 5, duration: 1.0),
                SKAction.moveBy(x: 0, y: -5, duration: 1.0)
            ]))
        ])
        buttonContainer.run(float, withKey: "float")
    }

    // MARK: - 点击事件
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let location = t.location(in: self)

        if let btn = startButton, btn.contains(location) {
            btn.run(SKAction.sequence([
                SKAction.scale(to: 0.85, duration: 0.1),
                SKAction.scale(to: 1.0, duration: 0.1)
            ])) {
                self.onStartGame?()
            }
        }
    }
}
