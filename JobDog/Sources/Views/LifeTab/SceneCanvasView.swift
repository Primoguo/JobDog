import SwiftUI

/// 等距场景 Canvas 渲染 — emoji 精灵 + 干净等距地板
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

    // MARK: - 场景主绘制

    private func drawScene(context: inout GraphicsContext, size: CGSize, time: Date) {
        let layout = variant.layout
        let origin = CGPoint(x: size.width / 2, y: size.height * 0.30)

        // 1. 地板
        drawFloor(context: &context, origin: origin, gridSize: layout.gridSize, floorColor: layout.floorColor)

        // 2. 墙壁
        if let wallColor = layout.wallColor {
            drawWalls(context: &context, origin: origin, gridSize: layout.gridSize, wallColor: wallColor)
        }

        // 3. 收集所有物件，Y 排序
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
        let dogPos = IsometricHelpers.cartesianToIsometric(
            x: dogGrid.x, y: dogGrid.y, origin: origin
        )
        drawables.append((y: dogPos.y, kind: .dog))

        drawables.sort { $0.y < $1.y }

        for item in drawables {
            switch item.kind {
            case .furniture(let furniture):
                drawFurniture(context: &context, origin: origin, furniture: furniture)
            case .dog:
                drawDog(context: &context, at: dogPos, time: time)
            }
        }

        // 4. 可交互道具
        for prop in variant.interactiveProps {
            drawProp(context: &context, origin: origin, prop: prop, time: time)
        }

        // 5. 时段光照叠加
        drawTimeOverlay(context: &context, size: size)

        // 6. 场景信息
        drawSceneInfo(context: &context, size: size, layout: layout)
    }

    // MARK: - 地板

    private func drawFloor(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, floorColor: String) {
        let baseColor = Color(hex: floorColor)
        let tw = IsometricHelpers.tileWidth
        let th = IsometricHelpers.tileHeight

        for x in 0...gridSize.width {
            for y in 0...gridSize.height {
                let point = IsometricHelpers.cartesianToIsometric(x: x, y: y, origin: origin)

                var path = Path()
                path.move(to: point)
                path.addLine(to: CGPoint(x: point.x + tw / 2, y: point.y + th / 2))
                path.addLine(to: CGPoint(x: point.x, y: point.y + th))
                path.addLine(to: CGPoint(x: point.x - tw / 2, y: point.y + th / 2))
                path.closeSubpath()

                // 柔和棋盘格
                let isAlternate = (x + y) % 2 == 0
                context.fill(path, with: .color(baseColor.opacity(isAlternate ? 0.35 : 0.22)))
                context.stroke(path, with: .color(baseColor.opacity(0.15)), lineWidth: 0.5)
            }
        }
    }

    // MARK: - 墙壁

    private func drawWalls(context: inout GraphicsContext, origin: CGPoint, gridSize: GridSize, wallColor: String) {
        let color = Color(hex: wallColor)
        let wallHeight: CGFloat = 45

        // 后墙
        for x in 0..<gridSize.width {
            let start = IsometricHelpers.cartesianToIsometric(x: x, y: 0, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: x + 1, y: 0, origin: origin)

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            path.addLine(to: CGPoint(x: end.x, y: end.y - wallHeight))
            path.addLine(to: CGPoint(x: start.x, y: start.y - wallHeight))
            path.closeSubpath()

            context.fill(path, with: .color(color.opacity(0.4)))
        }

        // 左墙
        for y in 0..<gridSize.height {
            let start = IsometricHelpers.cartesianToIsometric(x: 0, y: y, origin: origin)
            let end = IsometricHelpers.cartesianToIsometric(x: 0, y: y + 1, origin: origin)

            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            path.addLine(to: CGPoint(x: end.x, y: end.y - wallHeight))
            path.addLine(to: CGPoint(x: start.x, y: start.y - wallHeight))
            path.closeSubpath()

            context.fill(path, with: .color(color.opacity(0.25)))
        }
    }

    // MARK: - 家具（emoji 精灵）

    private func drawFurniture(context: inout GraphicsContext, origin: CGPoint, furniture: FurnitureItem) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: furniture.position.x, y: furniture.position.y, origin: origin
        )

        // 阴影
        let shadowRect = CGRect(x: position.x - 18, y: position.y - 4, width: 36, height: 14)
        context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.08)))

        // emoji
        context.draw(
            Text(furniture.emoji).font(.system(size: 28)),
            at: CGPoint(x: position.x, y: position.y - 14)
        )
    }

    // MARK: - 狗狗（emoji + 动画）

    private func drawDog(context: inout GraphicsContext, at pos: CGPoint, time: Date) {
        let t = time.timeIntervalSinceReferenceDate
        let bounce = sin(t * 2.0) * 2 // 轻微上下浮动

        // 阴影
        let shadowRect = CGRect(x: pos.x - 16, y: pos.y - 2, width: 32, height: 12)
        context.fill(Path(ellipseIn: shadowRect), with: .color(.black.opacity(0.1)))

        // 狗狗 emoji
        let dogEmoji = dog.breed.emoji
        context.draw(
            Text(dogEmoji).font(.system(size: 34)),
            at: CGPoint(x: pos.x, y: pos.y - 18 + bounce)
        )

        // 行为文字
        context.draw(
            Text(variant.dogAction)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppColors.textSecondary),
            at: CGPoint(x: pos.x, y: pos.y + 14)
        )
    }

    // MARK: - 可交互道具

    private func drawProp(context: inout GraphicsContext, origin: CGPoint, prop: InteractiveProp, time: Date) {
        let position = IsometricHelpers.cartesianToIsometric(
            x: prop.position.x, y: prop.position.y, origin: origin
        )

        let t = time.timeIntervalSinceReferenceDate
        let pulse = sin(t * 2.5) * 0.08 + 1.0

        // 光晕圈
        let radius: CGFloat = 18 * pulse
        let glowRect = CGRect(x: position.x - radius, y: position.y - radius,
                              width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: glowRect), with: .color(AppColors.accentYellow.opacity(0.15)))
        context.stroke(Path(ellipseIn: glowRect), with: .color(AppColors.accentYellow.opacity(0.5)), lineWidth: 1.5)

        // emoji
        context.draw(Text(prop.emoji).font(.system(size: 24)), at: position)
    }

    // MARK: - 时段光照

    private func drawTimeOverlay(context: inout GraphicsContext, size: CGSize) {
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
            opacity = 0.10
        case .night, .lateNight:
            overlayColor = Color(red: 0.08, green: 0.08, blue: 0.25)
            opacity = 0.18
        }

        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(overlayColor.opacity(opacity)))
    }

    // MARK: - 场景信息

    private func drawSceneInfo(context: inout GraphicsContext, size: CGSize, layout: SceneLayout) {
        let text = Text(layout.location)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
        let textSize = context.resolve(text).measure(in: size)
        let capsuleRect = CGRect(x: 12, y: 12, width: textSize.width + 16, height: 24)

        var capsule = Path()
        capsule.addRoundedRect(in: capsuleRect, cornerSize: CGSize(width: 12, height: 12))
        context.fill(capsule, with: .color(.white.opacity(0.7)))
        context.stroke(capsule, with: .color(.black.opacity(0.08)), lineWidth: 0.5)

        context.draw(text, at: CGPoint(x: capsuleRect.midX, y: capsuleRect.midY))
    }
}
