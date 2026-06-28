import SwiftUI

/// 等距场景 Canvas 渲染 — 视觉重写版
struct SceneCanvasView: View {
    let variant: SceneVariant
    let dog: Dog
    let isFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { timeline in
                Canvas { context, size in
                    drawScene(context: &context, size: size, time: timeline.date)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .background(AppColors.creamBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func drawScene(context: inout GraphicsContext, size: CGSize, time: Date) {
        let layout = variant.layout
        let t = time.timeIntervalSinceReferenceDate

        // 计算原点（场景中心偏上）
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.32)

        // 1. 绘制地板
        drawFloor(context: &context, origin: origin, gridSize: layout.gridSize, floorColor: layout.floorColor)

        // 2. 绘制墙壁
        if let wallColor = layout.wallColor {
            drawWalls(context: &context, origin: origin, gridSize: layout.gridSize, wallColor: wallColor)
        }

        // 3. 收集绘制物件，按 y 排序
        enum Drawable {
            case furniture(FurnitureItem)
            case dog
        }
        var drawables: [(y: CGFloat, kind: Drawable)] = []

        for furniture in layout.furniture {
            let pos = IsometricHelpers.cartesianToIsometric(
                x: furniture.position.x, y: furniture.position.y, origin: origin
            )
            drawables.append((y: pos.y, kind: .furniture(furniture)))
        }

        let dogGrid = variant.resolvedDogPosition()
        let dogScreenPos = IsometricHelpers.cartesianToIsometric(
            x: dogGrid.x, y: dogGrid.y, origin: origin
        )
        drawables.append((y: dogScreenPos.y, kind: .dog))

        drawables.sort { $0.y < $1.y }
        for item in drawables {
            switch item.kind {
            case .furniture(let furniture):
                drawFurniture(context: &context, origin: origin, furniture: furniture, time: time)
            case .dog:
                drawDog(context: &context, origin: origin, dogGridPos: dogGrid, time: time)
            }
        }

        // 4. 可交互道具
        for prop in variant.interactiveProps {
            drawProp(context: &context, origin: origin, prop: prop, time: time)
        }

        // 5. 氛围粒子（阳光灰尘 / 夜晚星星）
        drawAmbientParticles(context: &context, origin: origin, size: size, time: time)

        // 6. 时段光照叠加
        drawTimeOverlay(context: &context, size: size, time: time)

        // 7. 场景信息
        drawSceneInfo(context: &context, size: size, layout: layout)
    }

    // MARK: - 地板（带木纹/瓷砖纹理）

    private func drawFloor(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, floorColor: String) {
        let baseColor = Color(hex: floorColor)

        for x in 0...gridSize.width {
            for y in 0...gridSize.height {
                let point = IsometricHelpers.cartesianToIsometric(x: x, y: y, origin: origin)
                let tw = IsometricHelpers.tileWidth
                let th = IsometricHelpers.tileHeight

                var path = Path()
                path.move(to: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x + tw / 2, y: point.y + th / 2))
                path.addLine(to: CGPoint(x: point.x, y: point.y + th))
                path.addLine(to: CGPoint(x: point.x - tw / 2, y: point.y + th / 2))
                path.closeSubpath()

                // 棋盘交替 + 微妙渐变
                let isAlternate = (x + y) % 2 == 0
                let alpha = isAlternate ? 0.45 : 0.30
                context.fill(path, with: .color(baseColor.opacity(alpha)))

                // 瓦片边缘高光（顶部两条边稍亮）
                var highlightPath = Path()
                highlightPath.move(to: CGPoint(x: point.x, y: point.y))
                highlightPath.addLine(to: CGPoint(x: point.x + tw / 2, y: point.y + th / 2))
                context.stroke(highlightPath, with: .color(.white.opacity(0.08)), lineWidth: 1)

                context.stroke(path, with: .color(baseColor.opacity(0.5)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - 墙壁（带踢脚线）

    private func drawWalls(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, wallColor: String) {
        let color = Color(hex: wallColor)
        let wallHeight: CGFloat = 50

        // 后墙
        for x in 0..<gridSize.width {
            let start = IsometricHelpers.cartesianToIsometric(x: x, y: 0, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: x + 1, y: 0, origin: origin)

            var wallPath = Path()
            wallPath.move(to: start)
            wallPath.addLine(to: end)
            wallPath.addLine(to: CGPoint(x: end.x, y: end.y - wallHeight))
            wallPath.addLine(to: CGPoint(x: start.x, y: start.y - wallHeight))
            wallPath.closeSubpath()

            context.fill(wallPath, with: .color(color.opacity(0.55)))
            context.stroke(wallPath, with: .color(color.darker(by: 0.15)), lineWidth: 0.5)
        }

        // 左墙
        for y in 0..<gridSize.height {
            let start = IsometricHelpers.cartesianToIsometric(x: 0, y: y, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: 0, y: y + 1, origin: origin)

            var wallPath = Path()
            wallPath.move(to: start)
            wallPath.addLine(to: end)
            wallPath.addLine(to: CGPoint(x: end.x, y: end.y - wallHeight))
            wallPath.addLine(to: CGPoint(x: start.x, y: start.y - wallHeight))
            wallPath.closeSubpath()

            context.fill(wallPath, with: .color(color.opacity(0.35)))
            context.stroke(wallPath, with: .color(color.darker(by: 0.15)), lineWidth: 0.5)
        }

        // 踢脚线
        drawBaseboard(context: &context, origin: origin, gridSize: gridSize, wallHeight: wallHeight)
    }

    private func drawBaseboard(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, wallHeight: CGFloat) {
        let baseboardColor = Color(hex: "8B7355").opacity(0.6)
        let baseboardHeight: CGFloat = 6

        // 后墙踢脚线
        for x in 0..<gridSize.width {
            let start = IsometricHelpers.cartesianToIsometric(x: x, y: 0, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: x + 1, y: 0, origin: origin)

            var path = Path()
            path.move(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y - baseboardHeight))
            path.addLine(to: CGPoint(x: start.x, y: start.y - baseboardHeight))
            path.closeSubpath()

            context.fill(path, with: .color(baseboardColor))
        }

        // 左墙踢脚线
        for y in 0..<gridSize.height {
            let start = IsometricHelpers.cartesianToIsometric(x: 0, y: y, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: 0, y: y + 1, origin: origin)

            var path = Path()
            path.move(to: CGPoint(x: start.x, y: start.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y))
            path.addLine(to: CGPoint(x: end.x, y: end.y - baseboardHeight))
            path.addLine(to: CGPoint(x: start.x, y: start.y - baseboardHeight))
            path.closeSubpath()

            context.fill(path, with: .color(baseboardColor.opacity(0.7)))
        }
    }

    // MARK: - 家具（类型感知绘制）

    private func drawFurniture(context: inout GraphicsContext, origin: CGPoint, furniture: FurnitureItem, time: Date) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: furniture.position.x, y: furniture.position.y, origin: origin
        )

        let boxWidth = CGFloat(furniture.size.width) * IsometricHelpers.tileWidth * 0.8
        let boxHeight = CGFloat(furniture.size.height) * IsometricHelpers.tileHeight * 0.8
        let color = Color(hex: furniture.color)

        // 阴影
        drawShadow(context: &context, at: CGPoint(x: position.x + 3, y: position.y + 5),
                   width: boxWidth * 0.85, height: boxHeight * 0.45)

        // 根据家具类型绘制不同样式
        switch furniture.id {
        case "bed":
            drawBed(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "desk":
            drawDesk(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "chair":
            drawChair(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "plant":
            drawPlant(context: &context, at: position, width: boxWidth, height: boxHeight)
        case "sofa", "couch":
            drawSofa(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "bathtub", "tub":
            drawBathtub(context: &context, at: position, width: boxWidth, height: boxHeight)
        case "fridge", "refrigerator":
            drawFridge(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "stove", "oven":
            drawStove(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "bookshelf", "shelf":
            drawBookshelf(context: &context, at: position, width: boxWidth, height: boxHeight, color: color)
        case "laptop", "computer":
            drawLaptop(context: &context, at: position, width: boxWidth, height: boxHeight)
        default:
            // 通用等距盒子
            let box = IsometricBox(position: position, width: boxWidth, height: boxHeight, depth: 18, color: color)
            box.draw(in: context)
            context.draw(Text(furniture.emoji).font(.system(size: 18)), at: CGPoint(x: position.x, y: position.y - 8))
        }
    }

    // MARK: - 家具类型绘制

    private func drawBed(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        // 床架
        let box = IsometricBox(position: pos, width: width, height: height, depth: 12, color: color)
        box.draw(in: context)

        // 枕头（白色小矩形在床头）
        let pillowPos = CGPoint(x: pos.x - width * 0.25, y: pos.y - height * 0.15 - 12)
        var pillow = Path()
        pillow.addRoundedRect(in: CGRect(x: pillowPos.x - 10, y: pillowPos.y - 5, width: 20, height: 10), cornerSize: CGSize(width: 3, height: 3))
        context.fill(pillow, with: .color(Color(hex: "F5F0E8")))
        context.stroke(pillow, with: .color(Color(hex: "E0D8D0").opacity(0.5)), lineWidth: 0.5)

        // 被子折痕
        var foldPath = Path()
        foldPath.move(to: CGPoint(x: pos.x - width * 0.15, y: pos.y - height * 0.1))
        foldPath.addLine(to: CGPoint(x: pos.x + width * 0.1, y: pos.y + height * 0.05))
        context.stroke(foldPath, with: .color(color.darker(by: 0.2).opacity(0.4)), lineWidth: 1)
    }

    private func drawDesk(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        // 桌面
        let box = IsometricBox(position: pos, width: width, height: height, depth: 8, color: color)
        box.draw(in: context)

        // 显示器
        let monitorPos = CGPoint(x: pos.x, y: pos.y - height * 0.15 - 15)
        // 屏幕
        var screen = Path()
        screen.addRect(CGRect(x: monitorPos.x - 12, y: monitorPos.y - 10, width: 24, height: 16))
        context.fill(screen, with: .color(Color(hex: "2C3E50")))
        context.stroke(screen, with: .color(Color(hex: "1A252F")), lineWidth: 1)
        // 屏幕亮面
        var screenGlow = Path()
        screenGlow.addRect(CGRect(x: monitorPos.x - 10, y: monitorPos.y - 8, width: 20, height: 12))
        context.fill(screenGlow, with: .color(Color(hex: "5DADE2").opacity(0.3)))
        // 支架
        var stand = Path()
        stand.move(to: CGPoint(x: monitorPos.x - 3, y: monitorPos.y + 6))
        stand.addLine(to: CGPoint(x: monitorPos.x + 3, y: monitorPos.y + 6))
        stand.addLine(to: CGPoint(x: monitorPos.x + 2, y: monitorPos.y + 10))
        stand.addLine(to: CGPoint(x: monitorPos.x - 2, y: monitorPos.y + 10))
        stand.closeSubpath()
        context.fill(stand, with: .color(Color(hex: "7F8C8D")))
    }

    private func drawChair(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        // 座位
        let seatPos = CGPoint(x: pos.x, y: pos.y)
        var seat = Path()
        seat.addRoundedRect(in: CGRect(x: seatPos.x - 10, y: seatPos.y - 4, width: 20, height: 8), cornerSize: CGSize(width: 2, height: 2))
        context.fill(seat, with: .color(color))
        context.stroke(seat, with: .color(color.darker(by: 0.3)), lineWidth: 0.5)

        // 靠背
        var backrest = Path()
        backrest.addRoundedRect(in: CGRect(x: seatPos.x - 10, y: seatPos.y - 18, width: 20, height: 14), cornerSize: CGSize(width: 2, height: 2))
        context.fill(backrest, with: .color(color.opacity(0.85)))
        context.stroke(backrest, with: .color(color.darker(by: 0.3)), lineWidth: 0.5)

        // 腿
        for dx in [-7.0, 7.0] as [CGFloat] {
            var leg = Path()
            leg.addRect(CGRect(x: seatPos.x + dx - 1.5, y: seatPos.y + 4, width: 3, height: 8))
            context.fill(leg, with: .color(color.darker(by: 0.2)))
        }
    }

    private func drawPlant(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat) {
        // 花盆
        var pot = Path()
        pot.move(to: CGPoint(x: pos.x - 8, y: pos.y - 5))
        pot.addLine(to: CGPoint(x: pos.x + 8, y: pos.y - 5))
        pot.addLine(to: CGPoint(x: pos.x + 6, y: pos.y + 8))
        pot.addLine(to: CGPoint(x: pos.x - 6, y: pos.y + 8))
        pot.closeSubpath()
        context.fill(pot, with: .color(Color(hex: "C0784A")))
        context.stroke(pot, with: .color(Color(hex: "A06030")), lineWidth: 0.5)

        // 泥土
        var soil = Path()
        soil.addEllipse(in: CGRect(x: pos.x - 7, y: pos.y - 7, width: 14, height: 5))
        context.fill(soil, with: .color(Color(hex: "5C4033")))

        // 叶子（多层圆形模拟）
        let leafColors = [Color(hex: "4A8B3A"), Color(hex: "5CA04A"), Color(hex: "3D7A2E")]
        for (i, leafColor) in leafColors.enumerated() {
            let offset = CGFloat(i) * 3
            var leaf = Path()
            leaf.addEllipse(in: CGRect(x: pos.x - 6 + offset * 0.3, y: pos.y - 18 - offset, width: 12, height: 10))
            context.fill(leaf, with: .color(leafColor))
        }
    }

    private func drawSofa(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        // 沙发主体
        let box = IsometricBox(position: pos, width: width, height: height, depth: 14, color: color)
        box.draw(in: context)

        // 靠垫分缝线
        let seamX = pos.x
        var seam = Path()
        seam.move(to: CGPoint(x: seamX, y: pos.y - height * 0.15 - 14))
        seam.addLine(to: CGPoint(x: seamX, y: pos.y + height * 0.1))
        context.stroke(seam, with: .color(color.darker(by: 0.25).opacity(0.5)), lineWidth: 1)

        // 扶手
        for side in [-1.0, 1.0] as [CGFloat] {
            var armrest = Path()
            let armX = pos.x + side * width * 0.35
            armrest.addRoundedRect(in: CGRect(x: armX - 5, y: pos.y - height * 0.15 - 10, width: 10, height: 16), cornerSize: CGSize(width: 3, height: 3))
            context.fill(armrest, with: .color(color.opacity(0.9)))
        }
    }

    private func drawBathtub(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat) {
        // 浴缸外壁
        let box = IsometricBox(position: pos, width: width, height: height, depth: 16, color: Color(hex: "E8E8E8"))
        box.draw(in: context)

        // 水面
        var water = Path()
        water.addEllipse(in: CGRect(x: pos.x - width * 0.3, y: pos.y - height * 0.1 - 8, width: width * 0.6, height: height * 0.3))
        context.fill(water, with: .color(Color(hex: "AED6F1").opacity(0.6)))

        // 泡泡
        for i in 0..<3 {
            let bubbleX = pos.x + CGFloat(i - 1) * 8
            let bubbleY = pos.y - height * 0.15 - 5
            var bubble = Path()
            bubble.addEllipse(in: CGRect(x: bubbleX - 3, y: bubbleY - 3, width: 6, height: 6))
            context.fill(bubble, with: .color(.white.opacity(0.5)))
            context.stroke(bubble, with: .color(.white.opacity(0.3)), lineWidth: 0.5)
        }
    }

    private func drawFridge(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        let box = IsometricBox(position: pos, width: width, height: height, depth: 25, color: color)
        box.draw(in: context)

        // 门缝
        var seam = Path()
        seam.move(to: CGPoint(x: pos.x, y: pos.y - height * 0.2 - 25))
        seam.addLine(to: CGPoint(x: pos.x, y: pos.y + height * 0.1))
        context.stroke(seam, with: .color(color.darker(by: 0.2).opacity(0.4)), lineWidth: 1)

        // 把手
        var handle = Path()
        handle.addRoundedRect(in: CGRect(x: pos.x + 3, y: pos.y - 10, width: 3, height: 12), cornerSize: CGSize(width: 1, height: 1))
        context.fill(handle, with: .color(Color(hex: "C0C0C0")))
    }

    private func drawStove(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        let box = IsometricBox(position: pos, width: width, height: height, depth: 15, color: color)
        box.draw(in: context)

        // 炉灶圈
        for dx in [-6.0, 6.0] as [CGFloat] {
            var burner = Path()
            burner.addEllipse(in: CGRect(x: pos.x + dx - 5, y: pos.y - height * 0.15 - 5, width: 10, height: 5))
            context.fill(burner, with: .color(Color(hex: "2C2C2C")))
            context.stroke(burner, with: .color(Color(hex: "404040")), lineWidth: 0.5)
        }
    }

    private func drawBookshelf(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat, color: Color) {
        let box = IsometricBox(position: pos, width: width, height: height, depth: 22, color: color)
        box.draw(in: context)

        // 书（彩色小矩形）
        let bookColors = ["E74C3C", "3498DB", "2ECC71", "F39C12", "9B59B6"]
        for (i, bookColor) in bookColors.enumerated() {
            let bookX = pos.x - 10 + CGFloat(i) * 5
            let bookH = 8 + CGFloat(i % 3) * 2
            var book = Path()
            book.addRect(CGRect(x: bookX, y: pos.y - height * 0.15 - bookH, width: 4, height: bookH))
            context.fill(book, with: .color(Color(hex: bookColor)))
        }
    }

    private func drawLaptop(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat) {
        // 底座
        var base = Path()
        base.addRoundedRect(in: CGRect(x: pos.x - 14, y: pos.y - 3, width: 28, height: 6), cornerSize: CGSize(width: 1, height: 1))
        context.fill(base, with: .color(Color(hex: "BDC3C7")))
        context.stroke(base, with: .color(Color(hex: "95A5A6")), lineWidth: 0.5)

        // 屏幕（打开状态）
        var screen = Path()
        screen.move(to: CGPoint(x: pos.x - 12, y: pos.y - 3))
        screen.addLine(to: CGPoint(x: pos.x + 12, y: pos.y - 3))
        screen.addLine(to: CGPoint(x: pos.x + 10, y: pos.y - 18))
        screen.addLine(to: CGPoint(x: pos.x - 10, y: pos.y - 18))
        screen.closeSubpath()
        context.fill(screen, with: .color(Color(hex: "2C3E50")))
        context.stroke(screen, with: .color(Color(hex: "1A252F")), lineWidth: 0.5)

        // 屏幕内容
        var screenContent = Path()
        screenContent.addRect(CGRect(x: pos.x - 9, y: pos.y - 16, width: 18, height: 11))
        context.fill(screenContent, with: .color(Color(hex: "5DADE2").opacity(0.25)))
    }

    // MARK: - 狗狗（品种差异化 + 动画）

    private func drawDog(context: inout GraphicsContext, origin: CGPoint, dogGridPos: GridPosition, time: Date) {
        let pos = IsometricHelpers.cartesianToIsometric(
            x: dogGridPos.x, y: dogGridPos.y, origin: origin
        )

        let breed = dog.breed
        let bodyColor = Color(hex: breed.bodyColor)
        let accentColor = Color(hex: breed.accentColor)
        let isLarge = breed.sizeCategory == .large
        let isSmall = breed.sizeCategory == .small
        let baseScale: CGFloat = isLarge ? 1.3 : (isSmall ? 0.85 : 1.0)

        let t = time.timeIntervalSinceReferenceDate

        // 动画参数
        let breathe = sin(t * 2.5) * 0.03 + 1.0       // 呼吸
        let tailWag = sin(t * 5.0) * 0.3              // 尾巴摇摆
        let blinkPhase = sin(t * 0.8)                  // 眨眼周期
        let isBlinking = blinkPhase > 0.92             // 偶尔眨眼

        let scale = baseScale * breathe

        // 阴影
        drawShadow(context: &context, at: CGPoint(x: pos.x + 2, y: pos.y + 6),
                   width: 30 * baseScale, height: 11 * baseScale)

        // 根据品种选择绘制风格
        switch breed {
        case .corgi:
            drawCorgi(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        case .husky:
            drawHusky(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        case .bichon, .samoyed:
            drawFluffyDog(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        case .frenchBulldog:
            drawBulldog(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        case .shiba:
            drawShiba(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        default:
            drawGenericDog(context: &context, at: pos, bodyColor: bodyColor, accentColor: accentColor, scale: scale, tailWag: tailWag, isBlinking: isBlinking)
        }

        // 行为文字
        context.draw(
            Text(variant.dogAction)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary),
            at: CGPoint(x: pos.x, y: pos.y + 22 * baseScale)
        )
    }

    // MARK: - 柯基（短腿 + 长身体 + 大屁股）

    private func drawCorgi(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体（更长更扁）
        let bodyRect = CGRect(x: pos.x - 16 * scale, y: pos.y - 12 * scale, width: 32 * scale, height: 18 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))
        context.stroke(Path(ellipseIn: bodyRect), with: .color(accentColor.opacity(0.4)), lineWidth: 0.8)

        // 白色肚子
        var belly = Path()
        belly.addEllipse(in: CGRect(x: pos.x - 8 * scale, y: pos.y - 2 * scale, width: 16 * scale, height: 10 * scale))
        context.fill(belly, with: .color(Color(hex: "FFF8F0")))

        // 超短腿
        for dx in [-10.0, -3.0, 4.0, 11.0] as [CGFloat] {
            drawLeg(context: &context, at: CGPoint(x: pos.x + dx * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.5)
        }

        // 大屁股（右侧突出）
        var butt = Path()
        butt.addEllipse(in: CGRect(x: pos.x + 10 * scale, y: pos.y - 10 * scale, width: 14 * scale, height: 16 * scale))
        context.fill(butt, with: .color(bodyColor))

        // 短尾巴（竖起来摇摆）
        drawShortTail(context: &context, at: pos, color: accentColor, scale: scale, wag: tailWag)

        // 头
        let headCenter = CGPoint(x: pos.x - 12 * scale, y: pos.y - 18 * scale)
        let headRadius: CGFloat = 11 * scale
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 大耳朵（柯基标志性大耳）
        drawLargeEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 脸
        drawFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale * 0.9, isBlinking: isBlinking, eyeColor: .black)
    }

    // MARK: - 哈士奇（蓝眼 + 面具花纹）

    private func drawHusky(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体
        let bodyRect = CGRect(x: pos.x - 14 * scale, y: pos.y - 16 * scale, width: 28 * scale, height: 22 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        // 白色胸毛
        var chest = Path()
        chest.addEllipse(in: CGRect(x: pos.x - 6 * scale, y: pos.y - 6 * scale, width: 14 * scale, height: 14 * scale))
        context.fill(chest, with: .color(Color(hex: "F0F0F0")))

        // 腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 8 * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.85)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 8 * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.85)
        drawLeg(context: &context, at: CGPoint(x: pos.x - 4 * scale, y: pos.y + 5 * scale), color: Color(hex: "F0F0F0"), scale: scale * 0.85)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 5 * scale, y: pos.y + 5 * scale), color: Color(hex: "F0F0F0"), scale: scale * 0.85)

        // 蓬松尾巴（上翘）
        drawFluffyTail(context: &context, at: pos, color: accentColor, scale: scale, wag: tailWag)

        // 头
        let headCenter = CGPoint(x: pos.x + 10 * scale, y: pos.y - 22 * scale)
        let headRadius: CGFloat = 11 * scale

        // 头部底色
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 面具花纹（头顶深色，脸部白色）
        var mask = Path()
        mask.addEllipse(in: CGRect(x: headCenter.x - headRadius * 0.8, y: headCenter.y - headRadius * 0.5, width: headRadius * 1.6, height: headRadius * 1.2))
        context.fill(mask, with: .color(Color(hex: "F0F0F0")))

        // 耳朵（尖耳）
        drawPointedEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 蓝眼睛
        drawFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale * 0.9, isBlinking: isBlinking, eyeColor: Color(hex: "5DADE2"))
    }

    // MARK: - 蓬松犬（比熊/萨摩耶 — 多层圆模拟毛茸茸）

    private func drawFluffyDog(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体（多个重叠圆模拟蓬松）
        let bodyRect = CGRect(x: pos.x - 14 * scale, y: pos.y - 16 * scale, width: 28 * scale, height: 22 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        // 蓬松边缘
        for angle in stride(from: 0.0, to: 360.0, by: 30.0) {
            let rad = angle * .pi / 180
            let px = pos.x + cos(rad) * 13 * scale
            let py = pos.y + sin(rad) * 10 * scale - 5 * scale
            var puff = Path()
            puff.addEllipse(in: CGRect(x: px - 5 * scale, y: py - 5 * scale, width: 10 * scale, height: 10 * scale))
            context.fill(puff, with: .color(bodyColor.opacity(0.7)))
        }

        // 腿（被毛遮住一部分）
        drawLeg(context: &context, at: CGPoint(x: pos.x - 7 * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.7)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 7 * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.7)
        drawLeg(context: &context, at: CGPoint(x: pos.x - 3 * scale, y: pos.y + 5 * scale), color: bodyColor, scale: scale * 0.7)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 4 * scale, y: pos.y + 5 * scale), color: bodyColor, scale: scale * 0.7)

        // 蓬松尾巴
        drawFluffyTail(context: &context, at: pos, color: bodyColor, scale: scale, wag: tailWag)

        // 头（更圆）
        let headCenter = CGPoint(x: pos.x + 10 * scale, y: pos.y - 22 * scale)
        let headRadius: CGFloat = 12 * scale
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 头部蓬松
        for angle in stride(from: 0.0, to: 360.0, by: 45.0) {
            let rad = angle * .pi / 180
            let px = headCenter.x + cos(rad) * headRadius * 0.85
            let py = headCenter.y + sin(rad) * headRadius * 0.85
            var puff = Path()
            puff.addEllipse(in: CGRect(x: px - 4 * scale, y: py - 4 * scale, width: 8 * scale, height: 8 * scale))
            context.fill(puff, with: .color(bodyColor.opacity(0.6)))
        }

        // 小耳朵（被毛遮住）
        drawSmallEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 脸
        drawFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale * 0.85, isBlinking: isBlinking, eyeColor: .black)
    }

    // MARK: - 法斗（蝙蝠耳 + 扁脸）

    private func drawBulldog(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体（更圆更胖）
        let bodyRect = CGRect(x: pos.x - 13 * scale, y: pos.y - 14 * scale, width: 26 * scale, height: 20 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        // 腿（短粗）
        for dx in [-8.0, 6.0] as [CGFloat] {
            drawLeg(context: &context, at: CGPoint(x: pos.x + dx * scale, y: pos.y + 4 * scale), color: bodyColor, scale: scale * 0.7)
        }
        for dx in [-5.0, 4.0] as [CGFloat] {
            drawLeg(context: &context, at: CGPoint(x: pos.x + dx * scale, y: pos.y + 5 * scale), color: bodyColor, scale: scale * 0.7)
        }

        // 小卷尾巴
        drawCurlyTail(context: &context, at: pos, color: accentColor, scale: scale, wag: tailWag)

        // 头（更大更圆，扁脸）
        let headCenter = CGPoint(x: pos.x + 8 * scale, y: pos.y - 20 * scale)
        let headRadius: CGFloat = 13 * scale
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 蝙蝠耳（大而立）
        drawBatEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 扁脸
        drawFlatFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale, isBlinking: isBlinking)
    }

    // MARK: - 柴犬（卷尾巴 + 尖耳）

    private func drawShiba(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体
        let bodyRect = CGRect(x: pos.x - 13 * scale, y: pos.y - 15 * scale, width: 26 * scale, height: 20 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        // 白色胸腹
        var belly = Path()
        belly.addEllipse(in: CGRect(x: pos.x - 5 * scale, y: pos.y - 2 * scale, width: 12 * scale, height: 12 * scale))
        context.fill(belly, with: .color(Color(hex: "FFF8F0")))

        // 腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 7 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale * 0.8)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 7 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale * 0.8)
        drawLeg(context: &context, at: CGPoint(x: pos.x - 3 * scale, y: pos.y + 4 * scale), color: Color(hex: "FFF8F0"), scale: scale * 0.8)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 4 * scale, y: pos.y + 4 * scale), color: Color(hex: "FFF8F0"), scale: scale * 0.8)

        // 卷尾巴（柴犬标志）
        drawCurledTail(context: &context, at: pos, color: accentColor, scale: scale, wag: tailWag)

        // 头
        let headCenter = CGPoint(x: pos.x + 10 * scale, y: pos.y - 21 * scale)
        let headRadius: CGFloat = 11 * scale
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 尖耳
        drawPointedEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 脸（柴犬表情）
        drawFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale * 0.9, isBlinking: isBlinking, eyeColor: .black)
    }

    // MARK: - 通用狗狗

    private func drawGenericDog(context: inout GraphicsContext, at pos: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, tailWag: Double, isBlinking: Bool) {
        // 身体
        let bodyRect = CGRect(x: pos.x - 14 * scale, y: pos.y - 16 * scale, width: 28 * scale, height: 20 * scale)
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))
        context.stroke(Path(ellipseIn: bodyRect), with: .color(accentColor.opacity(0.4)), lineWidth: 0.8)

        // 后腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 8 * scale, y: pos.y + 2 * scale), color: bodyColor, scale: scale * 0.8)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 8 * scale, y: pos.y + 2 * scale), color: bodyColor, scale: scale * 0.8)

        // 尾巴
        drawTail(context: &context, at: pos, color: accentColor, scale: scale, wag: tailWag)

        // 头
        let headCenter = CGPoint(x: pos.x + 10 * scale, y: pos.y - 20 * scale)
        let headRadius: CGFloat = 10 * scale
        let headRect = CGRect(x: headCenter.x - headRadius, y: headCenter.y - headRadius, width: headRadius * 2, height: headRadius * 2)
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))

        // 耳朵
        drawEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 脸
        drawFace(context: &context, at: headCenter, bodyColor: bodyColor, accentColor: accentColor, scale: scale * 0.9, isBlinking: isBlinking, eyeColor: .black)

        // 前腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 4 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 6 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale)
    }

    // MARK: - 脸部绘制

    private func drawFace(context: inout GraphicsContext, at headCenter: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, isBlinking: Bool, eyeColor: Color) {
        // 脸颊红晕
        for side in [-1.0, 1.0] as [CGFloat] {
            var blush = Path()
            blush.addEllipse(in: CGRect(x: headCenter.x + side * 5 * scale - 3 * scale, y: headCenter.y + 2 * scale, width: 6 * scale, height: 4 * scale))
            context.fill(blush, with: .color(Color(hex: "FFB6C1").opacity(0.35)))
        }

        // 眼睛
        let eyeOffsetX: CGFloat = 3 * scale
        let eyeOffsetY: CGFloat = -2 * scale
        let eyeRadius: CGFloat = 2.2 * scale

        if isBlinking {
            // 闭眼（一条线）
            var closedEye = Path()
            closedEye.move(to: CGPoint(x: headCenter.x + eyeOffsetX - eyeRadius, y: headCenter.y + eyeOffsetY))
            closedEye.addLine(to: CGPoint(x: headCenter.x + eyeOffsetX + eyeRadius, y: headCenter.y + eyeOffsetY))
            context.stroke(closedEye, with: .color(.black), lineWidth: 1.5)
        } else {
            context.fill(
                Path(ellipseIn: CGRect(x: headCenter.x + eyeOffsetX - eyeRadius, y: headCenter.y + eyeOffsetY - eyeRadius,
                                        width: eyeRadius * 2, height: eyeRadius * 2)),
                with: .color(eyeColor)
            )
            // 高光
            context.fill(
                Path(ellipseIn: CGRect(x: headCenter.x + eyeOffsetX - 0.5, y: headCenter.y + eyeOffsetY - 1,
                                        width: 1.5, height: 1.5)),
                with: .color(.white)
            )
        }

        // 鼻子
        let noseCenter = CGPoint(x: headCenter.x + 8 * scale, y: headCenter.y + 1 * scale)
        context.fill(
            Path(ellipseIn: CGRect(x: noseCenter.x - 2.5 * scale, y: noseCenter.y - 1.5 * scale,
                                    width: 5 * scale, height: 3.5 * scale)),
            with: .color(.black)
        )

        // 嘴巴（微笑）
        var mouthPath = Path()
        mouthPath.move(to: CGPoint(x: noseCenter.x, y: noseCenter.y + 2 * scale))
        mouthPath.addQuadCurve(
            to: CGPoint(x: noseCenter.x - 5 * scale, y: noseCenter.y + 4 * scale),
            control: CGPoint(x: noseCenter.x - 1 * scale, y: noseCenter.y + 6 * scale)
        )
        context.stroke(mouthPath, with: .color(accentColor.opacity(0.6)), lineWidth: 1)
    }

    private func drawFlatFace(context: inout GraphicsContext, at headCenter: CGPoint, bodyColor: Color, accentColor: Color, scale: CGFloat, isBlinking: Bool) {
        // 扁脸皱纹
        var wrinkle1 = Path()
        wrinkle1.move(to: CGPoint(x: headCenter.x - 4 * scale, y: headCenter.y - 3 * scale))
        wrinkle1.addQuadCurve(to: CGPoint(x: headCenter.x + 4 * scale, y: headCenter.y - 3 * scale),
                              control: CGPoint(x: headCenter.x, y: headCenter.y - 5 * scale))
        context.stroke(wrinkle1, with: .color(accentColor.opacity(0.3)), lineWidth: 0.8)

        // 眼睛（间距更宽）
        let eyeRadius: CGFloat = 2.5 * scale
        if !isBlinking {
            context.fill(Path(ellipseIn: CGRect(x: headCenter.x - 5 * scale - eyeRadius, y: headCenter.y - 2 * scale - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2)), with: .color(.black))
            context.fill(Path(ellipseIn: CGRect(x: headCenter.x + 3 * scale - eyeRadius, y: headCenter.y - 2 * scale - eyeRadius, width: eyeRadius * 2, height: eyeRadius * 2)), with: .color(.black))
        }

        // 扁鼻子（更大）
        context.fill(Path(ellipseIn: CGRect(x: headCenter.x - 3 * scale, y: headCenter.y + 2 * scale, width: 6 * scale, height: 4 * scale)), with: .color(.black))

        // 嘴巴
        var mouth = Path()
        mouth.move(to: CGPoint(x: headCenter.x - 4 * scale, y: headCenter.y + 5 * scale))
        mouth.addQuadCurve(to: CGPoint(x: headCenter.x + 4 * scale, y: headCenter.y + 5 * scale),
                           control: CGPoint(x: headCenter.x, y: headCenter.y + 8 * scale))
        context.stroke(mouth, with: .color(accentColor.opacity(0.5)), lineWidth: 1)
    }

    // MARK: - 耳朵变体

    private func drawEars(context: inout GraphicsContext, at headCenter: CGPoint, color: Color, scale: CGFloat) {
        // 左耳
        var leftEar = Path()
        leftEar.move(to: CGPoint(x: headCenter.x - 6 * scale, y: headCenter.y - 8 * scale))
        leftEar.addLine(to: CGPoint(x: headCenter.x - 10 * scale, y: headCenter.y - 18 * scale))
        leftEar.addLine(to: CGPoint(x: headCenter.x - 2 * scale, y: headCenter.y - 10 * scale))
        leftEar.closeSubpath()
        context.fill(leftEar, with: .color(color))

        // 右耳
        var rightEar = Path()
        rightEar.move(to: CGPoint(x: headCenter.x + 4 * scale, y: headCenter.y - 9 * scale))
        rightEar.addLine(to: CGPoint(x: headCenter.x + 8 * scale, y: headCenter.y - 19 * scale))
        rightEar.addLine(to: CGPoint(x: headCenter.x + 10 * scale, y: headCenter.y - 8 * scale))
        rightEar.closeSubpath()
        context.fill(rightEar, with: .color(color))
    }

    private func drawLargeEars(context: inout GraphicsContext, at headCenter: CGPoint, color: Color, scale: CGFloat) {
        // 柯基大耳朵
        for side in [-1.0, 1.0] as [CGFloat] {
            var ear = Path()
            let baseX = headCenter.x + side * 7 * scale
            ear.move(to: CGPoint(x: baseX - 4 * scale, y: headCenter.y - 6 * scale))
            ear.addLine(to: CGPoint(x: baseX - 2 * scale, y: headCenter.y - 22 * scale))
            ear.addLine(to: CGPoint(x: baseX + 6 * scale, y: headCenter.y - 6 * scale))
            ear.closeSubpath()
            context.fill(ear, with: .color(color))
        }
    }

    private func drawPointedEars(context: inout GraphicsContext, at headCenter: CGPoint, color: Color, scale: CGFloat) {
        // 尖耳（哈士奇/柴犬）
        for side in [-1.0, 1.0] as [CGFloat] {
            var ear = Path()
            let baseX = headCenter.x + side * 6 * scale
            ear.move(to: CGPoint(x: baseX - 3 * scale, y: headCenter.y - 7 * scale))
            ear.addLine(to: CGPoint(x: baseX, y: headCenter.y - 20 * scale))
            ear.addLine(to: CGPoint(x: baseX + 5 * scale, y: headCenter.y - 7 * scale))
            ear.closeSubpath()
            context.fill(ear, with: .color(color))
        }
    }

    private func drawSmallEars(context: inout GraphicsContext, at headCenter: CGPoint, color: Color, scale: CGFloat) {
        // 小耳朵（被毛遮住，比熊/萨摩耶）
        for side in [-1.0, 1.0] as [CGFloat] {
            var ear = Path()
            let baseX = headCenter.x + side * 8 * scale
            ear.addEllipse(in: CGRect(x: baseX - 3 * scale, y: headCenter.y - 12 * scale, width: 6 * scale, height: 8 * scale))
            context.fill(ear, with: .color(color.opacity(0.7)))
        }
    }

    private func drawBatEars(context: inout GraphicsContext, at headCenter: CGPoint, color: Color, scale: CGFloat) {
        // 蝙蝠耳（法斗）
        for side in [-1.0, 1.0] as [CGFloat] {
            var ear = Path()
            let baseX = headCenter.x + side * 8 * scale
            ear.move(to: CGPoint(x: baseX - 5 * scale, y: headCenter.y - 5 * scale))
            ear.addLine(to: CGPoint(x: baseX - 3 * scale, y: headCenter.y - 22 * scale))
            ear.addLine(to: CGPoint(x: baseX + 5 * scale, y: headCenter.y - 20 * scale))
            ear.addLine(to: CGPoint(x: baseX + 7 * scale, y: headCenter.y - 5 * scale))
            ear.closeSubpath()
            context.fill(ear, with: .color(color))
        }
    }

    // MARK: - 尾巴变体

    private func drawTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat, wag: Double) {
        var tailPath = Path()
        let wagOffset = CGFloat(wag) * 5 * scale
        tailPath.move(to: CGPoint(x: pos.x - 14 * scale, y: pos.y - 10 * scale))
        tailPath.addQuadCurve(
            to: CGPoint(x: pos.x - 20 * scale + wagOffset, y: pos.y - 24 * scale),
            control: CGPoint(x: pos.x - 22 * scale + wagOffset * 0.5, y: pos.y - 14 * scale)
        )
        context.stroke(tailPath, with: .color(color), lineWidth: 3 * scale)
    }

    private func drawShortTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat, wag: Double) {
        // 柯基短尾巴（竖起来）
        let wagOffset = CGFloat(wag) * 3 * scale
        var tail = Path()
        tail.move(to: CGPoint(x: pos.x + 14 * scale, y: pos.y - 8 * scale))
        tail.addQuadCurve(
            to: CGPoint(x: pos.x + 16 * scale + wagOffset, y: pos.y - 20 * scale),
            control: CGPoint(x: pos.x + 18 * scale + wagOffset * 0.5, y: pos.y - 14 * scale)
        )
        context.stroke(tail, with: .color(color), lineWidth: 4 * scale)
    }

    private func drawFluffyTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat, wag: Double) {
        // 蓬松尾巴（多层圆）
        let wagOffset = CGFloat(wag) * 4 * scale
        let tailBase = CGPoint(x: pos.x - 16 * scale + wagOffset, y: pos.y - 14 * scale)
        for i in 0..<4 {
            var puff = Path()
            let px = tailBase.x - CGFloat(i) * 3 * scale
            let py = tailBase.y - CGFloat(i) * 4 * scale
            let r = (4 - CGFloat(i) * 0.5) * scale
            puff.addEllipse(in: CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2))
            context.fill(puff, with: .color(color.opacity(0.8)))
        }
    }

    private func drawCurlyTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat, wag: Double) {
        // 卷尾巴（法斗/柴犬）
        let wagOffset = CGFloat(wag) * 2 * scale
        var tail = Path()
        tail.move(to: CGPoint(x: pos.x - 12 * scale, y: pos.y - 12 * scale))
        tail.addCurve(
            to: CGPoint(x: pos.x - 18 * scale + wagOffset, y: pos.y - 8 * scale),
            control1: CGPoint(x: pos.x - 22 * scale, y: pos.y - 20 * scale),
            control2: CGPoint(x: pos.x - 8 * scale, y: pos.y - 22 * scale)
        )
        context.stroke(tail, with: .color(color), lineWidth: 3 * scale)
    }

    private func drawCurledTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat, wag: Double) {
        // 柴犬卷尾巴（卷在背上）
        let wagOffset = CGFloat(wag) * 2 * scale
        var tail = Path()
        tail.move(to: CGPoint(x: pos.x - 12 * scale, y: pos.y - 14 * scale))
        tail.addCurve(
            to: CGPoint(x: pos.x - 5 * scale + wagOffset, y: pos.y - 22 * scale),
            control1: CGPoint(x: pos.x - 20 * scale, y: pos.y - 24 * scale),
            control2: CGPoint(x: pos.x - 15 * scale, y: pos.y - 30 * scale)
        )
        context.stroke(tail, with: .color(color), lineWidth: 3.5 * scale)
    }

    // MARK: - 腿

    private func drawLeg(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat) {
        let legRect = CGRect(
            x: pos.x - 3 * scale,
            y: pos.y,
            width: 6 * scale,
            height: 10 * scale
        )
        context.fill(Path(roundedRect: legRect, cornerRadius: 2.5 * scale), with: .color(color))
        // 爪子
        var paw = Path()
        paw.addEllipse(in: CGRect(x: pos.x - 3.5 * scale, y: pos.y + 8 * scale, width: 7 * scale, height: 4 * scale))
        context.fill(paw, with: .color(color.darker(by: 0.1)))
    }

    // MARK: - 阴影

    private func drawShadow(context: inout GraphicsContext, at pos: CGPoint, width: CGFloat, height: CGFloat) {
        let shadowRect = CGRect(
            x: pos.x - width / 2,
            y: pos.y - height / 2,
            width: width,
            height: height
        )
        context.fill(
            Path(ellipseIn: shadowRect),
            with: .color(.black.opacity(0.12))
        )
    }

    // MARK: - 可交互道具

    private func drawProp(context: inout GraphicsContext, origin: CGPoint, prop: InteractiveProp, time: Date) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: prop.position.x, y: prop.position.y, origin: origin
        )

        let t = time.timeIntervalSinceReferenceDate
        let pulse = sin(t * 2.5) * 0.12 + 1.0
        let radius: CGFloat = 16 * pulse

        // 外圈光晕
        let outerRect = CGRect(x: position.x - radius - 4, y: position.y - radius - 4, width: (radius + 4) * 2, height: (radius + 4) * 2)
        context.fill(Path(ellipseIn: outerRect), with: .color(AppColors.accentYellow.opacity(0.1)))

        // 内圈
        let circleRect = CGRect(x: position.x - radius, y: position.y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: circleRect), with: .color(AppColors.accentYellow.opacity(0.2)))
        context.stroke(Path(ellipseIn: circleRect), with: .color(AppColors.accentYellow.opacity(0.7)), lineWidth: 1.5)

        // emoji
        context.draw(Text(prop.emoji).font(.system(size: 22)), at: position)
    }

    // MARK: - 氛围粒子

    private func drawAmbientParticles(context: inout GraphicsContext, origin: CGPoint, size: CGSize, time: Date) {
        let t = time.timeIntervalSinceReferenceDate
        let slot = variant.timeSlot

        switch slot {
        case .night, .lateNight:
            // 夜晚：小星星闪烁
            for i in 0..<8 {
                let px = size.width * 0.1 + CGFloat(i) * size.width * 0.1
                let py = size.height * 0.05 + CGFloat(i % 3) * size.height * 0.08
                let twinkle = sin(t * 3.0 + Double(i)) * 0.5 + 0.5
                var star = Path()
                star.addEllipse(in: CGRect(x: px - 1.5, y: py - 1.5, width: 3, height: 3))
                context.fill(star, with: .color(.white.opacity(twinkle * 0.6)))
            }

        case .earlyMorning, .morning, .lateMorning:
            // 早晨：阳光灰尘
            for i in 0..<6 {
                let px = size.width * 0.2 + CGFloat(i) * size.width * 0.12 + CGFloat(sin(t + Double(i))) * 10
                let py = size.height * 0.15 + CGFloat(cos(t * 0.7 + Double(i))) * 20
                let alpha = sin(t * 2.0 + Double(i) * 1.5) * 0.3 + 0.4
                var dust = Path()
                dust.addEllipse(in: CGRect(x: px - 1, y: py - 1, width: 2, height: 2))
                context.fill(dust, with: .color(Color(hex: "FFD700").opacity(alpha * 0.3)))
            }

        default:
            break
        }
    }

    // MARK: - 时段光照

    private func drawTimeOverlay(context: inout GraphicsContext, size: CGSize, time: Date) {
        let slot = variant.timeSlot
        let overlayColor: Color
        let opacity: Double

        switch slot {
        case .earlyMorning:
            overlayColor = Color(red: 1.0, green: 0.85, blue: 0.6)
            opacity = 0.06
        case .morning, .lateMorning:
            overlayColor = Color(red: 1.0, green: 0.95, blue: 0.85)
            opacity = 0.03
        case .noon:
            overlayColor = Color(red: 1.0, green: 1.0, blue: 0.95)
            opacity = 0.02
        case .afternoon, .lateAfternoon:
            overlayColor = Color(red: 1.0, green: 0.82, blue: 0.55)
            opacity = 0.06
        case .evening:
            overlayColor = Color(red: 0.85, green: 0.5, blue: 0.3)
            opacity = 0.1
        case .night, .lateNight:
            overlayColor = Color(red: 0.08, green: 0.08, blue: 0.25)
            opacity = 0.18
        }

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(overlayColor.opacity(opacity)))
    }

    // MARK: - 场景信息

    private func drawSceneInfo(context: inout GraphicsContext, size: CGSize, layout: SceneLayout) {
        // 左上角地点名（带背景胶囊）
        let text = Text(layout.location).font(.system(size: 13, weight: .semibold)).foregroundStyle(AppColors.textPrimary)
        let textSize = context.resolve(text).measure(in: size)
        let capsuleRect = CGRect(x: 12, y: 12, width: textSize.width + 16, height: 24)

        var capsule = Path()
        capsule.addRoundedRect(in: capsuleRect, cornerSize: CGSize(width: 12, height: 12))
        context.fill(capsule, with: .color(.white.opacity(0.7)))
        context.stroke(capsule, with: .color(.black.opacity(0.08)), lineWidth: 0.5)

        context.draw(text, at: CGPoint(x: capsuleRect.midX, y: capsuleRect.midY))
    }
}
