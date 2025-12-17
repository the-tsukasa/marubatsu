import SpriteKit
import UIKit

class WelcomeScene: SKScene {

    // MARK: - Properties
    private var startButton: SKNode?
    var onStartGame: (() -> Void)?
    
    // 屏幕安全区域（适配刘海屏/灵动岛）
    private var safeAreaTop: CGFloat = 0
    private var safeAreaBottom: CGFloat = 0
    
    // 核心假设：所有素材原图都是 1024x1024
    private let assetOriginalSize: CGFloat = 1024.0

    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        if let window = view.window {
            safeAreaTop = window.safeAreaInsets.top
            safeAreaBottom = window.safeAreaInsets.bottom
        }
        setupScene()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        // 屏幕尺寸改变时重新布局（自动处理旋转或启动时的尺寸变化）
        setupScene()
    }
    
    // MARK: - Setup Orchestration
    private func setupScene() {
        // 【关键修复】防止重影：无论何时调用此方法，先清空场景
        removeAllChildren()
        
        setupBackground()
        setupGridBackground()
        
        // 1. 布局：计算位置和大小
        let (maruTitle, batsuTitle, taisenTitle) = setupTitleNodes()
        let (heroMaru, heroBatsu) = setupHeroNodes()
        let btnContainer = setupButtonNodes()
        
        // 2. 动画：执行 "Juicy" 入场序列
        runEntranceSequence(
            titles: (maruTitle, batsuTitle, taisenTitle),
            heroes: (heroMaru, heroBatsu),
            button: btnContainer
        )
    }
    
    // MARK: - Helper: 动态缩放计算器
    /// 根据想要占用的屏幕宽度百分比，计算 1024px 素材所需的缩放值
    private func calculateScale(targetScreenPercentage: CGFloat) -> CGFloat {
        let targetWidthInPoints = size.width * targetScreenPercentage
        // 缩放值 = 目标点数宽度 / 原图像素宽度
        return targetWidthInPoints / assetOriginalSize
    }

    // MARK: - 1. 背景 & 网格
    private func setupBackground() {
        backgroundColor = .black
    }

    private func setupGridBackground() {
        let grid = SKSpriteNode(imageNamed: "ground_grid")
        // 使用 aspectFill 保证网格铺满屏幕且不变形
        let ratio = max(size.width / grid.size.width, size.height / grid.size.height)
        grid.setScale(ratio)
        grid.position = CGPoint(x: size.width / 2, y: size.height / 2)
        grid.zPosition = 0
        grid.alpha = 0.5 // 稍微降低透明度，突出前景
        addChild(grid)
    }

    // MARK: - 2. 标题 (顶部布局)
    private func setupTitleNodes() -> (SKSpriteNode, SKSpriteNode, SKSpriteNode) {
        // 目标：每个标题图标占屏幕宽度的 35%
        let titleScale = calculateScale(targetScreenPercentage: 0.35)
        
        let imgMaru = SKSpriteNode(imageNamed: "title_maru")
        let imgBatsu = SKSpriteNode(imageNamed: "title_batsu")
        let imgTaisen = SKSpriteNode(imageNamed: "title_taisen")
        
        [imgMaru, imgBatsu, imgTaisen].forEach {
            $0.setScale(titleScale)
            $0.zPosition = 200
        }
        
        // 计算实际显示尺寸
        let displaySize = imgMaru.size.height
        
        // 布局：基于安全区域顶部的垂直定位
        let topAnchorY = size.height - safeAreaTop - (size.height * 0.15)
        
        let finalYMaru = topAnchorY
        let finalYBatsu = topAnchorY
        // Taisen 在 Maru/Batsu 下方
        let finalYTaisen = topAnchorY - displaySize - (displaySize * -0.3)
        
        // 水平布局
        let centerX = size.width / 2
        let horizontalOffset = displaySize * 0.50 // 图标之间的间距

        let startY = size.height + 400 // 屏幕外起始点 (稍微抬高一点，给加速留空间)
        
        imgMaru.position = CGPoint(x: centerX - horizontalOffset, y: startY)
        imgBatsu.position = CGPoint(x: centerX + horizontalOffset, y: startY)
        imgTaisen.position = CGPoint(x: centerX, y: startY)
        
        // 保存最终位置供动画使用
        imgMaru.userData = ["finalY": finalYMaru]
        imgBatsu.userData = ["finalY": finalYBatsu]
        imgTaisen.userData = ["finalY": finalYTaisen]
        
        addChild(imgMaru)
        addChild(imgBatsu)
        addChild(imgTaisen)
        
        return (imgMaru, imgBatsu, imgTaisen)
    }

    // MARK: - 3. 英雄 (中心布局)
    private func setupHeroNodes() -> (SKSpriteNode, SKSpriteNode) {
        // 目标：每个英雄占屏幕宽度的 32%，但在大屏上设上限
        var targetScale = calculateScale(targetScreenPercentage: 0.32)
        let maxHeroSize: CGFloat = 300.0
        if (assetOriginalSize * targetScale) > maxHeroSize {
            targetScale = maxHeroSize / assetOriginalSize
        }
        
        let heroY = size.height * 0.38 // 居中偏下
        let centerX = size.width / 2
        
        // 英雄之间的间距
        let spacing = size.width * 0.25
        
        // 丸 (左侧)
        let maru = SKSpriteNode(imageNamed: "maru-hero")
        maru.setScale(targetScale)
        // 初始位置在屏幕左外
        maru.position = CGPoint(x: -maru.size.width * 1.5, y: heroY)
        maru.zPosition = 100
        maru.userData = ["finalX": centerX - spacing]
        
        // 罚 (右侧)
        let batsu = SKSpriteNode(imageNamed: "batsu-hero")
        batsu.setScale(targetScale)
        // 初始位置在屏幕右外
        batsu.position = CGPoint(x: size.width + batsu.size.width * 1.5, y: heroY)
        batsu.zPosition = 100
        batsu.userData = ["finalX": centerX + spacing]
        
        addChild(maru)
        addChild(batsu)
        
        return (maru, batsu)
    }

    // MARK: - 4. 按钮 (底部布局)
    private func setupButtonNodes() -> SKNode {
        // 目标：单个按钮图片占屏幕宽度的 18%
        let buttonImgScale = calculateScale(targetScreenPercentage: 0.18)
        
        let container = SKNode()
        
        // 布局：基于安全区域底部的垂直定位
        let bottomAnchorY = safeAreaBottom + (size.height * 0.12)
        container.position = CGPoint(x: size.width / 2, y: bottomAnchorY)
        container.zPosition = 200
        container.setScale(0) // 初始状态不可见
        
        let btnPress = SKSpriteNode(imageNamed: "btn_press")
        let btnStart = SKSpriteNode(imageNamed: "btn_start")
        
        btnPress.setScale(buttonImgScale)
        btnStart.setScale(buttonImgScale)
        
        // 两个图片之间的间距
        let spacingX: CGFloat = btnPress.size.width * 0.1
        
        btnPress.position = CGPoint(x: -btnStart.size.width/2 - spacingX, y: 0)
        btnStart.position = CGPoint(x: btnPress.size.width/2 + spacingX, y: 0)
        
        container.addChild(btnPress)
        container.addChild(btnStart)
        addChild(container)
        
        self.startButton = container
        
        // 按钮内部持续闪烁动画
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.6, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        btnStart.run(SKAction.repeatForever(blink))
        
        // 将最终的 scale 存下来
        container.userData = ["finalScale": CGFloat(1.0)]
        
        return container
    }
    
    // MARK: - 高级动画 Helper Methods (Juice Effects)
    
    /// 模拟物体落地的弹性变形 (Q弹效果: 变扁 -> 拉长 -> 恢复)
    private func runElasticImpact(on node: SKNode, duration: TimeInterval = 0.2) {
        // 1. 落地瞬间：变扁 (Y轴压缩，X轴拉伸)
        let squash = SKAction.group([
            SKAction.scaleX(to: node.xScale * 1.3, duration: duration * 0.3),
            SKAction.scaleY(to: node.yScale * 0.7, duration: duration * 0.3)
        ])
        
        // 2. 反弹：变长 (Y轴拉伸，X轴压缩)
        let stretch = SKAction.group([
            SKAction.scaleX(to: node.xScale * 0.9, duration: duration * 0.3),
            SKAction.scaleY(to: node.yScale * 1.1, duration: duration * 0.3)
        ])
        
        // 3. 恢复原状
        let recover = SKAction.group([
            SKAction.scaleX(to: node.xScale * 1.0, duration: duration * 0.4),
            SKAction.scaleY(to: node.yScale * 1.0, duration: duration * 0.4)
        ])
        
        node.run(SKAction.sequence([squash, stretch, recover]))
    }

    /// 模拟重击震屏效果 (随机抖动所有子节点)
    private func shakeScreen(intensity: CGFloat = 15.0, duration: TimeInterval = 0.3) {
        let numberOfShakes = Int(duration / 0.02)
        var actions: [SKAction] = []
        
        // 创建一组随机位移动作
        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity...intensity)
            let shake = SKAction.moveBy(x: dx, y: dy, duration: 0.02)
            let returnPos = shake.reversed() // 立即归位
            actions.append(SKAction.sequence([shake, returnPos]))
        }
        let shakeSequence = SKAction.sequence(actions)
        
        // 应用到主要层级 (避免震动 startButton 导致点击问题，或者全屏震动更带感)
        // 这里我们选择震动背景和网格，制造环境震动的错觉
        self.children.forEach { node in
            // 排除闪光层 (Name 标记)
            if node.name != "flashNode" {
                node.run(shakeSequence)
            }
        }
    }
    
    /// 白屏闪光效果 (高光冲击)
    private func flashScreenWhite() {
        let flashNode = SKSpriteNode(color: .white, size: self.size)
        flashNode.position = CGPoint(x: size.width/2, y: size.height/2)
        flashNode.zPosition = 1000 // 确保在最上层
        flashNode.name = "flashNode"
        flashNode.alpha = 0
        addChild(flashNode)
        
        flashNode.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.05), // 瞬间变亮
            SKAction.fadeAlpha(to: 0.0, duration: 0.25), // 快速消散
            SKAction.removeFromParent()
        ]))
    }
    
    // MARK: - 动画编排 (Pro Version: Juicy & Dynamic)
    private func runEntranceSequence(titles: (SKSpriteNode, SKSpriteNode, SKSpriteNode),
                                     heroes: (SKSpriteNode, SKSpriteNode),
                                     button: SKNode) {
        
        // --- A. 标题掉落 (Maru & Batsu) - 果冻感 ---
        let dropSound = SKAction.playSoundFileNamed("drop.wav", waitForCompletion: false)
        
        func playJellyDrop(node: SKSpriteNode, targetY: CGFloat, delay: TimeInterval) {
            // 初始状态：拉长一点，感觉像在重力加速往下冲
            node.yScale = node.yScale * 1.2
            node.xScale = node.xScale * 0.9
            
            let wait = SKAction.wait(forDuration: delay)
            // 极速下落
            let fall = SKAction.moveTo(y: targetY, duration: 0.35)
            fall.timingMode = .easeIn
            
            // 组合动作
            let sequence = SKAction.sequence([
                wait,
                dropSound,
                fall,
                SKAction.run { [weak self] in
                    // 落地瞬间调用挤压变形 (Helper)
                    self?.runElasticImpact(on: node)
                }
            ])
            node.run(sequence)
        }
        
        if let y1 = titles.0.userData?["finalY"] as? CGFloat {
            playJellyDrop(node: titles.0, targetY: y1, delay: 0.0)
        }
        
        if let y2 = titles.1.userData?["finalY"] as? CGFloat {
            playJellyDrop(node: titles.1, targetY: y2, delay: 0.2) // 稍微错开
        }
        
        // --- B. 中间标题 (Taisen) - 重磅轰击 ---
        if let y3 = titles.2.userData?["finalY"] as? CGFloat {
            // 初始放大，像从天而降的巨石
            titles.2.setScale(titles.2.xScale * 1.5)
            titles.2.alpha = 0
            
            let wait = SKAction.wait(forDuration: 0.5)
            let appear = SKAction.fadeAlpha(to: 1.0, duration: 0.0)
            
            // 强力砸下
            let slam = SKAction.moveTo(y: y3, duration: 0.2)
            slam.timingMode = .easeIn
            
            // 砸下同时缩小回正常尺寸 (增加视觉冲击)
            let scaleDown = SKAction.scale(to: calculateScale(targetScreenPercentage: 0.35), duration: 0.2)
            
            let impactGroup = SKAction.group([slam, scaleDown])
            
            titles.2.run(SKAction.sequence([
                wait,
                appear,
                impactGroup,
                SKAction.run { [weak self] in
                    // 播放重击音效 (如有 boom.wav 更好，这里复用 drop)
                    // self?.run(SKAction.playSoundFileNamed("boom.wav", waitForCompletion: false))
                    
                    // 触发震屏 + 闪光
                    self?.shakeScreen(intensity: 20, duration: 0.4)
                    self?.flashScreenWhite()
                }
            ]))
        }
        
        // --- C. 英雄入场 - 急刹车效果 ---
        let slideSound = SKAction.playSoundFileNamed("slide.wav", waitForCompletion: false)
        
        func playDashEntry(node: SKSpriteNode, targetX: CGFloat, isLeft: Bool, delay: TimeInterval) {
            let wait = SKAction.wait(forDuration: delay)
            
            // 1. 冲刺阶段：身体前倾 (旋转)
            let originalRotation = node.zRotation
            // 左边进往右倾(-)，右边进往左倾(+)
            let dashRotation = isLeft ? CGFloat(-0.2) : CGFloat(0.2)
            
            node.zRotation = dashRotation
            
            // 移动稍微冲过头 (Overshoot)
            let direction: CGFloat = isLeft ? 1.0 : -1.0
            let overshootX = targetX + (40.0 * direction)
            
            let dash = SKAction.moveTo(x: overshootX, duration: 0.4)
            dash.timingMode = .easeOut
            
            // 2. 刹车阶段：回弹 + 恢复旋转 + 挤压
            let brakeGroup = SKAction.group([
                SKAction.moveTo(x: targetX, duration: 0.3), // 回到正确位置
                SKAction.rotate(toAngle: originalRotation, duration: 0.3), // 旋转回正
                // 刹车时的挤压感 (横向变扁，纵向拉长 -> 模拟惯性)
                SKAction.sequence([
                    SKAction.scaleX(to: node.xScale * 0.9, y: node.yScale * 1.05, duration: 0.1),
                    SKAction.scaleX(to: node.xScale * 1.0, y: node.yScale * 1.0, duration: 0.2)
                ])
            ])
            brakeGroup.timingMode = .easeOut
            
            node.run(SKAction.sequence([
                wait,
                slideSound,
                dash,
                brakeGroup,
                SKAction.run { [weak self] in
                    // 动作做完后，转入原本的待机呼吸
                    self?.addIdleAnimation(to: node)
                }
            ]))
        }
        
        // 注意：这里需要考虑 setupHeroNodes 里可能被 clamp 过的 scale
        // 为了安全起见，我们直接使用 node 当前的 scale (因为 setupHeroNodes 已经设置好了)
        // playDashEntry 内部是基于 node.xScale 相对计算的，所以不需要重置
        
        if let x1 = heroes.0.userData?["finalX"] as? CGFloat {
            playDashEntry(node: heroes.0, targetX: x1, isLeft: true, delay: 0.8)
        }
        
        if let x2 = heroes.1.userData?["finalX"] as? CGFloat {
            playDashEntry(node: heroes.1, targetX: x2, isLeft: false, delay: 0.9)
        }
        
        // --- D. 按钮 - 弹簧高光出现 ---
        let btnFinalScale = button.userData?["finalScale"] as? CGFloat ?? 1.0
        button.setScale(0)
        button.zRotation = -0.3 // 初始歪一点
        
        let btnWait = SKAction.wait(forDuration: 1.4)
        let btnPopSound = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: false)
        
        // 弹簧曲线：放大过头 + 旋转过头 -> 缩小 -> 回正
        let springAction = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: btnFinalScale * 1.2, duration: 0.2),
                SKAction.rotate(toAngle: 0.1, duration: 0.2)
            ]),
            SKAction.group([
                SKAction.scale(to: btnFinalScale * 0.95, duration: 0.15),
                SKAction.rotate(toAngle: -0.05, duration: 0.15)
            ]),
            SKAction.group([
                SKAction.scale(to: btnFinalScale, duration: 0.15),
                SKAction.rotate(toAngle: 0, duration: 0.15)
            ])
        ])
        
        button.run(SKAction.sequence([
            btnWait,
            btnPopSound,
            springAction,
            SKAction.run {
                // 开始上下浮动 (待机)
                let float = SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 6, duration: 1.2),
                    SKAction.moveBy(x: 0, y: -6, duration: 1.2)
                ])
                float.timingMode = .easeInEaseOut
                button.run(SKAction.repeatForever(float))
            }
        ]))
    }
    
    // MARK: - 待机动画 helper (呼吸)
    private func addIdleAnimation(to node: SKNode) {
        // 获取当前的缩放值，基于此进行呼吸
        let currentScaleX = node.xScale
        let currentScaleY = node.yScale
        
        let breathe = SKAction.sequence([
            SKAction.scaleX(to: currentScaleX * 1.03, y: currentScaleY * 1.03, duration: 1.5),
            SKAction.scaleX(to: currentScaleX * 1.0, y: currentScaleY * 1.0, duration: 1.5)
        ])
        breathe.timingMode = .easeInEaseOut
        
        // 随机延迟，避免所有角色同步呼吸，看起来更自然
        let randomDelay = SKAction.wait(forDuration: Double.random(in: 0...0.5))
        node.run(SKAction.sequence([randomDelay, SKAction.repeatForever(breathe)]))
    }

    // MARK: - Touch Events
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let location = t.location(in: self)

        if let btn = startButton {
            // 扩大点击区域 (+30pt)
            let hitFrame = btn.calculateAccumulatedFrame().insetBy(dx: -30, dy: -30)
            
            if hitFrame.contains(location) {
                // 点击反馈：快速收缩再弹回
                btn.run(SKAction.sequence([
                    SKAction.scale(to: 0.9, duration: 0.1),
                    SKAction.scale(to: 1.0, duration: 0.1)
                ])) { [weak self] in
                    self?.onStartGame?()
                }
            }
        }
    }
}
