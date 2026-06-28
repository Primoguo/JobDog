import Foundation

// MARK: - 犬种

enum Breed: String, Codable, CaseIterable, Identifiable {
    // 小型犬
    case shiba = "柴犬"
    case corgi = "柯基"
    case bichon = "比熊"
    case pomeranian = "博美"
    // 中型犬
    case borderCollie = "边牧"
    case husky = "哈士奇"
    case samoyed = "萨摩耶"
    case frenchBulldog = "法斗"
    // 大型犬
    case goldenRetriever = "金毛"
    case labrador = "拉布拉多"
    case germanShepherd = "德牧"
    case alaskan = "阿拉斯加"

    var id: String { rawValue }

    /// 中文显示名
    var displayName: String { rawValue }

    var sizeCategory: SizeCategory {
        switch self {
        case .shiba, .corgi, .bichon, .pomeranian:
            return .small
        case .borderCollie, .husky, .samoyed, .frenchBulldog:
            return .medium
        case .goldenRetriever, .labrador, .germanShepherd, .alaskan:
            return .large
        }
    }

    /// 用于 Canvas 占位渲染的 emoji
    var emoji: String {
        switch self {
        case .shiba: "🐕"
        case .corgi: "🐶"
        case .bichon: "🐩"
        case .pomeranian: "🦊"
        case .borderCollie: "🐕‍🦺"
        case .husky: "🐺"
        case .samoyed: "🤍"
        case .frenchBulldog: "🐾"
        case .goldenRetriever: "🦮"
        case .labrador: "🐕"
        case .germanShepherd: "🐕‍🦺"
        case .alaskan: "🐺"
        }
    }

    enum SizeCategory: String, Codable {
        case small, medium, large
    }
}

// MARK: - 性别

enum Gender: String, Codable, CaseIterable, Identifiable {
    case boy = "男孩"
    case girl = "女孩"

    var id: String { rawValue }
}

// MARK: - 生活模式

enum LifeMode: String, Codable, CaseIterable, Identifiable {
    case office = "上班族"
    case free = "自由人"
    case disciplined = "自律者"

    var id: String { rawValue }

    /// 中文显示名
    var displayName: String { rawValue }

    /// 用于 UI 展示的 emoji
    var emoji: String {
        switch self {
        case .office: "💼"
        case .free: "🎨"
        case .disciplined: "🏋️"
        }
    }

    var description: String {
        switch self {
        case .office: "朝九晚五，规律作息"
        case .free: "时间自由，随性安排"
        case .disciplined: "严格自律，追求成长"
        }
    }
}

// MARK: - 时段

enum TimeSlot: String, Codable, CaseIterable, Identifiable {
    case earlyMorning = "清晨"    // 5:00-7:00
    case morning = "上午"         // 7:00-11:00
    case noon = "中午"            // 11:00-14:00
    case afternoon = "下午"       // 14:00-18:00
    case evening = "傍晚"         // 18:00-21:00
    case night = "夜晚"           // 21:00-24:00
    // 自由人专用
    case lateMorning = "上午晚"   // 10:00-12:00
    case lateAfternoon = "下午晚" // 14:00-18:00
    case lateNight = "深夜"       // 0:00-2:00

    var id: String { rawValue }

    /// 中文显示名
    var displayName: String { rawValue }

    /// 该时段的起始小时（24h）
    var startHour: Int {
        switch self {
        case .lateNight: 0
        case .earlyMorning: 5
        case .morning: 7
        case .lateMorning: 10
        case .noon: 11
        case .afternoon: 14
        case .lateAfternoon: 14
        case .evening: 18
        case .night: 21
        }
    }

    /// 该时段的结束小时（24h，不含）
    var endHour: Int {
        switch self {
        case .lateNight: 2
        case .earlyMorning: 7
        case .morning: 11
        case .lateMorning: 12
        case .noon: 14
        case .afternoon: 18
        case .lateAfternoon: 18
        case .evening: 21
        case .night: 24
        }
    }

    /// 根据小时和生活模式返回当前时段
    static func from(hour: Int, mode: LifeMode) -> TimeSlot {
        switch mode {
        case .office, .disciplined:
            switch hour {
            case 0..<5: return .night
            case 5..<7: return .earlyMorning
            case 7..<11: return .morning
            case 11..<14: return .noon
            case 14..<18: return .afternoon
            case 18..<21: return .evening
            default: return .night
            }
        case .free:
            switch hour {
            case 0..<2: return .lateNight
            case 2..<10: return .night
            case 10..<12: return .lateMorning
            case 12..<14: return .noon
            case 14..<18: return .lateAfternoon
            case 18..<21: return .evening
            default: return .night
            }
        }
    }
}

// MARK: - 天气

enum Weather: String, Codable, CaseIterable, Identifiable {
    case sunny = "晴天"
    case cloudy = "多云"
    case rainy = "雨天"
    case thunderstorm = "雷暴"
    case snowy = "雪天"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .sunny: "☀️"
        case .cloudy: "☁️"
        case .rainy: "🌧️"
        case .thunderstorm: "⛈️"
        case .snowy: "🌨️"
        }
    }

    var isBadWeather: Bool {
        self == .rainy || self == .thunderstorm || self == .snowy
    }
}

// MARK: - 物品类型

enum ItemType: String, Codable {
    case food, drink, accessory
}

// MARK: - 互动类型

enum InteractionType: String, Codable {
    case feed       // 喂食
    case drink      // 喝水/饮品
    case play       // 玩耍
    case rest       // 休息
    case clean      // 清洁
    case work       // 工作（自由人/自律者）
}
