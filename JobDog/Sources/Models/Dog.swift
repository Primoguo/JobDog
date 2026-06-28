import Foundation

// MARK: - 狗狗实体

struct Dog: Codable, Identifiable {
    let id: UUID
    var name: String
    var breed: Breed
    var gender: Gender
    var lifeMode: LifeMode

    // 四维属性（0-100）
    var attributes: DogAttributes

    // 外观
    var outfit: Outfit?

    // 元数据
    let createdAt: Date
    var companionDays: Int
    var consecutiveAttendance: Int  // 连续出勤天数（自律者用）
    var skillLevel: Int             // 技能等级（自律者用，1-6）

    init(
        name: String,
        breed: Breed,
        gender: Gender,
        lifeMode: LifeMode
    ) {
        self.id = UUID()
        self.name = name
        self.breed = breed
        self.gender = gender
        self.lifeMode = lifeMode
        self.attributes = DogAttributes()
        self.outfit = nil
        self.createdAt = Date()
        self.companionDays = 0
        self.consecutiveAttendance = 0
        self.skillLevel = 1
    }
}

// MARK: - 四维属性

struct DogAttributes: Codable {
    var mood: Int        // 心情 0-100
    var energy: Int      // 活力 0-100
    var fullness: Int    // 饱腹 0-100
    var cleanliness: Int // 清洁 0-100

    /// 综合心情（用于显示）
    var overallMood: Int {
        (mood + energy + fullness + cleanliness) / 4
    }

    init(mood: Int = 70, energy: Int = 70, fullness: Int = 70, cleanliness: Int = 70) {
        self.mood = min(100, max(0, mood))
        self.energy = min(100, max(0, energy))
        self.fullness = min(100, max(0, fullness))
        self.cleanliness = min(100, max(0, cleanliness))
    }

    /// 应用属性变化（自动 clamp 到 0-100）
    mutating func apply(_ changes: [String: Int]) {
        if let v = changes["mood"] { mood = min(100, max(0, mood + v)) }
        if let v = changes["energy"] { energy = min(100, max(0, energy + v)) }
        if let v = changes["fullness"] { fullness = min(100, max(0, fullness + v)) }
        if let v = changes["cleanliness"] { cleanliness = min(100, max(0, cleanliness + v)) }
    }

    /// 是否有属性低于危险阈值
    var hasWarning: Bool {
        mood < 20 || energy < 20 || fullness < 20 || cleanliness < 20
    }

    /// 当前状态描述
    var statusDescription: String {
        switch overallMood {
        case 80...100: "状态极佳！"
        case 60..<80: "心情不错"
        case 40..<60: "还算可以"
        case 20..<40: "有点疲惫"
        default: "需要照顾..."
        }
    }
}

// MARK: - 装扮

struct Outfit: Codable {
    var top: String?       // 上衣 ID
    var bottom: String?    // 下装 ID
    var accessory: String? // 配饰 ID
}
