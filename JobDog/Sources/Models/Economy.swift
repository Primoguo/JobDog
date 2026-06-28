import Foundation

// MARK: - 经济状态

struct EconomyState: Codable {
    var goldCoins: Int
    var backpack: [BackpackItem]
    var todaySalaryPaid: Bool
    var currentProject: Project?
    var lastSalaryDate: Date?

    init() {
        self.goldCoins = 100 // 初始赠送
        self.backpack = []
        self.todaySalaryPaid = false
        self.currentProject = nil
        self.lastSalaryDate = nil
    }
}

// MARK: - 背包物品

struct BackpackItem: Codable, Identifiable {
    let itemId: String
    var quantity: Int
    var itemType: ItemType

    var id: String { itemId }
}

// MARK: - 自由人项目

struct Project: Codable, Identifiable {
    let id: String
    let name: String
    let reward: Int
    let workSlotsNeeded: Int
    var workSlotsDone: Int

    var isCompleted: Bool { workSlotsDone >= workSlotsNeeded }
    var progressText: String { "\(workSlotsDone)/\(workSlotsNeeded)" }
}

// MARK: - 薪资架构

enum SalaryArchitecture {
    /// 上班族 — 固定薪资制
    struct OfficeSalary {
        static let baseDaily = 100        // 日薪基础
        static let onTimeBonus = 20       // 准时奖
        static let overtimeBonus = 50     // 加班费
        static let lunchSubsidy = 10      // 午休补贴
    }

    /// 自由人 — 项目接单制
    struct FreelancerSalary {
        static let smallProjectRange = 30...50
        static let mediumProjectRange = 60...100
        static let largeProjectRange = 120...200
    }

    /// 自律者 — 技能成长制
    struct DisciplinedSalary {
        static let baseDaily = 80
        static let morningRunBonus = 15
        static let exerciseBonus = 10
        static let perfectAttendanceBonus = 50

        /// 技能等级倍率
        static func multiplier(for level: Int) -> Double {
            switch level {
            case 1: return 1.0
            case 2: return 1.2
            case 3: return 1.5
            case 4: return 1.8
            case 5: return 2.2
            default: return 2.5  // level 6+
            }
        }
    }
}
