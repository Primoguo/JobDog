import Foundation

// MARK: - 顶层存档

struct SaveData: Codable {
    var dog: Dog
    var economy: EconomyState
    var sceneState: SceneState
    var settings: UserSettings
    var metadata: SaveMetadata

    /// 创建新存档
    static func new(dog: Dog) -> SaveData {
        SaveData(
            dog: dog,
            economy: EconomyState(),
            sceneState: SceneState(),
            settings: UserSettings(),
            metadata: SaveMetadata()
        )
    }
}

// MARK: - 用户设置

struct UserSettings: Codable {
    var onboardingCompleted: Bool
    var onboardingCompletedAt: Date?
    var lastActiveTime: Date
    var timeAccelerateCooldown: Date?
    var notificationsEnabled: Bool

    init() {
        self.onboardingCompleted = false
        self.onboardingCompletedAt = nil
        self.lastActiveTime = Date()
        self.timeAccelerateCooldown = nil
        self.notificationsEnabled = true
    }
}

// MARK: - 存档元数据

struct SaveMetadata: Codable {
    var version: String
    var lastSavedAt: Date
    var totalPlayTime: TimeInterval

    init() {
        self.version = "2.1.0"
        self.lastSavedAt = Date()
        self.totalPlayTime = 0
    }
}
