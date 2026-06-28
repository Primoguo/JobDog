import SwiftUI

/// 状态栏 - 显示属性 + 金币 + 天气 + 时间
struct StatusBarView: View {
    let attributes: DogAttributes
    let goldCoins: Int
    let weather: Weather
    let timeSlot: TimeSlot

    var body: some View {
        VStack(spacing: 8) {
            // 顶部信息栏
            HStack {
                // 天气 + 时间
                HStack(spacing: 8) {
                    Text(weather.emoji)
                        .font(.system(size: 16))
                    Text(timeSlot.displayName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                // 金币
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundStyle(AppColors.accentYellow)
                    Text("\(goldCoins)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                }
            }

            // 属性条
            HStack(spacing: 12) {
                AttributeCapsule(title: "心情", value: attributes.mood, color: AppColors.moodPink)
                AttributeCapsule(title: "活力", value: attributes.energy, color: AppColors.energyGreen)
                AttributeCapsule(title: "饱腹", value: attributes.fullness, color: AppColors.fullnessOrange)
                AttributeCapsule(title: "清洁", value: attributes.cleanliness, color: AppColors.cleanlinessBlue)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        )
        .padding(.horizontal, 16)
    }
}
