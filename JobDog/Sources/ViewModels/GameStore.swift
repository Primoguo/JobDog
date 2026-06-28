import Foundation
import Observation

// MARK: - 全局游戏状态中心

@Observable
class GameStore {
    // MARK: - 状态
    var saveData: SaveData?
    var currentVariant: SceneVariant?
    var isOnboarding: Bool = true
    var attributeWarnings: [String] = []

    // MARK: - 服务
    let persistence = PersistenceService()
    let timeService = TimeService()
    let sceneService = SceneService()
    let attributeService = AttributeService()
    let economyService = EconomyService()
    let weatherService = WeatherService()

    // MARK: - 初始化

    init() {
        loadGame()
    }

    // MARK: - 存档

    func loadGame() {
        if let data = persistence.load() {
            saveData = data
            isOnboarding = !data.settings.onboardingCompleted
        } else {
            saveData = nil
            isOnboarding = true
        }
    }

    func save() {
        guard var data = saveData else { return }
        data.settings.lastActiveTime = Date()
        data.metadata.lastSavedAt = Date()
        do {
            try persistence.save(data)
            saveData = data
        } catch {
            print("Save failed: \(error)")
        }
    }

    // MARK: - Onboarding 完成

    func completeOnboarding(dog: Dog) {
        var data = SaveData.new(dog: dog)
        data.settings.onboardingCompleted = true
        data.settings.onboardingCompletedAt = Date()
        saveData = data
        isOnboarding = false

        // 注册定时器回调
        timeService.onTick = { [weak self] in self?.onTick() }

        // 初始化场景
        timeService.onAppLaunch(mode: dog.lifeMode)
        updateScene()
        save()
    }

    // MARK: - 时间管理

    func onAppLaunch() {
        guard let dog = saveData?.dog else { return }

        // 注册定时器回调
        timeService.onTick = { [weak self] in self?.onTick() }

        timeService.onAppLaunch(mode: dog.lifeMode)

        // 计算离线期间的属性衰减
        if let lastActive = saveData?.settings.lastActiveTime {
            let hoursOffline = min(24, Int(Date().timeIntervalSince(lastActive) / 3600))
            if hoursOffline > 0 {
                applyAttributeDecay(hours: hoursOffline)
            }
        }

        // 发薪检查
        checkSalary()
        updateScene()
        save()
    }

    func onForeground() {
        guard let dog = saveData?.dog else { return }
        timeService.onForeground(mode: dog.lifeMode)
        updateScene()
        save()
    }

    func onTick() {
        guard let dog = saveData?.dog else { return }
        timeService.tick(mode: dog.lifeMode)
        applyAttributeDecay(hours: 1)
        updateScene()
        save()
    }

    // MARK: - 场景

    func updateScene() {
        guard let dog = saveData?.dog else { return }
        let variant = sceneService.selectScene(
            mode: dog.lifeMode,
            timeSlot: timeService.currentTimeSlot,
            weather: saveData?.sceneState.currentWeather ?? .sunny,
            lastVariantId: saveData?.sceneState.lastVariantId ?? ""
        )
        currentVariant = variant
        saveData?.sceneState.currentSceneId = variant.id
        saveData?.sceneState.currentTimeSlot = timeService.currentTimeSlot
        saveData?.sceneState.lastVariantId = variant.id
        saveData?.sceneState.lastSceneChangeTime = Date()
    }

    // MARK: - 属性

    func applyAttributeDecay(hours: Int) {
        guard var dog = saveData?.dog, let variant = currentVariant else { return }
        dog.attributes = attributeService.applySceneEffects(
            to: dog.attributes,
            sceneEffects: variant.attributeEffects,
            hoursElapsed: hours
        )
        saveData?.dog = dog
        attributeWarnings = attributeService.checkWarnings(dog.attributes)
    }

    func interact(with prop: InteractiveProp) {
        guard var dog = saveData?.dog else { return }
        // 检查金币
        if prop.cost > 0 {
            guard saveData!.economy.goldCoins >= prop.cost else { return }
            saveData?.economy.goldCoins -= prop.cost
        }
        dog.attributes = attributeService.applyInteraction(to: dog.attributes, interaction: prop)
        saveData?.dog = dog
        attributeWarnings = attributeService.checkWarnings(dog.attributes)
        save()
    }

    // MARK: - 经济

    func checkSalary() {
        guard var data = saveData else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let lastSalaryDay = data.economy.lastSalaryDate.map { Calendar.current.startOfDay(for: $0) }

        guard lastSalaryDay != today else { return } // 今日已发

        switch data.dog.lifeMode {
        case .office:
            let salary = economyService.calculateOfficeSalary(onTime: true, overtime: false)
            data.economy.goldCoins += salary
        case .free:
            // 自由人按项目完成发薪
            break
        case .disciplined:
            let salary = economyService.calculateDisciplinedSalary(
                skillLevel: data.dog.skillLevel,
                morningRun: true,
                exercise: false,
                perfectAttendance: data.dog.consecutiveAttendance > 0
            )
            data.economy.goldCoins += salary
        }

        data.economy.todaySalaryPaid = true
        data.economy.lastSalaryDate = Date()
        saveData = data
    }

    // MARK: - 重置

    func resetGame() {
        persistence.deleteSave()
        saveData = nil
        isOnboarding = true
        currentVariant = nil
    }
}
