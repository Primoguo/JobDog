import Foundation

// MARK: - 网格尺寸（顶层类型，供 SceneLayout / FurnitureItem / SceneCanvasView 共用）

struct GridSize: Codable {
    let width: Int
    let height: Int
}

// MARK: - 场景状态

struct SceneState: Codable {
    var currentSceneId: String
    var currentTimeSlot: TimeSlot
    var currentWeather: Weather
    var lastSceneChangeTime: Date
    var lastVariantId: String

    init() {
        self.currentSceneId = ""
        self.currentTimeSlot = .morning
        self.currentWeather = .sunny
        self.lastSceneChangeTime = Date()
        self.lastVariantId = ""
    }
}

// MARK: - 场景变体

struct SceneVariant: Codable, Identifiable {
    let id: String
    let timeSlot: TimeSlot
    let layout: SceneLayout
    let dogAction: String
    let interactiveProps: [InteractiveProp]
    let attributeEffects: [String: Int]
    let weatherCondition: Weather?  // nil = 任意天气可用

    /// 显示用的位置描述
    var locationText: String { layout.location }
}

// MARK: - 场景布局

struct SceneLayout: Codable {
    let location: String          // 位置名称（如 "办公室"、"咖啡厅"）
    let furniture: [FurnitureItem]
    let floorColor: String        // hex 色值
    let wallColor: String?        // hex 色值（nil = 无墙壁，户外场景）
    let gridSize: GridSize        // 网格大小
}

// MARK: - 家具/物件

struct FurnitureItem: Codable, Identifiable {
    let id: String
    let name: String
    let emoji: String             // 占位 emoji
    let position: GridPosition
    let size: GridSize
    let color: String             // hex 色值
}

// MARK: - 网格坐标

struct GridPosition: Codable {
    let x: Int
    let y: Int
}

// MARK: - 可交互道具

struct InteractiveProp: Codable, Identifiable {
    let id: String
    let type: InteractionType
    let emoji: String
    let position: GridPosition
    let effect: [String: Int]     // 属性变化
    let cost: Int                 // 金币消耗（0 = 免费）
    let label: String             // 显示文本
}
