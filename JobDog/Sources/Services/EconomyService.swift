import Foundation

// MARK: - 经济服务

class EconomyService {

    /// 计算上班族日薪
    func calculateOfficeSalary(onTime: Bool, overtime: Bool) -> Int {
        var total = SalaryArchitecture.OfficeSalary.baseDaily
        if onTime { total += SalaryArchitecture.OfficeSalary.onTimeBonus }
        if overtime { total += SalaryArchitecture.OfficeSalary.overtimeBonus }
        total += SalaryArchitecture.OfficeSalary.lunchSubsidy
        return total
    }

    /// 计算自律者日薪
    func calculateDisciplinedSalary(
        skillLevel: Int,
        morningRun: Bool,
        exercise: Bool,
        perfectAttendance: Bool
    ) -> Int {
        let multiplier = SalaryArchitecture.DisciplinedSalary.multiplier(for: skillLevel)
        var total = Int(Double(SalaryArchitecture.DisciplinedSalary.baseDaily) * multiplier)
        if morningRun { total += SalaryArchitecture.DisciplinedSalary.morningRunBonus }
        if exercise { total += SalaryArchitecture.DisciplinedSalary.exerciseBonus }
        if perfectAttendance { total += SalaryArchitecture.DisciplinedSalary.perfectAttendanceBonus }
        return total
    }

    /// 生成自由人项目邀约
    func generateProject(consecutiveDays: Int) -> Project {
        let tier: (name: String, range: ClosedRange<Int>, slots: Int)
        if consecutiveDays >= 5 {
            // 大单
            tier = ("大客户项目", SalaryArchitecture.FreelancerSalary.largeProjectRange, 4)
        } else if consecutiveDays >= 2 {
            // 中单
            tier = ("中型任务", SalaryArchitecture.FreelancerSalary.mediumProjectRange, 3)
        } else {
            // 小单
            tier = ("小任务", SalaryArchitecture.FreelancerSalary.smallProjectRange, 2)
        }
        return Project(
            id: UUID().uuidString,
            name: tier.name,
            reward: Int.random(in: tier.range),
            workSlotsNeeded: tier.slots,
            workSlotsDone: 0
        )
    }

    /// 购买物品
    func purchase(
        itemId: String,
        itemType: ItemType,
        price: Int,
        economy: inout EconomyState
    ) -> Bool {
        guard economy.goldCoins >= price else { return false }

        economy.goldCoins -= price

        // 添加到背包
        if let index = economy.backpack.firstIndex(where: { $0.itemId == itemId }) {
            economy.backpack[index].quantity += 1
        } else {
            economy.backpack.append(BackpackItem(itemId: itemId, quantity: 1, itemType: itemType))
        }
        return true
    }

    /// 使用物品
    func useItem(itemId: String, economy: inout EconomyState) -> Bool {
        guard let index = economy.backpack.firstIndex(where: { $0.itemId == itemId }) else {
            return false
        }
        if economy.backpack[index].quantity <= 1 {
            economy.backpack.remove(at: index)
        } else {
            economy.backpack[index].quantity -= 1
        }
        return true
    }

    /// 切换模式时重置金币
    func resetForModeSwitch(economy: inout EconomyState) {
        economy.goldCoins = 0
        economy.todaySalaryPaid = false
        economy.currentProject = nil
        economy.lastSalaryDate = nil
    }
}
