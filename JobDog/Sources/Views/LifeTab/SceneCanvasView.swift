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

        // 3. 绘制家具
        for furniture in layout.furniture {
            drawFurniture(context: &context, origin: origin, furniture: furniture)
        }

        // 4. 绘制狗狗
        drawDog(context: &context, origin: origin, gridSize: layout.gridSize)

        // 5. 绘制可交互道具
        for prop in variant.interactiveProps {
            drawProp(context: &context, origin: origin, prop: prop)
        }

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

                context.fill(path, with: .color(color.opacity(0.3)))
                context.stroke(path, with: .color(color.opacity(0.5)), lineWidth: 0.5)
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

    // MARK: - 绘制狗狗

    private func drawDog(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize) {
        // 狗狗位于场景中心
        let dogPos = IsometricHelpers.cartesianToIsometric(
            x: gridSize.width / 2,
            y: gridSize.height / 2,
            origin: origin
        )

        // 绘制狗狗占位（彩色矩形 + emoji）
        let dogColor = dog.breed.sizeCategory == .large
            ? Color(hex: "D4A574")
            : Color(hex: "E8C8A0")

        let box = IsometricBox(
            position: dogPos,
            width: 40,
            height: 20,
            depth: 25,
            color: dogColor
        )
        box.draw(in: context)

        // 狗狗 emoji
        context.draw(
            Text(dog.breed.emoji).font(.system(size: 28)),
            at: CGPoint(x: dogPos.x, y: dogPos.y - 15)
        )

        // 行为文字
        context.draw(
            Text(variant.dogAction)
                .font(.system(size: 10))
                .foregroundStyle(AppColors.textSecondary),
            at: CGPoint(x: dogPos.x, y: dogPos.y + 20)
        )
    }

    // MARK: - 绘制可交互道具

    private func drawProp(context: inout GraphicsContext, origin: CGPoint, prop: InteractiveProp) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: prop.position.x,
            y: prop.position.y,
            origin: origin
        )

        // 绘制发光圆圈
        let circleRect = CGRect(
            x: position.x - 15,
            y: position.y - 15,
            width: 30,
            height: 30
        )

        context.fill(
            Path(ellipseIn: circleRect),
            with: .color(AppColors.accentYellow.opacity(0.3))
        )
        context.stroke(
            Path(ellipseIn: circleRect),
            with: .color(AppColors.accentYellow),
            lineWidth: 1.5
        )

        // 绘制 emoji
        context.draw(
            Text(prop.emoji).font(.system(size: 20)),
            at: position
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
