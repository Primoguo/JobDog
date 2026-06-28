import Foundation
import Observation

// MARK: - 时间服务

@Observable
class TimeService {
    private var timer: Timer?
    private(set) var currentHour: Int
    private(set) var currentTimeSlot: TimeSlot

    /// 时段变化回调
    var onTimeSlotChanged: ((TimeSlot) -> Void)?

    /// 定时器 tick 回调（每 30 分钟触发）
    var onTick: (() -> Void)?

    init() {
        let hour = Calendar.current.component(.hour, from: Date())
        self.currentHour = hour
        self.currentTimeSlot = .morning // 默认值，启动时更新
    }

    // MARK: - 生命周期

    /// App 启动时调用
    func onAppLaunch(mode: LifeMode) {
        updateCurrentTime(mode: mode)
        startTimer()
    }

    /// 回到前台时调用
    func onForeground(mode: LifeMode) {
        let oldSlot = currentTimeSlot
        updateCurrentTime(mode: mode)
        if currentTimeSlot != oldSlot {
            onTimeSlotChanged?(currentTimeSlot)
        }
    }

    /// 停止定时器
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - 时间加速

    /// 检查加速是否可用
    func canAccelerate(cooldown: Date?) -> Bool {
        guard let cooldown else { return true }
        return Date() >= cooldown
    }

    /// 获取加速冷却结束时间
    func accelerateCooldownEnd() -> Date {
        Date().addingTimeInterval(TimeInterval(AppConfig.accelerateCooldownHours * 3600))
    }

    // MARK: - Private

    private func updateCurrentTime(mode: LifeMode) {
        currentHour = Calendar.current.component(.hour, from: Date())
        currentTimeSlot = TimeSlot.from(hour: currentHour, mode: mode)
    }

    private func startTimer() {
        timer?.invalidate()
        // 每 30 分钟触发一次
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(AppConfig.tickIntervalMinutes * 60), repeats: true) { [weak self] _ in
            guard let self else { return }
            self.onTick?()
        }
    }

    /// 手动触发 tick（由 GameStore 在定时器回调中调用）
    func tick(mode: LifeMode) {
        let oldSlot = currentTimeSlot
        updateCurrentTime(mode: mode)
        if currentTimeSlot != oldSlot {
            onTimeSlotChanged?(currentTimeSlot)
        }
    }
}
