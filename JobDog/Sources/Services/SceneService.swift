import Foundation

// MARK: - 场景服务

class SceneService {
    /// 加权随机选择场景变体
    func selectScene(
        mode: LifeMode,
        timeSlot: TimeSlot,
        weather: Weather,
        lastVariantId: String
    ) -> SceneVariant {
        let candidates = SceneData.variants(for: mode, timeSlot: timeSlot, weather: weather)

        guard !candidates.isEmpty else {
            // 回退：返回任意可用变体
            return SceneData.allVariants.first ?? SceneData.fallbackVariant
        }

        // 避免连续重复
        let filtered = candidates.filter { $0.id != lastVariantId }
        let pool = filtered.isEmpty ? candidates : filtered

        // 加权随机（目前等权）
        let index = Int.random(in: 0..<pool.count)
        return pool[index]
    }
}
