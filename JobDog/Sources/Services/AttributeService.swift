import Foundation

// MARK: - 属性服务

class AttributeService {

    /// 每小时基础衰减（与场景无关）
    static let hourlyDecay: [String: Int] = [
        "mood": -1,
        "energy": -2,
        "fullness": -3,
        "cleanliness": -1
    ]

    /// 计算经过 N 小时后的属性变化
    func calculateDecay(hours: Int) -> [String: Int] {
        var result: [String: Int] = [:]
        for (key, value) in Self.hourlyDecay {
            result[key] = value * hours
        }
        return result
    }

    /// 应用场景属性效果
    func applySceneEffects(
        to attributes: DogAttributes,
        sceneEffects: [String: Int],
        hoursElapsed: Int
    ) -> DogAttributes {
        var attrs = attributes

        // 1. 基础衰减
        let decay = calculateDecay(hours: hoursElapsed)
        attrs.apply(decay)

        // 2. 场景效果
        attrs.apply(sceneEffects)

        return attrs
    }

    /// 执行互动效果
    func applyInteraction(
        to attributes: DogAttributes,
        interaction: InteractiveProp
    ) -> DogAttributes {
        var attrs = attributes
        attrs.apply(interaction.effect)
        return attrs
    }

    /// 检查属性阈值，返回警告列表
    func checkWarnings(_ attributes: DogAttributes) -> [String] {
        var warnings: [String] = []
        if attributes.mood < AppConfig.attributeWarningThreshold {
            warnings.append("心情很低落...")
        }
        if attributes.energy < AppConfig.attributeWarningThreshold {
            warnings.append("精力快耗尽了...")
        }
        if attributes.fullness < AppConfig.attributeWarningThreshold {
            warnings.append("肚子好饿...")
        }
        if attributes.cleanliness < AppConfig.attributeWarningThreshold {
            warnings.append("需要洗个澡...")
        }
        return warnings
    }
}
