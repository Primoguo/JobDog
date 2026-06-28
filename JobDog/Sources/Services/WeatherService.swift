import Foundation

// MARK: - 天气服务

class WeatherService {

    /// 根据当前条件生成天气
    func generateWeather(for date: Date = Date()) -> Weather {
        // 简化版：基于随机概率
        let roll = Double.random(in: 0...100)
        switch roll {
        case 0..<50: return .sunny        // 50% 晴天
        case 50..<75: return .cloudy       // 25% 多云
        case 75..<90: return .rainy        // 15% 雨天
        case 90..<97: return .thunderstorm // 7% 雷暴
        default: return .snowy             // 3% 雪天
        }
    }

    /// 自由人场景：天气是否影响室内/室外选择
    func shouldStayIndoors(weather: Weather, outdoorProbability: Double) -> Bool {
        switch weather {
        case .sunny, .cloudy:
            return false // 好天气不强制室内
        case .rainy:
            return Double.random(in: 0...1) > (1 - outdoorProbability) // 80% 室内
        case .thunderstorm:
            return Double.random(in: 0...1) > 0.05 // 95% 室内
        case .snowy:
            return Double.random(in: 0...1) > 0.2 // 80% 室内
        }
    }
}
