import SwiftUI

// MARK: - 颜色常量

enum AppColors {
    static let background = Color(hex: 0xFFF8E8)       // 暖米色
    static let primary = Color(hex: 0x5D8B6A)          // 森林绿
    static let primaryDark = Color(hex: 0x3E6B4F)      // 深森林绿
    static let accent = Color(hex: 0xC69A3E)           // 暖金色
    static let accentBright = Color(hex: 0xFFF1B8)     // 亮金色
    static let textPrimary = Color(hex: 0x26382B)      // 深绿黑
    static let textSecondary = Color(hex: 0x6B715F)    // 灰绿
    static let textTertiary = Color(hex: 0x9B9B8A)     // 浅灰
    static let border = Color(hex: 0x7C9B64)           // 边框绿
    static let borderLight = Color(hex: 0x9BB985)      // 浅边框
    static let cardBg = Color(hex: 0xF6E9C8)           // 卡片底色
    static let panelBg = Color(hex: 0xFFF8E8)          // 面板底色
    static let danger = Color(hex: 0xD4645A)           // 警示红
    static let warning = Color(hex: 0xE8A838)          // 警告橙
    static let success = Color(hex: 0x5D8B6A)          // 成功绿

    // 场景色
    static let floorWood = Color(hex: 0xD4B896)        // 木地板
    static let floorTile = Color(hex: 0xC8D8C8)        // 瓷砖地
    static let floorGrass = Color(hex: 0x8CB87C)       // 草地
    static let wallBeige = Color(hex: 0xE8D8C0)        // 米色墙
    static let wallBlue = Color(hex: 0xB8C8D8)         // 蓝色墙

    // 属性条色
    static let moodBar = Color(hex: 0xE8A0B8)          // 心情粉
    static let energyBar = Color(hex: 0xA0C8E8)        // 活力蓝
    static let fullnessBar = Color(hex: 0xE8C8A0)      // 饱腹橙
    static let cleanlinessBar = Color(hex: 0xA0E8C8)   // 清洁绿

    // 像素阴影
    static let pixelShadow = Color(hex: 0x3E4F38).opacity(0.2)

    // MARK: - 视图层别名
    static let creamBackground = background
    static let primaryBrown = primary
    static let accentYellow = accent
    static let lightGray = borderLight
    static let warningRed = danger
    static let moodPink = moodBar
    static let energyGreen = energyBar
    static let fullnessOrange = fullnessBar
    static let cleanlinessBlue = cleanlinessBar
}

// MARK: - Color hex 初始化器

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

// MARK: - 全局配置

enum AppConfig {
    // 属性
    static let attributeMin = 0
    static let attributeMax = 100
    static let attributeWarningThreshold = 20

    // 时间
    static let tickIntervalMinutes = 30
    static let accelerateCooldownHours = 3

    // 经济
    static let initialGoldCoins = 100

    // 场景
    static let sceneTileWidth: CGFloat = 64
    static let sceneTileHeight: CGFloat = 32

    // 存档
    static let saveFileName = "savedata.json"
    static let backupFileName = "savedata.bak"
    static let saveVersion = "2.1.0"
}
