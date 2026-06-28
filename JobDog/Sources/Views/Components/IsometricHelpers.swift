import SwiftUI

// MARK: - 等距坐标工具

enum IsometricHelpers {
    /// 瓦片尺寸
    static let tileWidth: CGFloat = 64
    static let tileHeight: CGFloat = 32

    /// 笛卡尔坐标 → 等距坐标
    static func cartesianToIsometric(x: Int, y: Int, origin: CGPoint) -> CGPoint {
        let isoX = origin.x + CGFloat(x - y) * tileWidth / 2
        let isoY = origin.y + CGFloat(x + y) * tileHeight / 2
        return CGPoint(x: isoX, y: isoY)
    }

    /// 等距坐标 → 笛卡尔坐标（用于点击检测）
    static func isometricToCartesian(point: CGPoint, origin: CGPoint) -> (x: Int, y: Int) {
        let dx = point.x - origin.x
        let dy = point.y - origin.y
        let x = Int((dx / (tileWidth / 2) + dy / (tileHeight / 2)) / 2)
        let y = Int((dy / (tileHeight / 2) - dx / (tileWidth / 2)) / 2)
        return (x, y)
    }
}

// MARK: - 等距盒子绘制

struct IsometricBox {
    let position: CGPoint
    let width: CGFloat
    let height: CGFloat
    let depth: CGFloat
    let color: Color

    func draw(in context: GraphicsContext) {
        let topPath = topFace
        let leftPath = leftFace
        let rightPath = rightFace

        // 绘制三个面
        context.fill(topPath, with: .color(color))
        context.fill(leftPath, with: .color(color.darker(by: 0.15)))
        context.fill(rightPath, with: .color(color.darker(by: 0.3)))

        // 描边
        context.stroke(topPath, with: .color(color.darker(by: 0.4)), lineWidth: 0.5)
        context.stroke(leftPath, with: .color(color.darker(by: 0.4)), lineWidth: 0.5)
        context.stroke(rightPath, with: .color(color.darker(by: 0.4)), lineWidth: 0.5)
    }

    /// 顶面
    private var topFace: Path {
        var path = Path()
        path.move(to: CGPoint(x: position.x, y: position.y - depth))
        path.addLine(to: CGPoint(x: position.x + width / 2, y: position.y + height / 4 - depth))
        path.addLine(to: CGPoint(x: position.x, y: position.y + height / 2 - depth))
        path.addLine(to: CGPoint(x: position.x - width / 2, y: position.y + height / 4 - depth))
        path.closeSubpath()
        return path
    }

    /// 左面
    private var leftFace: Path {
        var path = Path()
        path.move(to: CGPoint(x: position.x - width / 2, y: position.y + height / 4 - depth))
        path.addLine(to: CGPoint(x: position.x, y: position.y + height / 2 - depth))
        path.addLine(to: CGPoint(x: position.x, y: position.y + height / 2))
        path.addLine(to: CGPoint(x: position.x - width / 2, y: position.y + height / 4))
        path.closeSubpath()
        return path
    }

    /// 右面
    private var rightFace: Path {
        var path = Path()
        path.move(to: CGPoint(x: position.x, y: position.y + height / 2 - depth))
        path.addLine(to: CGPoint(x: position.x + width / 2, y: position.y + height / 4 - depth))
        path.addLine(to: CGPoint(x: position.x + width / 2, y: position.y + height / 4))
        path.addLine(to: CGPoint(x: position.x, y: position.y + height / 2))
        path.closeSubpath()
        return path
    }
}

// MARK: - Color 扩展

extension Color {
    /// 加深颜色
    func darker(by amount: Double) -> Color {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: h, saturation: s, brightness: max(0, b - CGFloat(amount)), opacity: Double(a))
        #else
        return self.opacity(1 - amount)
        #endif
    }

    /// 从 hex 字符串初始化
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
