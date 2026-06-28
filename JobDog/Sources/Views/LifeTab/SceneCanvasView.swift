import SwiftUI

/// 等距场景 Canvas 渲染
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

        // 计算原点（场景中心偏上）
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.3)

        // 1. 绘制地板网格
        drawFloor(context: &context, origin: origin, gridSize: layout.gridSize, floorColor: layout.floorColor)

        // 2. 绘制墙壁（如果有）
        if let wallColor = layout.wallColor {
            drawWalls(context: &context, origin: origin, gridSize: layout.gridSize, wallColor: wallColor)
        }

        // 3. 收集所有需要绘制的物件，按 y 排序（实现遮挡关系）
        var drawables: [(y: CGFloat, draw: () -> Void)] = []

        for furniture in layout.furniture {
            let pos = IsometricHelpers.cartesianToIsometric(
                x: furniture.position.x, y: furniture.position.y, origin: origin
            )
            drawables.append((y: pos.y, draw: { [self] in
                drawFurniture(context: &context, origin: origin, furniture: furniture)
            }))
        }

        // 狗狗
        let dogGrid = variant.resolvedDogPosition()
        let dogScreenPos = IsometricHelpers.cartesianToIsometric(
            x: dogGrid.x, y: dogGrid.y, origin: origin
        )
        drawables.append((y: dogScreenPos.y, draw: { [self] in
            drawDog(context: &context, origin: origin, dogGridPos: dogGrid)
        }))

        // 按 y 排序后绘制
        drawables.sort { $0.y < $1.y }
        for item in drawables {
            item.draw()
        }

        // 4. 绘制可交互道具（始终在最上层）
        for prop in variant.interactiveProps {
            drawProp(context: &context, origin: origin, prop: prop, time: time)
        }

        // 5. 绘制时段光照叠加
        drawTimeOverlay(context: &context, size: size)

        // 6. 绘制场景信息
        drawSceneInfo(context: &context, size: size, layout: layout)
    }

    // MARK: - 绘制地板

    private func drawFloor(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, floorColor: String) {
        let color = Color(hex: floorColor)

        for x in 0...gridSize.width {
            for y in 0...gridSize.height {
                let point = IsometricHelpers.cartesianToIsometric(x: x, y: y, origin: origin)

                // 绘制菱形瓦片
                var path = Path()
                path.move(to: CGPoint(x: point.x, y: point.y))
                path.addLine(to: CGPoint(x: point.x + IsometricHelpers.tileWidth / 2, y: point.y + IsometricHelpers.tileHeight / 2))
                path.addLine(to: CGPoint(x: point.x, y: point.y + IsometricHelpers.tileHeight))
                path.addLine(to: CGPoint(x: point.x - IsometricHelpers.tileWidth / 2, y: point.y + IsometricHelpers.tileHeight / 2))
                path.closeSubpath()

                // 交替色棋盘效果
                let isAlternate = (x + y) % 2 == 0
                context.fill(path, with: .color(color.opacity(isAlternate ? 0.35 : 0.25)))
                context.stroke(path, with: .color(color.opacity(0.4)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - 绘制墙壁

    private func drawWalls(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, wallColor: String) {
        let color = Color(hex: wallColor)

        // 后墙（沿 x 轴）
        for x in 0..<gridSize.width {
            let start = IsometricHelpers.cartesianToIsometric(x: x, y: 0, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: x + 1, y: 0, origin: origin)

            var wallPath = Path()
            wallPath.move(to: start)
            wallPath.addLine(to: end)
            wallPath.addLine(to: CGPoint(x: end.x, y: end.y - 40))
            wallPath.addLine(to: CGPoint(x: start.x, y: start.y - 40))
            wallPath.closeSubpath()

            context.fill(wallPath, with: .color(color.opacity(0.6)))
            context.stroke(wallPath, with: .color(color.darker(by: 0.2)), lineWidth: 0.5)
        }

        // 左墙（沿 y 轴）
        for y in 0..<gridSize.height {
            let start = IsometricHelpers.cartesianToIsometric(x: 0, y: y, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: 0, y: y + 1, origin: origin)

            var wallPath = Path()
            wallPath.move(to: start)
            wallPath.addLine(to: end)
            wallPath.addLine(to: CGPoint(x: end.x, y: end.y - 40))
            wallPath.addLine(to: CGPoint(x: start.x, y: start.y - 40))
            wallPath.closeSubpath()

            context.fill(wallPath, with: .color(color.opacity(0.4)))
            context.stroke(wallPath, with: .color(color.darker(by: 0.2)), lineWidth: 0.5)
        }
    }

    // MARK: - 绘制家具

    private func drawFurniture(context: inout GraphicsContext, origin: CGPoint, furniture: FurnitureItem) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: furniture.position.x,
            y: furniture.position.y,
            origin: origin
        )

        let boxWidth = CGFloat(furniture.size.width) * IsometricHelpers.tileWidth * 0.8
        let boxHeight = CGFloat(furniture.size.height) * IsometricHelpers.tileHeight * 0.8
        let color = Color(hex: furniture.color)

        // 家具阴影
        drawShadow(context: &context, at: CGPoint(x: position.x + 4, y: position.y + 4),
                   width: boxWidth * 0.8, height: boxHeight * 0.4)

        let box = IsometricBox(
            position: position,
            width: boxWidth,
            height: boxHeight,
            depth: 20,
            color: color
        )
        box.draw(in: context)

        // 绘制 emoji
        let textPosition = CGPoint(x: position.x, y: position.y - 10)
        context.draw(
            Text(furniture.emoji).font(.system(size: 20)),
            at: textPosition
        )
    }

    // MARK: - 绘制狗狗（Canvas 路径绘制可爱狗狗）

    private func drawDog(context: inout GraphicsContext, origin: CGPoint, dogGridPos: GridPosition) {
        let pos = IsometricHelpers.cartesianToIsometric(
            x: dogGridPos.x, y: dogGridPos.y, origin: origin
        )

        let breed = dog.breed
        let bodyColor = Color(hex: breed.bodyColor)
        let accentColor = Color(hex: breed.accentColor)
        let isLarge = breed.sizeCategory == .large
        let scale: CGFloat = isLarge ? 1.3 : 1.0

        // 阴影
        drawShadow(context: &context, at: CGPoint(x: pos.x + 2, y: pos.y + 6),
                   width: 28 * scale, height: 10 * scale)

        // 尾巴
        drawTail(context: &context, at: pos, color: accentColor, scale: scale)

        // 身体（椭圆）
        let bodyRect = CGRect(
            x: pos.x - 14 * scale,
            y: pos.y - 16 * scale,
            width: 28 * scale,
            height: 20 * scale
        )
        context.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))
        context.stroke(Path(ellipseIn: bodyRect), with: .color(accentColor.opacity(0.5)), lineWidth: 1)

        // 后腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 8 * scale, y: pos.y + 2 * scale), color: bodyColor, scale: scale * 0.8)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 8 * scale, y: pos.y + 2 * scale), color: bodyColor, scale: scale * 0.8)

        // 头（圆形，在身体上方偏前）
        let headCenter = CGPoint(x: pos.x + 10 * scale, y: pos.y - 20 * scale)
        let headRadius: CGFloat = 10 * scale
        let headRect = CGRect(
            x: headCenter.x - headRadius,
            y: headCenter.y - headRadius,
            width: headRadius * 2,
            height: headRadius * 2
        )
        context.fill(Path(ellipseIn: headRect), with: .color(bodyColor))
        context.stroke(Path(ellipseIn: headRect), with: .color(accentColor.opacity(0.4)), lineWidth: 1)

        // 耳朵
        drawEars(context: &context, at: headCenter, color: accentColor, scale: scale)

        // 眼睛
        let eyeOffsetX: CGFloat = 3 * scale
        let eyeOffsetY: CGFloat = -2 * scale
        let eyeRadius: CGFloat = 2 * scale
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x + eyeOffsetX - eyeRadius, y: headCenter.y + eyeOffsetY - eyeRadius,
                                    width: eyeRadius * 2, height: eyeRadius * 2)),
            with: .color(.black)
        )
        // 眼睛高光
        context.fill(
            Path(ellipseIn: CGRect(x: headCenter.x + eyeOffsetX - 0.5, y: headCenter.y + eyeOffsetY - 1,
                                    width: 1.5, height: 1.5)),
            with: .color(.white)
        )

        // 鼻子
        let noseCenter = CGPoint(x: headCenter.x + 8 * scale, y: headCenter.y + 2 * scale)
        context.fill(
            Path(ellipseIn: CGRect(x: noseCenter.x - 2 * scale, y: noseCenter.y - 1.5 * scale,
                                    width: 4 * scale, height: 3 * scale)),
            with: .color(.black)
        )

        // 嘴巴（微笑弧线）
        var mouthPath = Path()
        mouthPath.move(to: CGPoint(x: noseCenter.x, y: noseCenter.y + 2 * scale))
        mouthPath.addQuadCurve(
            to: CGPoint(x: noseCenter.x - 4 * scale, y: noseCenter.y + 4 * scale),
            control: CGPoint(x: noseCenter.x - 1 * scale, y: noseCenter.y + 5 * scale)
        )
        context.stroke(mouthPath, with: .color(accentColor), lineWidth: 1)

        // 前腿
        drawLeg(context: &context, at: CGPoint(x: pos.x - 4 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale)
        drawLeg(context: &context, at: CGPoint(x: pos.x + 6 * scale, y: pos.y + 3 * scale), color: bodyColor, scale: scale)

        // 行为文字
        context.draw(
            Text(variant.dogAction)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary),
            at: CGPoint(x: pos.x, y: pos.y + 18 * scale)
        )
    }

    // MARK: - 狗狗部件绘制

    private func drawTail(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat) {
        var tailPath = Path()
        tailPath.move(to: CGPoint(x: pos.x - 14 * scale, y: pos.y - 10 * scale))
        tailPath.addQuadCurve(
            to: CGPoint(x: pos.x - 20 * scale, y: pos.y - 22 * scale),
            control: CGPoint(x: pos.x - 22 * scale, y: pos.y - 12 * scale)
        )
        context.stroke(tailPath, with: .color(color), lineWidth: 3 * scale)
    }

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

    private func drawLeg(context: inout GraphicsContext, at pos: CGPoint, color: Color, scale: CGFloat) {
        let legRect = CGRect(
            x: pos.x - 3 * scale,
            y: pos.y,
            width: 6 * scale,
            height: 10 * scale
        )
        context.fill(Path(roundedRect: legRect, cornerRadius: 2 * scale), with: .color(color))
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
            with: .color(.black.opacity(0.15))
        )
    }

    // MARK: - 绘制可交互道具

    private func drawProp(context: inout GraphicsContext, origin: CGPoint, prop: InteractiveProp, time: Date) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: prop.position.x,
            y: prop.position.y,
            origin: origin
        )

        // 呼吸动画
        let pulse = sin(time.timeIntervalSinceReferenceDate * 2.0) * 0.15 + 1.0
        let radius: CGFloat = 15 * pulse

        // 绘制发光圆圈
        let circleRect = CGRect(
            x: position.x - radius,
            y: position.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        context.fill(
            Path(ellipseIn: circleRect),
            with: .color(AppColors.accentYellow.opacity(0.25))
        )
        context.stroke(
            Path(ellipseIn: circleRect),
            with: .color(AppColors.accentYellow.opacity(0.8)),
            lineWidth: 1.5
        )

        // 绘制 emoji
        context.draw(
            Text(prop.emoji).font(.system(size: 20)),
            at: position
        )
    }

    // MARK: - 时段光照叠加

    private func drawTimeOverlay(context: inout GraphicsContext, size: CGSize) {
        let slot = variant.timeSlot
        let overlayColor: Color
        let opacity: Double

        switch slot {
        case .earlyMorning:
            overlayColor = Color(red: 1.0, green: 0.85, blue: 0.6) // 暖晨光
            opacity = 0.08
        case .morning, .lateMorning:
            overlayColor = Color(red: 1.0, green: 0.95, blue: 0.8) // 明亮
            opacity = 0.04
        case .noon:
            overlayColor = Color(red: 1.0, green: 1.0, blue: 0.9) // 正午白光
            opacity = 0.03
        case .afternoon, .lateAfternoon:
            overlayColor = Color(red: 1.0, green: 0.8, blue: 0.5) // 暖午后
            opacity = 0.08
        case .evening:
            overlayColor = Color(red: 0.9, green: 0.5, blue: 0.3) // 夕照
            opacity = 0.12
        case .night, .lateNight:
            overlayColor = Color(red: 0.1, green: 0.1, blue: 0.3) // 夜色
            opacity = 0.2
        }

        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .color(overlayColor.opacity(opacity))
        )
    }

    // MARK: - 绘制场景信息

    private func drawSceneInfo(context: inout GraphicsContext, size: CGSize, layout: SceneLayout) {
        // 左上角：地点名
        context.draw(
            Text(layout.location)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary),
            at: CGPoint(x: 60, y: 20)
        )
    }
}
